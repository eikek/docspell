/*
 * Copyright 2020 Eike K. & Contributors
 *
 * SPDX-License-Identifier: AGPL-3.0-or-later
 */

package docspell.backend.joex

import cats.data.OptionT
import cats.effect.kernel.Sync
import cats.syntax.all._
import fs2.io.file.{Files, Path}

import docspell.addons._
import docspell.addons.out.{AddonOutput, ItemFile, NewItem}
import docspell.backend.JobFactory
import docspell.backend.ops.OAttachment
import docspell.common._
import docspell.common.bc.BackendCommandRunner
import docspell.files.FileSupport
import docspell.logging.Logger
import docspell.scheduler.JobStore
import docspell.store.Store
import docspell.store.records._

final private[joex] class AddonPostProcess[F[_]: Sync: Files](
    cmdRunner: BackendCommandRunner[F, Unit],
    store: Store[F],
    attachOps: OAttachment[F],
    jobStore: JobStore[F]
) extends FileSupport {

  def onResult(
      logger: Logger[F],
      collective: Ident,
      result: AddonExecutionResult,
      outputDir: Path
  ): F[Unit] =
    result.addonResult match {
      case AddonResult.Success(output) =>
        onSuccess(logger, collective, output, outputDir)
      case _ =>
        ().pure[F]
    }

  def onSuccess(
      logger: Logger[F],
      collective: Ident,
      output: AddonOutput,
      outputDir: Path
  ): F[Unit] =
    for {
      _ <- logger.info(s"Applying addon output commands (${output.commands.size})")
      _ <- cmdRunner.runAll(collective, output.commands)
      _ <- logger.debug(s"Applying changes from files (${output.files.size})")
      _ <- output.files.traverse_(updateOne(logger, collective, outputDir))
      _ <- logger.debug(s"Applying new items (${output.newItems.size})")
      _ <- output.newItems.traverse_(submitNewItem(logger, collective, outputDir))
    } yield ()

  def submitNewItem(
      logger: Logger[F],
      collective: Ident,
      outputDir: Path
  )(newItem: NewItem): F[Unit] =
    for {
      _ <- logger.debug(s"Submit new item with ${newItem.files.size} files")
      files <- newItem.resolveFiles[F](logger, outputDir)
      collLang <- store.transact(RCollective.findLanguage(collective))
      uploaded <- files.traverse(file =>
        file.readAll
          .through(
            store.fileRepo.save(
              collective,
              FileCategory.AttachmentSource,
              MimeTypeHint.filename(file)
            )
          )
          .compile
          .lastOrError
          .map(key => file.fileName.toString -> key)
      )
      _ <- logger.debug(s"Saved ${uploaded.size} files to be processed.")
      args = ProcessItemArgs(
        newItem.toProcessMeta(collective, collLang, "addon"),
        uploaded.map(f => ProcessItemArgs.File(f._1.some, f._2))
      )
      account = AccountId(collective, DocspellSystem.user)
      job <- JobFactory.processItem(args, account, Priority.High, None)
      _ <- jobStore.insert(job.encode)
      _ <- logger.debug(s"Submitted job for processing: ${job.id}")
    } yield ()

  def updateOne(logger: Logger[F], collective: Ident, outputDir: Path)(
      itemFile: ItemFile
  ): F[Unit] =
    for {
      textFiles <- itemFile.resolveTextFiles(logger, outputDir)
      pdfFiles <- itemFile.resolvePdfFiles(logger, outputDir)
      previewFiles <- itemFile.resolvePreviewFiles(logger, outputDir)
      attachs <- OptionT
        .whenF(textFiles.nonEmpty || pdfFiles.nonEmpty || previewFiles.nonEmpty)(
          store.transact(RAttachment.findByItem(itemFile.itemId))
        )
        .getOrElse(Vector.empty)
      _ <- textFiles.traverse_ { case (key, file) =>
        withAttach(logger, key, attachs) { ra =>
          setText(collective, ra, file.readText)
        }
      }
      _ <- pdfFiles.traverse_ { case (key, file) =>
        withAttach(logger, key, attachs) { ra =>
          replacePdf(collective, ra, file, previewFiles.forall(_._1 != key))
        }
      }
      _ <- previewFiles.traverse_ { case (key, file) =>
        withAttach(logger, key, attachs) { ra =>
          replacePreview(collective, ra.id, file)
        }
      }
      _ <- submitNewFiles(logger, collective, outputDir)(itemFile)
    } yield ()

  def submitNewFiles(
      logger: Logger[F],
      collective: Ident,
      outputDir: Path
  )(itemFile: ItemFile): F[Unit] =
    for {
      _ <- logger.info(s"Submitting new file for item")
      collLang <- store.transact(RCollective.findLanguage(collective))
      newFiles <- itemFile.resolveNewFiles(logger, outputDir)
      byMeta = newFiles.groupBy(_._1.metadata).view.mapValues(_.map(_._2))
      account = AccountId(collective, DocspellSystem.user)
      _ <- byMeta.toList.traverse_ { case (meta, files) =>
        for {
          uploaded <- files.traverse(file =>
            file.readAll
              .through(
                store.fileRepo.save(
                  collective,
                  FileCategory.AttachmentSource,
                  MimeTypeHint.filename(file)
                )
              )
              .compile
              .lastOrError
              .map(key => file.fileName.toString -> key)
          )
          args = ProcessItemArgs(
            meta.toProcessMeta(collective, itemFile.itemId, collLang, "addon"),
            uploaded.map(f => ProcessItemArgs.File(f._1.some, f._2))
          )
          job <- JobFactory.processItem(args, account, Priority.High, None)
          _ <- jobStore.insert(job.encode)
          _ <- logger.debug(s"Submitted job for processing: ${job.id}")
        } yield ()
      }
    } yield ()

  private def withAttach(logger: Logger[F], key: String, attachs: Vector[RAttachment])(
      run: RAttachment => F[Unit]
  ): F[Unit] =
    OptionT
      .fromOption(
        attachs.find(a => a.id.id == key || key.toIntOption == a.position.some)
      )
      .semiflatMap(run)
      .getOrElseF(logger.warn(s"Cannot find attachment for $key to update text!"))

  private def setText(collective: Ident, ra: RAttachment, readText: F[String]): F[Unit] =
    attachOps.setExtractedText(collective, ra.itemId, ra.id, readText)

  private def replacePdf(
      collective: Ident,
      ra: RAttachment,
      file: Path,
      generatePreview: Boolean
  ): F[Unit] =
    attachOps.addOrReplacePdf(collective, ra.id, file.readAll, generatePreview)

  private def replacePreview(
      collective: Ident,
      attachId: Ident,
      imageData: Path
  ): F[Unit] =
    attachOps.addOrReplacePreview(collective, attachId, imageData.readAll)
}

object AddonPostProcess {

  def apply[F[_]: Sync: Files](
      cmdRunner: BackendCommandRunner[F, Unit],
      store: Store[F],
      attachment: OAttachment[F],
      jobStore: JobStore[F]
  ): AddonPostProcess[F] =
    new AddonPostProcess[F](cmdRunner, store, attachment, jobStore)
}
