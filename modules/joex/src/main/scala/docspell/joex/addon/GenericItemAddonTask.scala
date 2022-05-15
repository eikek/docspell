/*
 * Copyright 2020 Eike K. & Contributors
 *
 * SPDX-License-Identifier: AGPL-3.0-or-later
 */

package docspell.joex.addon

import cats.data.{Kleisli, OptionT}
import cats.effect._
import cats.syntax.all._
import fs2.io.file.Files

import docspell.addons.{AddonTriggerType, InputEnv, Middleware}
import docspell.backend.joex.AddonOps.ExecResult
import docspell.backend.joex.{AddonOps, LoggerExtension}
import docspell.common._
import docspell.files.FileSupport
import docspell.joex.process.ItemData
import docspell.logging.Logger
import docspell.scheduler.Task
import docspell.store.Store
import docspell.store.queries.QAttachment

object GenericItemAddonTask extends LoggerExtension with FileSupport {

  private val itemSubdir = "item"
  private val itemDataJson = s"$itemSubdir/item-data.json"
  private val argsMetaJson = s"$itemSubdir/given-data.json"
  private val pdfDir = s"$itemSubdir/pdfs"
  private val originalDir = s"$itemSubdir/originals"
  private val originalMetaJson = s"$itemSubdir/source-files.json"
  private val pdfMetaJson = s"$itemSubdir/pdf-files.json"

  // This environment can be used by the addon to access data of the current task
  private val itemEnv = Map(
    "ITEM_DIR" -> itemSubdir,
    "ITEM_DATA_JSON" -> itemDataJson,
    "ITEM_ARGS_JSON" -> argsMetaJson,
    "ITEM_PDF_DIR" -> pdfDir,
    "ITEM_ORIGINAL_DIR" -> originalDir,
    "ITEM_ORIGINAL_JSON" -> originalMetaJson,
    "ITEM_PDF_JSON" -> pdfMetaJson
  )

  def apply[F[_]: Async](
      ops: AddonOps[F],
      store: Store[F],
      trigger: AddonTriggerType,
      addonTaskIds: Set[Ident]
  )(
      collective: Ident,
      data: ItemData,
      maybeMeta: Option[ProcessItemArgs.ProcessMeta]
  ): Task[F, Unit, ItemData] =
    addonResult(ops, store, trigger, addonTaskIds)(collective, data, maybeMeta).as(
      data
    )

  def addonResult[F[_]: Async](
      ops: AddonOps[F],
      store: Store[F],
      trigger: AddonTriggerType,
      addonTaskIds: Set[Ident]
  )(
      collective: Ident,
      data: ItemData,
      maybeMeta: Option[ProcessItemArgs.ProcessMeta]
  ): Task[F, Unit, ExecResult] =
    Task { ctx =>
      ops.execAll(collective, Set(trigger), addonTaskIds, ctx.logger.some)(
        Middleware.prepare(Kleisli(prepareItemData(ctx.logger, store, data, maybeMeta)))
      )
    }

  def prepareItemData[F[_]: Async](
      logger: Logger[F],
      store: Store[F],
      data: ItemData,
      maybeMeta: Option[ProcessItemArgs.ProcessMeta]
  )(
      input: InputEnv
  ): F[InputEnv] =
    for {
      _ <- logger.debug(s"Preparing item data '${data.item.name}' for addon")
      wd = input.baseDir
      itemMetaFile = wd / itemDataJson
      argsMetaFile = wd / argsMetaJson
      pdfs = wd / pdfDir
      originals = wd / originalDir
      srcJson = wd / originalMetaJson
      pdfJson = wd / pdfMetaJson

      _ <- List(wd / itemSubdir, pdfs, originals).traverse(Files[F].createDirectories)

      _ <- logger.debug("Writing collected item data…")
      _ <- itemMetaFile.writeJson(data)

      _ <- OptionT
        .fromOption[F](maybeMeta)
        .semiflatMap { meta =>
          logger.debug("Writing context meta data…") *>
            argsMetaFile.writeJson(meta)
        }
        .value

      _ <- logger.debug("Storing all attachments…")
      _ <- data.attachments
        .flatMap(a =>
          Vector(
            pdfs / a.id.id -> a.fileId,
            originals / a.id.id -> data.originFile(a.id)
          )
        )
        .traverse_ { case (out, key) =>
          logger.debug(s"Storing attachment $out") *>
            store.fileRepo
              .getBytes(key)
              .through(Files[F].writeAll(out))
              .compile
              .drain
        }

      _ <- logger.debug("Storing file metadata")
      srcMeta <- store.transact(QAttachment.attachmentSourceFile(data.item.id))
      pdfMeta <- store.transact(QAttachment.attachmentFile(data.item.id))
      _ <- srcJson.writeJson(srcMeta)
      _ <- pdfJson.writeJson(pdfMeta)
    } yield input.addEnv(itemEnv)
}
