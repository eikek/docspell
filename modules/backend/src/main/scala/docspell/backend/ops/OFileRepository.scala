/*
 * Copyright 2020 Eike K. & Contributors
 *
 * SPDX-License-Identifier: AGPL-3.0-or-later
 */

package docspell.backend.ops

import cats.data.OptionT
import cats.effect._
import cats.implicits._
import docspell.backend.JobFactory
import docspell.backend.ops.OFileRepository.IntegrityResult
import docspell.common._
import docspell.scheduler.JobQueue
import docspell.store.Store
import docspell.store.records.RJob
import scodec.bits.ByteVector

trait OFileRepository[F[_]] {

  /** Inserts the job or return None if such a job already is running. */
  def cloneFileRepository(args: FileCopyTaskArgs, notifyJoex: Boolean): F[Option[RJob]]

  def checkIntegrityAll(part: FileKeyPart, notifyJoex: Boolean): F[Option[RJob]]

  def checkIntegrity(key: FileKey, hash: Option[ByteVector]): F[Option[IntegrityResult]]
}

object OFileRepository {

  case class IntegrityResult(ok: Boolean, key: FileKey)

  def apply[F[_]: Async](
      store: Store[F],
      queue: JobQueue[F],
      joex: OJoex[F]
  ): Resource[F, OFileRepository[F]] =
    Resource.pure(new OFileRepository[F] {
      private[this] val logger = docspell.logging.getLogger[F]

      def cloneFileRepository(
          args: FileCopyTaskArgs,
          notifyJoex: Boolean
      ): F[Option[RJob]] =
        for {
          job <- JobFactory.fileCopy(args)
          flag <- queue.insertIfNew(job)
          _ <- if (notifyJoex) joex.notifyAllNodes else ().pure[F]
        } yield Option.when(flag)(job)

      def checkIntegrityAll(part: FileKeyPart, notifyJoex: Boolean): F[Option[RJob]] =
        for {
          job <- JobFactory.integrityCheck(FileIntegrityCheckArgs(part))
          flag <- queue.insertIfNew(job)
          _ <- if (notifyJoex) joex.notifyAllNodes else ().pure[F]
        } yield Option.when(flag)(job)

      def checkIntegrity(
          key: FileKey,
          hash: Option[ByteVector]
      ): F[Option[IntegrityResult]] =
        (for {
          _ <- OptionT.liftF(
            logger.debugWith(s"Checking file $key")(_.data("fileKey", key))
          )
          expectedHash <-
            hash.fold(OptionT(store.fileRepo.findMeta(key)).map(_.checksum))(h =>
              OptionT.pure[F](h)
            )

          actualHash <-
            OptionT.liftF(
              logger.debugWith(s"Calculating new hash for $key")(
                _.data("fileKey", key)
              ) *>
                store.fileRepo
                  .getBytes(key)
                  .through(fs2.hash.sha256)
                  .compile
                  .foldChunks(ByteVector.empty)(_ ++ _.toByteVector)
            )
          res = IntegrityResult(expectedHash == actualHash, key)
          _ <- OptionT.liftF {
            if (res.ok) logger.debug(s"File hashes match for $key")
            else logger.warnWith(s"File hashes differ for: $key")(_.data("fileKey", key))
          }
        } yield res).value
    })
}
