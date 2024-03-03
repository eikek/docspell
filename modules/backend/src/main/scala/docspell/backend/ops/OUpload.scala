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
import docspell.scheduler.usertask.UserTaskScope
import docspell.scheduler.{Job, JobStore}
import docspell.store.Store
import docspell.store.records._

import io.circe.Json

trait OUpload[F[_]] {

  def submit(
      data: OUpload.UploadData[F],
      collectiveId: CollectiveId,
      userId: Option[Ident],
      itemId: Option[Ident]
  ): F[OUpload.UploadResult]

  /** Submit files via a given source identifier. The source is looked up to identify the
    * collective the files belong to. Metadata defined in the source is used as a fallback
    * to those specified here (in UploadData).
    */
  def submit(
      data: OUpload.UploadData[F],
      sourceId: Ident,
      itemId: Option[Ident]
  ): F[OUpload.UploadResult]

  final def submitEither(
      data: OUpload.UploadData[F],
      accOrSrc: Either[Ident, CollectiveId],
      userId: Option[Ident],
      itemId: Option[Ident]
  ): F[OUpload.UploadResult] =
    accOrSrc match {
      case Right(acc) =>
        submit(data, acc, userId, itemId)
      case Left(srcId) =>
        submit(data, srcId, itemId)
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
      attachmentsOnly: Option[Boolean],
      flattenArchives: Option[Boolean],
      customData: Option[Json]
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

    /** A source (`RSource`) could not be found for a given source-id. */
    case object NoSource extends UploadResult

    def noSource: UploadResult = NoSource

    /** When adding files to an item, no item was found using the given item-id. */
    case object NoItem extends UploadResult

    def noItem: UploadResult = NoItem

    /** A collective with the given id was not found */
    case object NoCollective extends UploadResult

    def noCollective: UploadResult = NoCollective

    /** A file could not be stored due to error in the file backend. */
    case class StoreFailure(cause: Throwable) extends UploadResult

    def storeFailure(cause: Throwable): UploadResult = StoreFailure(cause)
  }

  private def right[F[_]: Functor, A](a: F[A]): EitherT[F, UploadResult, A] =
    EitherT.right(a)

  def apply[F[_]: Sync](
      store: Store[F],
      jobStore: JobStore[F]
  ): Resource[F, OUpload[F]] =
    Resource.pure[F, OUpload[F]](new OUpload[F] {
      private[this] val logger = docspell.logging.getLogger[F]

      def submit(
          data: OUpload.UploadData[F],
          collectiveId: CollectiveId,
          userId: Option[Ident],
          itemId: Option[Ident]
      ): F[OUpload.UploadResult] =
        (for {
          _ <- checkExistingItem(itemId, collectiveId)
          coll <- OptionT(store.transact(RCollective.findById(collectiveId)))
            .toRight(UploadResult.noCollective)
          files <- data.files.traverse(saveFile(coll.id))
          _ <- checkFileList(files)
          lang <- data.meta.language match {
            case Some(lang) => right(lang.pure[F])
            case None =>
              right(
                store
                  .transact(RCollective.findLanguage(collectiveId))
                  .map(_.getOrElse(Language.German))
              )
          }
          meta = ProcessItemArgs.ProcessMeta(
            collectiveId,
            itemId,
            lang,
            data.meta.direction,
            data.meta.sourceAbbrev,
            data.meta.folderId,
            data.meta.validFileTypes,
            data.meta.skipDuplicates,
            data.meta.fileFilter.some,
            data.meta.tags.some,
            reprocess = false,
            data.meta.attachmentsOnly,
            data.meta.customData
          )
          args = ProcessItemArgs(meta, files.toList)
          jobs <- right(
            makeJobs(
              data,
              args,
              UserTaskScope(collectiveId, userId)
            )
          )
          _ <- right(logger.debug(s"Storing jobs: $jobs"))
          res <- right(submitJobs(jobs.map(_.encode)))
          _ <- right(
            store.transact(
              RSource.incrementCounter(data.meta.sourceAbbrev, collectiveId)
            )
          )
        } yield res).fold(identity, identity)

      def submit(
          data: OUpload.UploadData[F],
          sourceId: Ident,
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
          result <- OptionT.liftF(submit(updata, src.source.cid, None, itemId))
        } yield result).getOrElse(UploadResult.noSource)

      private def submitJobs(jobs: List[Job[String]]): F[OUpload.UploadResult] =
        for {
          _ <- logger.debug(s"Storing jobs: $jobs")
          _ <- jobStore.insertAll(jobs)
        } yield UploadResult.Success

      /** Saves the file into the database. */
      private def saveFile(
          collectiveId: CollectiveId
      )(file: File[F]): EitherT[F, UploadResult, ProcessItemArgs.File] =
        for {
          _ <- right(logger.info(s"Receiving file $file"))
          id <- EitherT(
            file.data
              .through(
                store.fileRepo.save(
                  collectiveId,
                  FileCategory.AttachmentSource,
                  MimeTypeHint(file.name, None)
                )
              )
              .compile
              .lastOrError
              .attempt
          ).leftSemiflatTap(ex =>
            logger.warn(ex)(
              s"Could not store file ${file.name}/${file.advertisedMime} for processing!"
            )
          ).leftMap(UploadResult.storeFailure)
        } yield ProcessItemArgs.File(file.name, id)

      private def checkExistingItem(
          itemId: Option[Ident],
          coll: CollectiveId
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
          data: UploadData[F],
          args: ProcessItemArgs,
          submitter: UserTaskScope
      ): F[List[Job[ProcessItemArgs]]] =
        if (data.meta.flattenArchives.getOrElse(false))
          JobFactory
            .multiUpload(args, submitter, data.priority, data.tracker)
            .map(List(_))
        else if (data.multiple)
          JobFactory.processItems(
            args.files.map(f => args.copy(files = List(f))),
            submitter,
            data.priority,
            data.tracker
          )
        else
          JobFactory
            .processItem[F](args, submitter, data.priority, data.tracker)
            .map(List(_))
    })
}
