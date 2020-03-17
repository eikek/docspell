package docspell.joex.process

import cats.implicits._
import cats.effect.Sync
import docspell.common._
import docspell.joex.scheduler.Task
import docspell.store.records._

/** Saves the proposals in the database
  *
  */
object SaveProposals {

  def apply[F[_]: Sync](data: ItemData): Task[F, ProcessItemArgs, ItemData] =
    Task { ctx =>
      ctx.logger.info("Storing proposals") *>
        data.metas
          .traverse(rm =>
            ctx.logger.debug(s"Storing attachment proposals: ${rm.proposals}") *>
              ctx.store.transact(RAttachmentMeta.updateProposals(rm.id, rm.proposals))
          )
          .map(_ => data)
    }
}
