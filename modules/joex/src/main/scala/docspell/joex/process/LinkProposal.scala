package docspell.joex.process

import cats.implicits._
import cats.effect.Sync
import docspell.common._
import docspell.joex.scheduler.{Context, Task}
import docspell.store.records.RItem

object LinkProposal {

  def apply[F[_]: Sync](data: ItemData): Task[F, ProcessItemArgs, ItemData] =
    Task { ctx =>
      val proposals = MetaProposalList.flatten(data.metas.map(_.proposals))

      ctx.logger.info(s"Starting linking proposals") *>
      MetaProposalType.all.
        traverse(applyValue(data, proposals, ctx)).
        map(result => ctx.logger.info(s"Results from proposal processing: $result")).
        map(_ => data)
    }

  def applyValue[F[_]: Sync](data: ItemData, proposalList: MetaProposalList, ctx: Context[F, ProcessItemArgs])(mpt: MetaProposalType): F[Result] = {
    proposalList.find(mpt) match {
      case None =>
        Result.noneFound(mpt).pure[F]
      case Some(a) if a.isSingleValue =>
        ctx.logger.info(s"Found one candidate for ${a.proposalType}") *>
          setItemMeta(data.item.id, ctx, a.proposalType, a.values.head.ref.id).
            map(_ => Result.single(mpt))
      case Some(a) =>
        ctx.logger.info(s"Found many (${a.size}, ${a.values.map(_.ref.id.id)}) candidates for ${a.proposalType}. Setting first.") *>
          setItemMeta(data.item.id, ctx, a.proposalType, a.values.head.ref.id).
            map(_ => Result.multiple(mpt))
    }
  }

  def setItemMeta[F[_]: Sync](itemId: Ident, ctx: Context[F, ProcessItemArgs], mpt: MetaProposalType, value: Ident): F[Int] =
    mpt match {
      case MetaProposalType.CorrOrg =>
        ctx.logger.debug(s"Updating item organization with: ${value.id}") *>
          ctx.store.transact(RItem.updateCorrOrg(itemId, ctx.args.meta.collective, Some(value)))
      case MetaProposalType.ConcPerson =>
        ctx.logger.debug(s"Updating item concerning person with: $value") *>
          ctx.store.transact(RItem.updateConcPerson(itemId, ctx.args.meta.collective, Some(value)))
      case MetaProposalType.CorrPerson =>
        ctx.logger.debug(s"Updating item correspondent person with: $value") *>
          ctx.store.transact(RItem.updateCorrPerson(itemId, ctx.args.meta.collective, Some(value)))
      case MetaProposalType.ConcEquip =>
        ctx.logger.debug(s"Updating item concerning equipment with: $value") *>
          ctx.store.transact(RItem.updateConcEquip(itemId, ctx.args.meta.collective, Some(value)))
      case MetaProposalType.DocDate =>
        ctx.logger.debug(s"Not linking document date suggestion ${value.id}").map(_ => 0)
      case MetaProposalType.DueDate =>
        ctx.logger.debug(s"Not linking document date suggestion ${value.id}").map(_ => 0)
    }


  sealed trait Result {
    def proposalType: MetaProposalType
  }
  object Result {

    case class NoneFound(proposalType: MetaProposalType) extends Result
    case class SingleResult(proposalType: MetaProposalType) extends Result
    case class MultipleResult(proposalType: MetaProposalType) extends Result

    def noneFound(proposalType: MetaProposalType): Result = NoneFound(proposalType)
    def single(proposalType: MetaProposalType): Result = SingleResult(proposalType)
    def multiple(proposalType: MetaProposalType): Result = MultipleResult(proposalType)
  }
}
