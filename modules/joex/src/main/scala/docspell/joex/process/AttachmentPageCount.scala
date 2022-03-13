/*
 * Copyright 2020 Eike K. & Contributors
 *
 * SPDX-License-Identifier: AGPL-3.0-or-later
 */

package docspell.joex.process

import cats.Functor
import cats.data.OptionT
import cats.effect._
import cats.implicits._
import fs2.Stream

import docspell.common._
import docspell.extract.pdfbox.PdfMetaData
import docspell.extract.pdfbox.PdfboxExtract
import docspell.scheduler._
import docspell.store.Store
import docspell.store.records.RAttachment
import docspell.store.records._

/** Goes through all attachments that must be already converted into a pdf. If it is a
  * pdf, the number of pages are retrieved and stored in the attachment metadata.
  */
object AttachmentPageCount {

  def apply[F[_]: Sync](store: Store[F])(
      item: ItemData
  ): Task[F, ProcessItemArgs, ItemData] =
    Task { ctx =>
      for {
        _ <- ctx.logger.info(
          s"Retrieving page count for ${item.attachments.size} files…"
        )
        _ <- item.attachments
          .traverse(createPageCount(ctx, store))
          .attempt
          .flatMap {
            case Right(_) => ().pure[F]
            case Left(ex) =>
              ctx.logger.error(ex)(
                s"Retrieving page counts failed, continuing without it."
              )
          }
      } yield item
    }

  def createPageCount[F[_]: Sync](
      ctx: Context[F, _],
      store: Store[F]
  )(ra: RAttachment): F[Option[PdfMetaData]] =
    findMime[F](store)(ra).flatMap {
      case MimeType.PdfMatch(_) =>
        PdfboxExtract.getMetaData(loadFile(store)(ra)).flatMap {
          case Right(md) =>
            ctx.logger.debug(s"Found number of pages: ${md.pageCount}") *>
              updatePageCount(ctx, store, md, ra).map(_.some)
          case Left(ex) =>
            ctx.logger.warn(s"Error obtaining pages count: ${ex.getMessage}") *>
              (None: Option[PdfMetaData]).pure[F]
        }

      case mt =>
        ctx.logger.warn(s"Not a pdf file, but ${mt.asString}, cannot get page count.") *>
          (None: Option[PdfMetaData]).pure[F]
    }

  private def updatePageCount[F[_]: Sync](
      ctx: Context[F, _],
      store: Store[F],
      md: PdfMetaData,
      ra: RAttachment
  ): F[PdfMetaData] =
    for {
      _ <- ctx.logger.debug(
        s"Update attachment ${ra.id.id} with page count ${md.pageCount.some}"
      )
      n <- store.transact(RAttachmentMeta.updatePageCount(ra.id, md.pageCount.some))
      m <-
        if (n == 0)
          ctx.logger.warn(
            s"No attachmentmeta record exists for ${ra.id.id}. Creating new."
          ) *> store.transact(
            RAttachmentMeta.insert(
              RAttachmentMeta(
                ra.id,
                None,
                Nil,
                MetaProposalList.empty,
                md.pageCount.some,
                None
              )
            )
          )
        else 0.pure[F]
      _ <- ctx.logger.debug(s"Stored page count (${n + m}).")
    } yield md

  def findMime[F[_]: Functor](store: Store[F])(ra: RAttachment): F[MimeType] =
    OptionT(store.transact(RFileMeta.findById(ra.fileId)))
      .map(_.mimetype)
      .getOrElse(MimeType.octetStream)

  def loadFile[F[_]](store: Store[F])(ra: RAttachment): Stream[F, Byte] =
    store.fileRepo.getBytes(ra.fileId)
}
