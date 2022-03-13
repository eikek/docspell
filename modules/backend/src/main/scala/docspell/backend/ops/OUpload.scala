/*
 * Copyright 2020 Eike K. & Contributors
 *
 * SPDX-License-Identifier: AGPL-3.0-or-later
 */

package docspell.backend.ops

import cats.Functor
import cats.data.{EitherT, OptionT}
import cats.effect._
import cats.implicits._
import fs2.Stream

import docspell.backend.JobFactory
import docspell.common._
import docspell.scheduler.{Job, JobStore}
import docspell.store.Store
import docspell.store.records._

trait OUpload[F[_]] {

  def submit(
      data: OUpload.UploadData[F],
      account: AccountId,
      notifyJoex: Boolean,
      itemId: Option[Ident]
  ): F[OUpload.UploadResult]

  /** Submit files via a given source identifier. The source is looked up to identify the
    * collective the files belong to. Metadata defined in the source is used as a fallback
    * to those specified here (in UploadData).
    */
  def submit(
      data: OUpload.UploadData[F],
      sourceId: Ident,
      notifyJoex: Boolean,
      itemId: Option[Ident]
  ): F[OUpload.UploadResult]

  final def submitEither(
      data: OUpload.UploadData[F],
      accOrSrc: Either[Ident, AccountId],
      notifyJoex: Boolean,
      itemId: Option[Ident]
  ): F[OUpload.UploadResult] =
    accOrSrc match {
      case Right(acc) =>
        submit(data, acc, notifyJoex, itemId)
      case Left(srcId) =>
        submit(data, srcId, notifyJoex, itemId)
    }
}

object OUpload {
  case class File[F[_]](
      name: Option[String],
      advertisedMime: Option[MimeType],
      data: Stream[F, Byte]
  )

  case class UploadMeta(
      direction: Option[Direction],
      sourceAbbrev: String,
      folderId: Option[Ident],
      validFileTypes: Seq[MimeType],
      skipDuplicates: Boolean,
      fileFilter: Glob,
      tags: List[String],
      language: Option[Language],
      attachmentsOnly: Option[Boolean]
  )

  case class UploadData[F[_]](
      multiple: Boolean,
      meta: UploadMeta,
      files: Vector[File[F]],
      priority: Priority,
      tracker: Option[Ident]
  )

  sealed trait UploadResult
  object UploadResult {

    /** File(s) have been successfully submitted. */
    case object Success extends UploadResult

    def success: UploadResult = Success

    /** There were no files to submit. */
    case object NoFiles extends UploadResult

    def noFiles: UploadResult = NoFiles

    /** A source (`RSource') could not be found for a given source-id. */
    case object NoSource extends UploadResult

    def noSource: UploadResult = NoSource

    /** When adding files to an item, no item was found using the given item-id. */
    case object NoItem extends UploadResult

    def noItem: UploadResult = NoItem
  }

  private def right[F[_]: Functor, A](a: F[A]): EitherT[F, UploadResult, A] =
    EitherT.right(a)

