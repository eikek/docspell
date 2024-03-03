/*
 * Copyright 2020 Eike K. & Contributors
 *
 * SPDX-License-Identifier: AGPL-3.0-or-later
 */

package docspell.joex.filecopy

import cats.data.NonEmptyList
import cats.effect._
import cats.implicits._

import docspell.common.FileCopyTaskArgs.Selection
import docspell.common.{FileCopyTaskArgs, Ident}
import docspell.joex.Config
import docspell.logging.Logger
import docspell.scheduler.{JobTaskResultEncoder, Task}
import docspell.store.Store
import docspell.store.file.{BinnyUtils, FileRepository, FileRepositoryConfig}

import binny.CopyTool.Counter
import binny.{BinaryId, BinaryStore, CopyTool}
import io.circe.generic.semiauto.deriveCodec
import io.circe.{Codec, Decoder, Encoder}

object FileCopyTask {
  type Args = FileCopyTaskArgs

  case class CopyResult(success: Boolean, message: String, counter: List[Counter])
  object CopyResult {
    def noSourceImpl: CopyResult =
      CopyResult(success = false, "No source BinaryStore implementation found!", Nil)

    def noTargetImpl: CopyResult =
      CopyResult(success = false, "No target BinaryStore implementation found!", Nil)

    def noSourceStore(id: Ident): CopyResult =
      CopyResult(
        success = false,
        s"No source file repo found with id: ${id.id}. Make sure it is present in the config.",
        Nil
      )

    def noTargetStore: CopyResult =
      CopyResult(success = false, "No target file repositories defined", Nil)

    def success(counter: NonEmptyList[Counter]): CopyResult =
      CopyResult(success = true, "Done", counter.toList)

    implicit val binaryIdCodec: Codec[BinaryId] =
      Codec.from(
        Decoder.decodeString.map(BinaryId.apply),
        Encoder.encodeString.contramap(_.id)
      )

    implicit val counterEncoder: Codec[Counter] =
      deriveCodec
    implicit val jsonCodec: Codec[CopyResult] =
      deriveCodec

    implicit val jobTaskResultEncoder: JobTaskResultEncoder[CopyResult] =
      JobTaskResultEncoder.fromJson[CopyResult].withMessage { result =>
        val allGood = result.counter.map(_.success).sum
        val failed = result.counter.map(_.failed.size).sum
        if (result.success)
          s"Successfully copied $allGood files to ${result.counter.size} stores."
        else
          s"Copying files failed for ${failed} files! $allGood were copied successfully."
      }
  }

  def onCancel[F[_]]: Task[F, Args, Unit] =
    Task.log(_.warn(s"Cancelling ${FileCopyTaskArgs.taskName.id} task"))

  def apply[F[_]: Async](cfg: Config, store: Store[F]): Task[F, Args, CopyResult] =
    Task { ctx =>
      val src = ctx.args.from
        .map(id =>
          cfg.files.getFileRepositoryConfig(id).toRight(CopyResult.noSourceStore(id))
        )
        .getOrElse(Right(cfg.files.defaultFileRepositoryConfig))

      val targets = ctx.args.to match {
        case Selection.All =>
          cfg.files.enabledStores.values.toList
            .map(FileRepositoryConfig.fromFileStoreConfig(cfg.files.chunkSize, _))
        case Selection.Stores(ids) =>
          ids.traverse(cfg.files.getFileRepositoryConfig).map(_.toList).getOrElse(Nil)
      }

      // remove source from targets if present there
      val data =
        for {
          srcConfig <- src
          trgConfig <- NonEmptyList
            .fromList(targets.filter(_ != srcConfig))
            .toRight(CopyResult.noTargetStore)

          srcRepo = store.createFileRepository(srcConfig, withAttributeStore = true)
          targetRepos = trgConfig.map(
            store.createFileRepository(_, withAttributeStore = false)
          )
        } yield (srcRepo, targetRepos)

      data match {
        case Right((from, tos)) =>
          ctx.logger.info(s"Start copying all files from $from") *>
            copy(ctx.logger, from, tos).flatTap(r =>
              if (r.success) ctx.logger.info(s"Copying finished: ${r.counter}")
              else ctx.logger.error(s"Copying failed: $r")
            )

        case Left(res) =>
          ctx.logger.error(s"Copying failed: $res") *> res.pure[F]
      }
    }

  def copy[F[_]: Async](
      logger: Logger[F],
      from: FileRepository[F],
      to: NonEmptyList[FileRepository[F]]
  ): F[CopyResult] =
    FileRepository.getDelegate(from) match {
      case None =>
        CopyResult.noSourceImpl.pure[F]

      case Some(src) =>
        to.traverse(FileRepository.getDelegate) match {
          case None =>
            CopyResult.noTargetImpl.pure[F]

          case Some(targets) =>
            val log = BinnyUtils.LoggerAdapter(logger)
            val maxConcurrent = {
              val nCores = Runtime.getRuntime.availableProcessors()
              if (nCores > 2) nCores / 2 else 1
            }

            def copyTo(to: BinaryStore[F]) =
              CopyTool.copyAll[F](log, src, to, 50, maxConcurrent)

            logger.info(s"Start copying ${from.config} -> ${to.map(_.config)}") *>
              targets.traverse(copyTo).map(CopyResult.success)
        }
    }
}
