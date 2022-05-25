/*
 * Copyright 2020 Eike K. & Contributors
 *
 * SPDX-License-Identifier: AGPL-3.0-or-later
 */

package docspell.backend.ops

import cats.data.{NonEmptyList => Nel, OptionT}
import cats.effect._
import cats.syntax.all._
import fs2.Stream

import docspell.backend.JobFactory
import docspell.common.MakePreviewArgs.StoreMode
import docspell.common._
import docspell.files.TikaMimetype
import docspell.ftsclient.{FtsClient, TextData}
import docspell.scheduler.JobStore
import docspell.store.Store
import docspell.store.queries.QAttachment
import docspell.store.records._

trait OAttachment[F[_]] {

  def setExtractedText(
      collective: Ident,
      itemId: Ident,
      attachId: Ident,
      newText: F[String]
  ): F[Unit]

  def addOrReplacePdf(
      collective: Ident,
      attachId: Ident,
      pdfData: Stream[F, Byte],
      regeneratePreview: Boolean
  ): F[Unit]

  def addOrReplacePreview(
      collective: Ident,
      attachId: Ident,
      imageData: Stream[F, Byte]
  ): F[Unit]
}

object OAttachment {

  def apply[F[_]: Sync](
      store: Store[F],
      fts: FtsClient[F],
      jobStore: JobStore[F]
  ): OAttachment[F] =
    new OAttachment[F] {
      private[this] val logger = docspell.logging.getLogger[F]

      def setExtractedText(
          collective: Ident,
          itemId: Ident,
          attachId: Ident,
          newText: F[String]
      ): F[Unit] =
        for {
          _ <- logger.info(s"Find attachment ${attachId.id} to update extracted text.")
          cca <- store
            .transact(
              QAttachment
                .allAttachmentMetaAndName(
                  collective.some,
                  Nel.of(itemId).some,
                  ItemState.validStates.append(ItemState.Processing),
                  100
                )
            )
            .filter(_.id == attachId)
            .compile
            .last
          content = cca.find(_.id == attachId)
          _ <- logger.debug(s"Found existing metadata: ${content.isDefined}")
          _ <- OptionT
            .fromOption(content)
            .semiflatMap { cnt =>
              for {
                _ <- logger.debug(s"Setting new extracted text on ${cnt.id.id}")
                text <- newText
                td = TextData.attachment(
                  cnt.item,
                  cnt.id,
                  cnt.collective,
                  cnt.folder,
                  cnt.lang,
                  cnt.name,
                  text.some
                )
                _ <- store.transact(RAttachmentMeta.updateContent(attachId, text))
                _ <- fts.updateIndex(logger, td)
              } yield ()
            }
            .getOrElseF(
              logger.warn(
                s"Item or attachment meta not found to update text: ${itemId.id}"
              )
            )
        } yield ()

      def addOrReplacePdf(
          collective: Ident,
          attachId: Ident,
          pdfData: Stream[F, Byte],
          regeneratePreview: Boolean
      ): F[Unit] = {
        def generatePreview(ra: RAttachment): F[Unit] =
          JobFactory
            .makePreview(MakePreviewArgs(ra.id, StoreMode.Replace), None)
            .map(_.encode)
            .flatMap(jobStore.insert) *>
            logger.info(s"Job submitted to re-generate preview from new pdf")

        def generatePageCount(ra: RAttachment): F[Unit] =
          JobFactory
            .makePageCount(
              MakePageCountArgs(ra.id),
              AccountId(collective, DocspellSystem.user).some
            )
            .map(_.encode)
            .flatMap(jobStore.insert) *>
            logger.info(s"Job submitted to find page count from new pdf")

        def setFile(ra: RAttachment, rs: RAttachmentSource) =
          for {
            _ <- requireMimeType(pdfData, MimeType.pdf)

            newFile <- pdfData
              .through(
                store.fileRepo.save(
                  collective,
                  FileCategory.AttachmentConvert,
                  MimeTypeHint.advertised(MimeType.pdf)
                )
              )
              .compile
              .lastOrError

            _ <- store.transact(RAttachment.updateFileId(attachId, newFile))
            _ <- logger.info(s"Deleting old file for attachment")
            _ <-
              if (rs.fileId == ra.fileId) ().pure[F]
              else store.fileRepo.delete(ra.fileId)
            _ <-
              if (regeneratePreview) generatePreview(ra)
              else ().pure[F]
            _ <- generatePageCount(ra)
          } yield ()

        (for {
          ra <- OptionT(
            store.transact(RAttachment.findByIdAndCollective(attachId, collective))
          )
          rs <- OptionT(
            store.transact(RAttachmentSource.findByIdAndCollective(attachId, collective))
          )
          _ <- OptionT.liftF(setFile(ra, rs))
        } yield ()).getOrElseF(
          logger.warn(
            s"Cannot replace pdf file. Attachment not found for id: ${attachId.id}"
          )
        )
      }

      def addOrReplacePreview(
          collective: Ident,
          attachId: Ident,
          imageData: Stream[F, Byte]
      ): F[Unit] = {
        def setFile(ra: RAttachment): F[Unit] =
          for {
            _ <- requireMimeType(imageData, MimeType.image("*"))
            newFile <- imageData
              .through(
                store.fileRepo
                  .save(collective, FileCategory.PreviewImage, MimeTypeHint.none)
              )
              .compile
              .lastOrError

            now <- Timestamp.current[F]
            record = RAttachmentPreview(ra.id, newFile, None, now)
            oldFile <- store.transact(RAttachmentPreview.upsert(record))
            _ <- OptionT
              .fromOption(oldFile)
              .semiflatMap(store.fileRepo.delete)
              .getOrElse(())
          } yield ()

        (for {
          ra <- OptionT(
            store.transact(RAttachment.findByIdAndCollective(attachId, collective))
          )
          _ <- OptionT.liftF(setFile(ra))
        } yield ()).getOrElseF(
          logger.warn(
            s"Cannot add/replace preview file. Attachment not found for id: ${attachId.id}"
          )
        )
      }
    }

  private def requireMimeType[F[_]: Sync](
      data: Stream[F, Byte],
      expectedMime: MimeType
  ): F[Unit] =
    TikaMimetype
      .detect(data, MimeTypeHint.advertised(expectedMime))
      .flatMap { mime =>
        if (expectedMime.matches(mime)) ().pure[F]
        else
          Sync[F].raiseError(
            new IllegalArgumentException(
              s"Expected pdf file, but got: ${mime.asString}"
            )
          )
      }
}
