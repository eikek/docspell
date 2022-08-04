/*
 * Copyright 2020 Eike K. & Contributors
 *
 * SPDX-License-Identifier: AGPL-3.0-or-later
 */

package docspell.backend.ops

import java.security.MessageDigest
import cats.data.OptionT
import cats.effect._
import cats.syntax.all._
import fs2.{Pipe, Stream}
import docspell.backend.JobFactory
import docspell.backend.ops.ODownloadAll.model._
import docspell.backend.ops.OJob.JobCancelResult
import docspell.backend.task.DownloadZipArgs
import docspell.common._
import docspell.query.ItemQuery.Expr.ValidItemStates
import docspell.query.{ItemQuery, ItemQueryParser}
import docspell.scheduler.JobStore
import docspell.scheduler.usertask.UserTaskScope
import docspell.store.Store
import docspell.store.file.FileMetadata
import docspell.store.queries.{QItem, Query}
import docspell.store.records.{RDownloadQuery, RFileMeta, RJob}
import io.circe.generic.semiauto.{deriveDecoder, deriveEncoder}
import io.circe.{Decoder, Encoder}
import scodec.bits.ByteVector

trait ODownloadAll[F[_]] {

  /** Calculates what kind of zip file would be created and checks the server thresholds.
    */
  def getSummary(account: AccountInfo, req: DownloadRequest): F[DownloadSummary]

  /** Same as `getSummary` but also submits the job to really create the zip file if
    * allowed and necessary.
    */
  def submit(accountId: AccountInfo, req: DownloadRequest): F[DownloadSummary]

  /** Given the id from the summary, cancels a running job. */
  def cancelDownload(cid: CollectiveId, id: Ident): F[OJob.JobCancelResult]

  /** Returns the file if it is present, given a summary id. */
  def getFile(collective: CollectiveId, id: Ident): F[Option[DownloadAllFile[F]]]

  /** Deletes a download archive given it's id. */
  def deleteFile(id: Ident): F[Unit]

  /** Deletes one file at a time going through all older than `ts`. */
  def deleteOlderThan(ts: Timestamp): F[Int]
}

object ODownloadAll {

  def apply[F[_]: Async](
      store: Store[F],
      jobs: OJob[F],
      jobStore: JobStore[F]
  ): ODownloadAll[F] =
    new ODownloadAll[F] {
      private[this] val logger = docspell.logging.getLogger[F]

      def getSummary(
          account: AccountInfo,
          req: DownloadRequest
      ): F[DownloadSummary] = {
        val query = req.toQuery(account)

        for {
          now <- Timestamp.current[F]
          today = now.toUtcDate
          summary <- store
            .transact(QItem.findFiles(query, req.fileType, today, req.maxFiles + 1, 50))
            .through(DownloadSummary.accumulate)
            .compile
            .lastOrError
          state <- getState(summary, req)
        } yield summary.copy(state = state)
      }

      def submit(
          account: AccountInfo,
          req: DownloadRequest
      ): F[DownloadSummary] = for {
        _ <- logger.info(s"Download all request: $req")
        summary <- getSummary(account, req)
        args = DownloadZipArgs(account, req)
        _ <- OptionT
          .whenF(summary.state == DownloadState.NotPresent) {
            JobFactory
              .downloadZip(args, summary.id, UserTaskScope(account))
              .flatMap(job =>
                logger.info(s"Submitting download all job: $job") *> jobStore
                  .insertIfNew(job.encode)
              )
          }
          .value
        _ <- OptionT
          .whenF(summary.state != DownloadState.NotPresent)(
            logger.info(s"Not inserting job. State = ${summary.state}")
          )
          .value
        state <- getState(summary, req)
      } yield summary.copy(state = state)

      private def getState(
          summary: DownloadSummary,
          req: DownloadRequest
      ): F[DownloadState] =
        for {
          inDB <- store.transact(RDownloadQuery.existsById(summary.id))
          inQueue <- store.transact(RJob.findNonFinalByTracker(summary.id))
          state =
            if (inDB) DownloadState.Present
            else if (inQueue.isDefined) DownloadState.Preparing
            else if (
              summary.fileCount > req.maxFiles || summary.uncompressedSize > req.maxSize
            ) DownloadState.Forbidden
            else if (summary.fileCount <= 0) DownloadState.Empty
            else DownloadState.NotPresent
        } yield state

      def getFile(collective: CollectiveId, id: Ident) =
        OptionT(store.transact(RDownloadQuery.findById(id)))
          .map(_._2)
          .map(md =>
            DownloadAllFile(id, md.toFileMetadata, store.fileRepo.getBytes(md.id))
          )
          .semiflatTap(_ => store.transact(RDownloadQuery.updateAccessNow(id)))
          .value

      def deleteFile(id: Ident): F[Unit] =
        (for {
          x <- OptionT(store.transact(RDownloadQuery.findById(id)))
          fileKey = x._1.fileId
          _ <- OptionT.liftF(deleteByFileKey(fileKey))
        } yield ())
          .getOrElse(())

      def deleteOlderThan(ts: Timestamp): F[Int] =
        Stream
          .eval(store.transact(RDownloadQuery.findOlderThan(ts, 1)))
          .repeat
          .takeWhile(_.nonEmpty)
          .evalMap(_.traverse(deleteByFileKey))
          .map(_.length)
          .compile
          .foldMonoid

      private def deleteByFileKey(fkey: FileKey): F[Unit] =
        for {
          _ <- logger.info(s"Deleting download archive: $fkey")
          _ <- store.transact(RDownloadQuery.deleteByFileKey(fkey))
          _ <- store.fileRepo.delete(fkey)
        } yield ()

      def cancelDownload(cid: CollectiveId, id: Ident) =
        OptionT(store.transact(RDownloadQuery.findById(id)))
          .flatMap(t => OptionT(store.transact(RJob.findNonFinalByTracker(t._1.id))))
          .semiflatMap(job => jobs.cancelJob(job.id, UserTaskScope.collective(cid)))
          .getOrElse(JobCancelResult.jobNotFound)
    }

