package docspell.joex.process

import cats.effect._
import cats.implicits._

import docspell.backend.ops.OItem
import docspell.common._
import docspell.joex.scheduler.Task

object SetGivenData {

  def apply[F[_]: Sync](
      ops: OItem[F]
  )(data: ItemData): Task[F, ProcessItemArgs, ItemData] =
    if (data.item.state.isValid)
      Task
        .log[F, ProcessItemArgs](_.debug(s"Not setting data on existing item"))
        .map(_ => data)
    else
      Task { ctx =>
        val itemId     = data.item.id
        val folderId   = ctx.args.meta.folderId
        val collective = ctx.args.meta.collective
        for {
          _ <- ctx.logger.info("Starting setting given data")
          _ <- ctx.logger.debug(s"Set item folder: '${folderId.map(_.id)}'")
          e <- ops.setFolder(itemId, folderId, collective).attempt
          _ <- e.fold(
            ex => ctx.logger.warn(s"Error setting folder: ${ex.getMessage}"),
            _ => ().pure[F]
          )
        } yield data
      }

}
