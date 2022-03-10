/*
 * Copyright 2020 Eike K. & Contributors
 *
 * SPDX-License-Identifier: AGPL-3.0-or-later
 */

package docspell.joex.filecopy

import cats.Monoid
import cats.effect._
import cats.implicits._

import docspell.backend.ops.OFileRepository
import docspell.backend.ops.OFileRepository.IntegrityResult
import docspell.common.{FileIntegrityCheckArgs, FileKey}
import docspell.joex.scheduler.Task
import docspell.store.records.RFileMeta

import io.circe.Encoder
import io.circe.generic.semiauto.deriveEncoder

object FileIntegrityCheckTask {
  type Args = FileIntegrityCheckArgs

  case class Result(ok: Int, failedKeys: Set[FileKey]) {
    override def toString: String =
      s"Result(ok=$ok, failed=${failedKeys.size}, keysFailed=$failedKeys)"
  }
  object Result {
    val empty = Result(0, Set.empty)

    def from(r: IntegrityResult): Result =
      if (r.ok) Result(1, Set.empty) else Result(0, Set(r.key))

    implicit val monoid: Monoid[Result] =
      Monoid.instance(empty, (a, b) => Result(a.ok + b.ok, a.failedKeys ++ b.failedKeys))

    implicit val jsonEncoder: Encoder[Result] =
      deriveEncoder
  }

  def apply[F[_]: Sync](ops: OFileRepository[F]): Task[F, Args, Result] =
    Task { ctx =>
      ctx.store
        .transact(
          RFileMeta
            .findAll(ctx.args.pattern, 50)
        )
        .chunks
        .evalTap(c => ctx.logger.info(s"Checking next ${c.size} files…"))
        .unchunks
        .evalMap(meta => ops.checkIntegrity(meta.id, meta.checksum.some))
        .evalMap {
          case Some(r) =>
            Result.from(r).pure[F]
          case None =>
            ctx.logger.error(s"File not found").as(Result.empty)
        }
        .foldMonoid
        .compile
        .lastOrError
        .flatTap(result =>
          ctx.logger
            .infoWith(s"File check result: $result")(_.data("integrityCheck", result))
        )
    }

  def onCancel[F[_]]: Task[F, Args, Unit] =
    Task.log(_.warn(s"Cancelling ${FileIntegrityCheckArgs.taskName.id} task"))

}
