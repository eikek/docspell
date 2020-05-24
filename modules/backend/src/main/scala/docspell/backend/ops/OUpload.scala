package docspell.backend.ops

import bitpeace.MimetypeHint
import cats.Functor
import cats.data.{EitherT, OptionT}
import cats.effect._
import cats.implicits._
import docspell.backend.Config
import fs2.Stream
import docspell.common._
import docspell.common.syntax.all._
import docspell.store.Store
import docspell.store.queue.JobQueue
import docspell.store.records._
import org.log4s._

trait OUpload[F[_]] {

  def submit(
      data: OUpload.UploadData[F],
      account: AccountId,
      notifyJoex: Boolean,
      itemId: Option[Ident]
  ): F[OUpload.UploadResult]

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
  private[this] val logger = getLogger

  case class File[F[_]](
      name: Option[String],
      advertisedMime: Option[MimeType],
      data: Stream[F, Byte]
  )

  case class UploadMeta(
      direction: Option[Direction],
      sourceAbbrev: String,
      validFileTypes: Seq[MimeType]
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

    /** When adding files to an item, no item was found using the given
      * item-id. */
    case object NoItem extends UploadResult

    def noItem: UploadResult = NoItem
  }

  private def right[F[_]: Functor, A](a: F[A]): EitherT[F, UploadResult, A] =
    EitherT.right(a)

  def apply[F[_]: Sync](
      store: Store[F],
      queue: JobQueue[F],
      cfg: Config.Files,
      joex: OJoex[F]
  ): Resource[F, OUpload[F]] =
    Resource.pure[F, OUpload[F]](new OUpload[F] {

      def submit(
          data: OUpload.UploadData[F],
          account: AccountId,
          notifyJoex: Boolean,
          itemId: Option[Ident]
      ): F[OUpload.UploadResult] =
        (for {
          _     <- checkExistingItem(itemId, account.collective)
          files <- right(data.files.traverse(saveFile).map(_.flatten))
          _     <- checkFileList(files)
          lang  <- right(store.transact(RCollective.findLanguage(account.collective)))
          meta = ProcessItemArgs.ProcessMeta(
            account.collective,
            itemId,
            lang.getOrElse(Language.German),
            data.meta.direction,
            data.meta.sourceAbbrev,
            data.meta.validFileTypes
          )
          args =
            if (data.multiple) files.map(f => ProcessItemArgs(meta, List(f)))
            else Vector(ProcessItemArgs(meta, files.toList))
          jobs <- right(makeJobs(args, account, data.priority, data.tracker))
          _    <- right(logger.fdebug(s"Storing jobs: $jobs"))
          res  <- right(submitJobs(notifyJoex)(jobs))
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
          src <- OptionT(store.transact(RSource.find(sourceId)))
          updata = data.copy(
            meta = data.meta.copy(sourceAbbrev = src.abbrev),
            priority = src.priority
          )
          accId = AccountId(src.cid, src.sid)
          result <- OptionT.liftF(submit(updata, accId, notifyJoex, itemId))
        } yield result).getOrElse(UploadResult.noSource)

      private def submitJobs(
          notifyJoex: Boolean
      )(jobs: Vector[RJob]): F[OUpload.UploadResult] =
        for {
          _ <- logger.fdebug(s"Storing jobs: $jobs")
          _ <- queue.insertAll(jobs)
          _ <- if (notifyJoex) joex.notifyAllNodes else ().pure[F]
        } yield UploadResult.Success

      /** Saves the file into the database. */
      private def saveFile(file: File[F]): F[Option[ProcessItemArgs.File]] =
        logger.finfo(s"Receiving file $file") *>
          store.bitpeace
            .saveNew(file.data, cfg.chunkSize, MimetypeHint(file.name, None), None)
            .compile
            .lastOrError
            .map(fm => Ident.unsafe(fm.id))
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
      ): F[Vector[RJob]] = {
        def create(id: Ident, now: Timestamp, arg: ProcessItemArgs): RJob =
          RJob.newJob(
            id,
            ProcessItemArgs.taskName,
            account.collective,
            arg,
            arg.makeSubject,
            now,
            account.user,
            prio,
            tracker
          )

        for {
          id  <- Ident.randomId[F]
          now <- Timestamp.current[F]
          jobs = args.map(a => create(id, now, a))
        } yield jobs

      }
    })
}