  def apply[F[_]: Sync](
      store: Store[F],
      jobStore: JobStore[F],
      joex: OJoex[F]
  ): Resource[F, OUpload[F]] =
    Resource.pure[F, OUpload[F]](new OUpload[F] {
      private[this] val logger = docspell.logging.getLogger[F]
      def submit(
          data: OUpload.UploadData[F],
          account: AccountId,
          notifyJoex: Boolean,
          itemId: Option[Ident]
      ): F[OUpload.UploadResult] =
        (for {
          _ <- checkExistingItem(itemId, account.collective)
          files <- right(data.files.traverse(saveFile(account)).map(_.flatten))
          _ <- checkFileList(files)
          lang <- data.meta.language match {
            case Some(lang) => right(lang.pure[F])
            case None =>
              right(
                store
                  .transact(RCollective.findLanguage(account.collective))
                  .map(_.getOrElse(Language.German))
              )
          }
          meta = ProcessItemArgs.ProcessMeta(
            account.collective,
            itemId,
            lang,
            data.meta.direction,
            data.meta.sourceAbbrev,
            data.meta.folderId,
            data.meta.validFileTypes,
            data.meta.skipDuplicates,
            data.meta.fileFilter.some,
            data.meta.tags.some,
            false,
            data.meta.attachmentsOnly
          )
          args =
            if (data.multiple) files.map(f => ProcessItemArgs(meta, List(f)))
            else Vector(ProcessItemArgs(meta, files.toList))
          jobs <- right(makeJobs(args, account, data.priority, data.tracker))
          _ <- right(logger.debug(s"Storing jobs: $jobs"))
          res <- right(submitJobs(notifyJoex)(jobs))
          _ <- right(
            store.transact(
              RSource.incrementCounter(data.meta.sourceAbbrev, account.collective)
            )
          )
        } yield res).fold(identity, identity)

      def submit(
          data: OUpload.UploadData[F],
          sourceId: Ident,
          notifyJoex: Boolean,
          itemId: Option[Ident]
      ): F[OUpload.UploadResult] =
        (for {
          src <- OptionT(store.transact(SourceData.findEnabled(sourceId)))
          updata = data.copy(
            meta = data.meta.copy(
              sourceAbbrev = src.source.abbrev,
              folderId = data.meta.folderId.orElse(src.source.folderId),
              fileFilter =
                if (data.meta.fileFilter == Glob.all) src.source.fileFilterOrAll
                else data.meta.fileFilter,
              tags = (data.meta.tags ++ src.tags.map(_.tagId.id)).distinct,
              language = data.meta.language.orElse(src.source.language),
              attachmentsOnly =
                data.meta.attachmentsOnly.orElse(src.source.attachmentsOnly.some)
            ),
            priority = src.source.priority
          )
          accId = AccountId(src.source.cid, src.source.sid)
          result <- OptionT.liftF(submit(updata, accId, notifyJoex, itemId))
        } yield result).getOrElse(UploadResult.noSource)

      private def submitJobs(
          notifyJoex: Boolean
      )(jobs: Vector[Job[String]]): F[OUpload.UploadResult] =
        for {
          _ <- logger.debug(s"Storing jobs: $jobs")
          _ <- jobStore.insertAll(jobs)
          _ <- if (notifyJoex) joex.notifyAllNodes else ().pure[F]
        } yield UploadResult.Success

      /** Saves the file into the database. */
      private def saveFile(
          accountId: AccountId
      )(file: File[F]): F[Option[ProcessItemArgs.File]] =
        logger.info(s"Receiving file $file") *>
          file.data
            .through(
              store.fileRepo.save(
                accountId.collective,
                FileCategory.AttachmentSource,
                MimeTypeHint(file.name, None)
              )
            )
            .compile
            .lastOrError
            .attempt
            .map(
              _.fold(
                ex => {
                  logger.warn(ex)(s"Could not store file for processing!")
                  None
                },
                id => Some(ProcessItemArgs.File(file.name, id))
              )
            )

      private def checkExistingItem(
          itemId: Option[Ident],
          coll: Ident
      ): EitherT[F, UploadResult, Unit] =
        itemId match {
          case None =>
            right(().pure[F])
          case Some(id) =>
            OptionT(store.transact(RItem.findByIdAndCollective(id, coll)))
              .toRight(UploadResult.noItem)
              .map(_ => ())
        }

      private def checkFileList(
          files: Seq[ProcessItemArgs.File]
      ): EitherT[F, UploadResult, Unit] =
        if (files.isEmpty) EitherT.left(UploadResult.noFiles.pure[F])
        else right(().pure[F])

      private def makeJobs(
          args: Vector[ProcessItemArgs],
          account: AccountId,
          prio: Priority,
          tracker: Option[Ident]
      ): F[Vector[Job[String]]] =
        JobFactory
          .processItems[F](args, account, prio, tracker)
          .map(_.map(_.encode))
    })
}
