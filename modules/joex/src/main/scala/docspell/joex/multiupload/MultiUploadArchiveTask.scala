/*
 * Copyright 2020 Eike K. & Contributors
 *
 * SPDX-License-Identifier: AGPL-3.0-or-later
 */

package docspell.joex.multiupload

import cats.Monoid
import cats.data.OptionT
import cats.effect._
import cats.implicits._
import fs2.Stream

import docspell.backend.JobFactory
import docspell.common._
import docspell.common.util.Zip
import docspell.logging.Logger
import docspell.scheduler._
import docspell.store.Store

/** Task to submit multiple files at once. By default, one file in an upload results in
  * one item. Zip files are extracted, but its inner files are considered to be one item
  * with (perhaps) multiple attachments.
  *
  * In contrast, this task extracts ZIP files (not recursively) and submits each extracted
  * file to be processed separately. Non-zip files are submitted as is. If zip files
  * contain other zip file, these inner zip files will result in one item each, only the
  * outer zip file is extracted here.
  *
  * Note: the outer zip file only acts as a container to transport multiple files and is
  * NOT kept in docspell!
  */
object MultiUploadArchiveTask {
  type Args = ProcessItemArgs

  def apply[F[_]: Async](store: Store[F], jobStore: JobStore[F]): Task[F, Args, Result] =
    Task { ctx =>
      ctx.args.files
        .traverse { file =>
          isZipFile(store)(file).flatMap {
            case true =>
              ctx.logger.info(s"Extracting zip file ${file.name}") *>
                extractZip(store, ctx.args)(file)
                  .evalTap(entry =>
                    ctx.logger.debug(
                      s"Create job for entry: ${entry.files.flatMap(_.name).mkString(", ")}"
                    )
                  )
                  .evalMap(makeJob[F](ctx, jobStore))
                  .compile
                  .toList
                  .map(Jobs.extracted(file))

            case false =>
              makeJob(ctx, jobStore)(ctx.args.copy(files = List(file))).map(Jobs.normal)
          }
        }
        .map(_.combineAll)
        .flatTap(jobs => jobStore.insertAll(jobs.jobs))
        .flatTap(deleteZips(store, ctx.logger))
        .map(_.result)
        .flatTap(result =>
          ctx.logger.info(
            s"Submitted ${result.submittedFiles}, extracted ${result.extractedZips} zips."
          )
        )
    }

  def onCancel[F[_]: Sync](store: Store[F]): Task[F, ProcessItemArgs, Unit] =
    Task { ctx =>
      for {
        _ <- ctx.logger.warn("Cancelling multi-upload task, deleting uploaded files.")
        _ <- ctx.args.files.map(_.fileMetaId).traverse(store.fileRepo.delete).void
      } yield ()
    }

  private def deleteZips[F[_]: Sync](store: Store[F], logger: Logger[F])(
      jobs: Jobs
  ): F[Unit] =
    logger.info(s"Deleting ${jobs.zips.size} extracted zip fies.") *>
      jobs.zips.map(_.fileMetaId).traverse(store.fileRepo.delete).void

  private def makeJob[F[_]: Sync](ctx: Context[F, Args], jobStore: JobStore[F])(
      args: ProcessItemArgs
  ): F[Job[String]] =
    for {
      currentJob <- jobStore.findById(ctx.jobId)
      prio = currentJob.map(_.priority).getOrElse(Priority.Low)
      submitter = currentJob.map(_.submitter).getOrElse(DocspellSystem.user)
      job <- JobFactory.processItem(
        args,
        AccountId(ctx.args.meta.collective, submitter),
        prio,
        None
      )
    } yield job.encode

  private def isZipFile[F[_]: Sync](
      store: Store[F]
  )(file: ProcessItemArgs.File): F[Boolean] =
    OptionT(store.fileRepo.findMeta(file.fileMetaId))
      .map(_.mimetype.matches(MimeType.zip))
      .getOrElse(false)

  private def extractZip[F[_]: Async](
      store: Store[F],
      args: Args
  )(file: ProcessItemArgs.File): Stream[F, ProcessItemArgs] =
    store.fileRepo
      .getBytes(file.fileMetaId)
      .through(Zip[F]().unzip(glob = args.meta.fileFilter.getOrElse(Glob.all)))
      .through(Binary.toBinary[F])
      .flatMap { entry =>
        val hint = MimeTypeHint(entry.name.some, entry.mime.asString.some)
        entry.data
          .through(
            store.fileRepo.save(args.meta.collective, FileCategory.AttachmentSource, hint)
          )
          .map(key =>
            args.copy(files = ProcessItemArgs.File(entry.name.some, key) :: Nil)
          )
      }

  case class Jobs(
      result: Result,
      jobs: List[Job[String]],
      zips: List[ProcessItemArgs.File]
  )
  object Jobs {
    def extracted(zip: ProcessItemArgs.File)(jobs: List[Job[String]]): Jobs =
      Jobs(Result(jobs.size, 1), jobs, List(zip))

    def normal(job: Job[String]): Jobs =
      Jobs(Result.notExtracted, List(job), Nil)

    val empty: Jobs = Jobs(Result.empty, Nil, Nil)
    implicit val jobsMonoid: Monoid[Jobs] =
      Monoid.instance(
        empty,
        (a, b) => Jobs(a.result.combine(b.result), a.jobs ::: b.jobs, a.zips ::: b.zips)
      )
  }
}
