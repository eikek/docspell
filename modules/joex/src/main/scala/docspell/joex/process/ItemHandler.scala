/*
 * Copyright 2020 Eike K. & Contributors
 *
 * SPDX-License-Identifier: AGPL-3.0-or-later
 */

package docspell.joex.process

import cats.data.OptionT
import cats.effect._
import cats.implicits._
import fs2.Stream

import docspell.analysis.TextAnalyser
import docspell.backend.ops.OItem
import docspell.common.{ItemState, ProcessItemArgs}
import docspell.ftsclient.FtsClient
import docspell.joex.Config
import docspell.joex.analysis.RegexNerFile
import docspell.scheduler.Task
import docspell.store.Store
import docspell.store.queries.QItem
import docspell.store.records.RItem

object ItemHandler {
  type Args = ProcessItemArgs

  def onCancel[F[_]: Sync](store: Store[F]): Task[F, Args, Unit] =
    logWarn[F]("Now cancelling.").flatMap(_ =>
      markItemCreated(store).flatMap {
        case true =>
          Task.pure(())
        case false =>
          deleteByFileIds[F](store).flatMap(_ => deleteFiles(store))
      }
    )

  def newItem[F[_]: Async](
      cfg: Config,
      store: Store[F],
      itemOps: OItem[F],
      fts: FtsClient[F],
      analyser: TextAnalyser[F],
      regexNer: RegexNerFile[F]
  ): Task[F, Args, Option[ItemData]] =
    logBeginning[F].flatMap(_ =>
      DuplicateCheck[F](store)
        .flatMap(args =>
          if (args.files.isEmpty) logNoFiles[F].map(_ => None)
          else {
            val create: Task[F, Args, ItemData] =
              CreateItem[F](store).contramap(_ => args.pure[F])
            create
              .flatMap(itemStateTask(store, ItemState.Processing))
              .flatMap(safeProcess[F](cfg, store, itemOps, fts, analyser, regexNer))
              .map(_.some)
          }
        )
    )

  def itemStateTask[F[_]: Sync, A](store: Store[F], state: ItemState)(
      data: ItemData
  ): Task[F, A, ItemData] =
    Task(_ =>
      store
        .transact(RItem.updateState(data.item.id, state, ItemState.invalidStates))
        .map(_ => data)
    )

  def isLastRetry[F[_]]: Task[F, Args, Boolean] =
    Task(_.isLastRetry)

  def safeProcess[F[_]: Async](
      cfg: Config,
      store: Store[F],
      itemOps: OItem[F],
      fts: FtsClient[F],
      analyser: TextAnalyser[F],
      regexNer: RegexNerFile[F]
  )(data: ItemData): Task[F, Args, ItemData] =
    isLastRetry[F].flatMap {
      case true =>
        ProcessItem[F](cfg, itemOps, fts, analyser, regexNer, store)(data).attempt
          .flatMap {
            case Right(d) =>
              Task.pure(d)
            case Left(ex) =>
              logWarn[F](
                "Processing failed on last retry. Creating item but without proposals."
              ).flatMap(_ => itemStateTask(store, ItemState.Created)(data))
                .andThen(_ => Sync[F].raiseError(ex))
          }
      case false =>
        ProcessItem[F](cfg, itemOps, fts, analyser, regexNer, store)(data)
          .flatMap(itemStateTask(store, ItemState.Created))
    }

  private def markItemCreated[F[_]: Sync](store: Store[F]): Task[F, Args, Boolean] =
    Task { ctx =>
      val fileMetaIds = ctx.args.files.map(_.fileMetaId).toSet
      (for {
        item <- OptionT(store.transact(QItem.findOneByFileIds(fileMetaIds.toSeq)))
        _ <- OptionT.liftF(
          ctx.logger.info("Processing cancelled. Marking item as created anyways.")
        )
        _ <- OptionT.liftF(
          store
            .transact(
              RItem.updateState(item.id, ItemState.Created, ItemState.invalidStates)
            )
        )
      } yield true)
        .getOrElseF(
          ctx.logger.warn("Processing cancelled. No item created").map(_ => false)
        )
    }

  private def deleteByFileIds[F[_]: Sync](store: Store[F]): Task[F, Args, Unit] =
    Task { ctx =>
      val states = ItemState.invalidStates
      for {
        items <- store.transact(
          QItem.findByFileIds(ctx.args.files.map(_.fileMetaId), states)
        )
        _ <-
          if (items.nonEmpty) ctx.logger.info(s"Deleting items ${items.map(_.id.id)}")
          else
            ctx.logger.info(
              s"No items found for file ids ${ctx.args.files.map(_.fileMetaId)}"
            )
        _ <- items.traverse(i => QItem.delete(store)(i.id, ctx.args.meta.collective))
      } yield ()
    }

  private def deleteFiles[F[_]: Sync](store: Store[F]): Task[F, Args, Unit] =
    Task(ctx =>
      ctx.logger.info("Deleting input files …") *>
        Stream
          .emits(ctx.args.files.map(_.fileMetaId))
          .evalMap(id => store.fileRepo.delete(id).attempt)
          .compile
          .drain
    )

  private def logWarn[F[_]](msg: => String): Task[F, Args, Unit] =
    Task.log(_.warn(msg))

  private def logNoFiles[F[_]]: Task[F, Args, Unit] =
    logWarn(
      "No files to process! Either no files were given or duplicate check removed all."
    )

  private def logBeginning[F[_]]: Task[F, Args, Unit] =
    Task { ctx =>
      val files = ctx.args.files.flatMap(_.name).mkString(", ")
      ctx.logger.info(s"============ Start processing $files ============")
    }
}
