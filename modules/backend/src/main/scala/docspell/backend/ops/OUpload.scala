package docspell.backend.ops

import bitpeace.MimetypeHint
import cats.implicits._
import cats.effect.{ConcurrentEffect, Effect, Resource}
import docspell.backend.Config
import fs2.Stream
import docspell.common._
import docspell.common.syntax.all._
import docspell.store.Store
import docspell.store.queue.JobQueue
import docspell.store.records.{RCollective, RJob, RSource}
import org.log4s._

import scala.concurrent.ExecutionContext

trait OUpload[F[_]] {

  def submit(data: OUpload.UploadData[F], account: AccountId): F[OUpload.UploadResult]

  def submit(data: OUpload.UploadData[F], sourceId: Ident): F[OUpload.UploadResult]
}

object OUpload {
  private [this] val logger = getLogger

  case class File[F[_]](name: Option[String], advertisedMime: Option[MimeType], data: Stream[F, Byte])

  case class UploadMeta( direction: Option[Direction]
                       , sourceAbbrev: String
                       , validFileTypes: Seq[MimeType])

  case class UploadData[F[_]]( multiple: Boolean
                              , meta: UploadMeta
                              , files: Vector[File[F]], priority: Priority, tracker: Option[Ident])

  sealed trait UploadResult
  object UploadResult {
    case object Success extends UploadResult
    case object NoFiles extends UploadResult
    case object NoSource extends UploadResult
  }

  def apply[F[_]: ConcurrentEffect](store: Store[F], queue: JobQueue[F], cfg: Config, httpClientEC: ExecutionContext): Resource[F, OUpload[F]] =
    Resource.pure(new OUpload[F] {

      def submit(data: OUpload.UploadData[F], account: AccountId): F[OUpload.UploadResult] = {
        for {
          files <- data.files.traverse(saveFile).map(_.flatten)
          pred  <- checkFileList(files)
          lang  <- store.transact(RCollective.findLanguage(account.collective))
          meta  = ProcessItemArgs.ProcessMeta(account.collective, lang.getOrElse(Language.German), data.meta.direction, data.meta.sourceAbbrev, data.meta.validFileTypes)
          args  =  if (data.multiple) files.map(f => ProcessItemArgs(meta, List(f))) else Vector(ProcessItemArgs(meta, files.toList))
          job   <- pred.traverse(_ => makeJobs(args, account, data.priority, data.tracker))
          _     <- logger.fdebug(s"Storing jobs: $job")
          res   <- job.traverse(submitJobs)
          _     <- store.transact(RSource.incrementCounter(data.meta.sourceAbbrev, account.collective))
        } yield res.fold(identity, identity)
      }

      def submit(data: OUpload.UploadData[F], sourceId: Ident): F[OUpload.UploadResult] =
        for {
          sOpt     <- store.transact(RSource.find(sourceId)).map(_.toRight(UploadResult.NoSource))
          abbrev    = sOpt.map(_.abbrev).toOption.getOrElse(data.meta.sourceAbbrev)
          updata    = data.copy(meta = data.meta.copy(sourceAbbrev = abbrev))
          accId     = sOpt.map(source => AccountId(source.cid, source.sid))
          result   <- accId.traverse(acc => submit(updata, acc))
        } yield result.fold(identity, identity)

      private def submitJobs(jobs: Vector[RJob]): F[OUpload.UploadResult] = {
        for {
          _     <- logger.fdebug(s"Storing jobs: $jobs")
          _     <- queue.insertAll(jobs)
          _     <- OJoex.notifyAll(store, httpClientEC)
        } yield UploadResult.Success
      }

      private def saveFile(file: File[F]): F[Option[ProcessItemArgs.File]] = {
        logger.finfo(s"Receiving file $file") *>
        store.bitpeace.saveNew(file.data, cfg.files.chunkSize, MimetypeHint(file.name, None), None).
          compile.lastOrError.map(fm => Ident.unsafe(fm.id)).attempt.
          map(_.fold(ex => {
            logger.warn(ex)(s"Could not store file for processing!")
            None
          }, id => Some(ProcessItemArgs.File(file.name, id))))
      }

      private def checkFileList(files: Seq[ProcessItemArgs.File]): F[Either[UploadResult, Unit]] =
        Effect[F].pure(if (files.isEmpty) Left(UploadResult.NoFiles) else Right(()))

      private def makeJobs(args: Vector[ProcessItemArgs], account: AccountId, prio: Priority, tracker: Option[Ident]): F[Vector[RJob]] = {
        def create(id: Ident, now: Timestamp, arg: ProcessItemArgs): RJob =
          RJob.newJob(id, ProcessItemArgs.taskName, account.collective, arg, arg.makeSubject, now, account.user, prio, tracker)

        for {
          id   <- Ident.randomId[F]
          now  <- Timestamp.current[F]
          jobs = args.map(a => create(id, now, a))
        } yield jobs

      }
    })
}