  object model {

    final case class DownloadRequest(
        query: ItemQuery,
        fileType: DownloadAllType,
        maxFiles: Int,
        maxSize: ByteSize
    ) {
      def toQuery(account: AccountInfo): Query =
        Query
          .all(account)
          .withFix(_.andQuery(ValidItemStates))
          .withCond(_ => Query.QueryExpr(query.expr))

      def itemQueryString =
        ItemQueryParser.asString(query.expr)
    }
    object DownloadRequest {
      import docspell.backend.codec.ItemQueryCodec._

      implicit val jsonDecoder: Decoder[DownloadRequest] =
        deriveDecoder

      implicit val jsonEncoder: Encoder[DownloadRequest] =
        deriveEncoder
    }

    final case class DownloadSummary(
        id: Ident,
        fileCount: Int,
        uncompressedSize: ByteSize,
        state: DownloadState
    )

    object DownloadSummary {
      val empty: DownloadSummary =
        DownloadSummary(
          Ident.unsafe(""),
          0,
          ByteSize.zero,
          DownloadState.Empty
        )

      def accumulate[F[_]]: Pipe[F, RFileMeta, DownloadSummary] =
        in =>
          Stream
            .suspend {
              in.fold((empty, MessageDigest.getInstance("SHA-256"))) {
                case ((summary, digest), meta) =>
                  val next = summary.copy(
                    fileCount = summary.fileCount + 1,
                    uncompressedSize = summary.uncompressedSize + meta.length
                  )
                  digest.update(meta.checksum.toArray)
                  (next, digest)
              }
            }
            .map { case (summary, digest) =>
              val c = ByteVector.view(digest.digest())
              val state =
                if (summary.fileCount > 0) DownloadState.NotPresent
                else DownloadState.Empty
              summary.copy(id = Ident.unsafe(c.toBase58), state = state)
            }
    }

    final case class DownloadAllFile[F[_]](
        id: Ident,
        meta: FileMetadata,
        data: Stream[F, Byte]
    ) extends OItemSearch.BinaryData[F] {
      def name = Some(
        s"docspell-download-${id.id.take(7)}-${meta.created.forFilename}.zip"
      )
      def fileId = meta.id
    }
  }
}
