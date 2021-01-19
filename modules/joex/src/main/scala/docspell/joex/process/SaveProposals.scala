package docspell.joex.process

import cats.effect.Sync
import cats.implicits._
import docspell.common._
import docspell.joex.scheduler.Task
import docspell.store.AddResult
import docspell.store.records._

/** Saves the proposals in the database
  */
object SaveProposals {

  def apply[F[_]: Sync](data: ItemData): Task[F, ProcessItemArgs, ItemData] =
    Task { ctx =>
      for {
        _ <- ctx.logger.info("Storing proposals")
        _ <- data.metas
          .traverse(rm =>
            ctx.logger.debug(
              s"Storing attachment proposals: ${rm.proposals}"
            ) *> ctx.store.transact(RAttachmentMeta.updateProposals(rm.id, rm.proposals))
          )
        _ <- data.classifyProposals match {
          case Some(clp) =>
            val itemId = data.item.id
            ctx.logger.debug(s"Storing classifier proposals: $clp") *>
              ctx.store
                .add(
                  RItemProposal.createNew(itemId, clp),
                  RItemProposal.exists(itemId)
                )
                .flatMap({
                  case AddResult.EntityExists(_) =>
                    ctx.store.transact(RItemProposal.updateProposals(itemId, clp))
                  case AddResult.Failure(ex) =>
                    ctx.logger
                      .warn(s"Could not store classifier proposals: ${ex.getMessage}") *>
                      0.pure[F]
                  case AddResult.Success =>
                    1.pure[F]
                })
          case None =>
            0.pure[F]
        }
      } yield data
    }
}
