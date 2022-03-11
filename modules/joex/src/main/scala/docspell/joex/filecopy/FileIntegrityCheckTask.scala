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
import docspell.joex.scheduler.{JobTaskResultEncoder, Task}
import docspell.store.records.RFileMeta
import io.circe.Encoder
import io.circe.generic.semiauto.deriveEncoder

object FileIntegrityCheckTask {
  type Args = FileIntegrityCheckArgs

  case class Result(ok: Int, failedKeys: Set[FileKey], notFoundKeys: Set[FileKey]) {
    override def toString: String =
      s"Result(ok=$ok, failed=${failedKeys.size}, notFound=${notFoundKeys.size}, " +
        s"keysFailed=$failedKeys, notFoundKeys=$notFoundKeys)"
  }
  object Result {
    val empty = Result(0, Set.empty, Set.empty)

    def notFound(key: FileKey) = Result(0, Set.empty, Set(key))

    def from(r: IntegrityResult): Result =
      if (r.ok) Result(1, Set.empty, Set.empty) else Result(0, Set(r.key), Set.empty)

    implicit val monoid: Monoid[Result] =
      Monoid.instance(
        empty,
        (a, b) =>
          Result(
            a.ok + b.ok,
            a.failedKeys ++ b.failedKeys,
            a.notFoundKeys ++ b.notFoundKeys
          )
      )

    implicit val jsonEncoder: Encoder[Result] =
      deriveEncoder

    implicit val jobTaskResultEncoder: JobTaskResultEncoder[Result] =
      JobTaskResultEncoder.fromJson[Result].withMessage { result =>
        s"Integrity check finished. Ok: ${result.ok}, " +
          s"Failed: ${result.failedKeys.size}, Not found: ${result.notFoundKeys.size}"
      }
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
        .evalMap(meta =>
          ops.checkIntegrity(meta.id, meta.checksum.some).flatMap {
            case Some(r) =>
              Result.from(r).pure[F]
            case None =>
              ctx.logger
                .error(s"File '${meta.id.toString}' not found in file repository")
                .as(Result.notFound(meta.id))
          }
        )
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
