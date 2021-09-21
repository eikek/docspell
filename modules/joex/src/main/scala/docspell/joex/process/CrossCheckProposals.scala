/*
 * Copyright 2020 Eike K. & Contributors
 *
 * SPDX-License-Identifier: AGPL-3.0-or-later
 */

package docspell.joex.process

import cats.data.NonEmptyList
import cats.data.OptionT
import cats.effect.Sync
import cats.implicits._

import docspell.common._
import docspell.joex.scheduler.Task

/** After candidates have been determined, the set is reduced by doing some cross checks.
  * For example: if a organization is suggested as correspondent, the correspondent person
  * must be linked to that organization. So this *removes all* person candidates that are
  * not linked to the first organization candidate (which will be linked to the item).
  */
object CrossCheckProposals {

  def apply[F[_]: Sync](data: ItemData): Task[F, ProcessItemArgs, ItemData] =
    Task { ctx =>
      val proposals = data.finalProposals
      val corrOrg   = proposals.find(MetaProposalType.CorrOrg)
      (for {
        orgRef   <- OptionT.fromOption[F](corrOrg)
        persRefs <- OptionT.liftF(EvalProposals.findOrganizationRelation(data, ctx))
        clProps <- OptionT.liftF(
          personOrgCheck[F](ctx.logger, data.classifyProposals, persRefs)(orgRef)
        )
        atProps <- OptionT.liftF {
          data.metas.traverse(ra =>
            personOrgCheck[F](ctx.logger, ra.proposals, persRefs)(orgRef).map(nl =>
              ra.copy(proposals = nl)
            )
          )
        }
      } yield data.copy(classifyProposals = clProps, metas = atProps)).getOrElse(data)
    }

  def personOrgCheck[F[_]: Sync](
      logger: Logger[F],
      mpl: MetaProposalList,
      persRefs: Map[Ident, PersonRef]
  )(
      corrOrg: MetaProposal
  ): F[MetaProposalList] = {
    val orgId = corrOrg.values.head.ref.id
    mpl.find(MetaProposalType.CorrPerson) match {
      case Some(ppl) =>
        val list = ppl.values.filter(c =>
          persRefs.get(c.ref.id).exists(_.organization == Some(orgId))
        )

        if (ppl.values.toList == list) mpl.pure[F]
        else
          logger.debug(
            "Removing person suggestion, because it doesn't match organization"
          ) *> NonEmptyList
            .fromList(list)
            .map(nel => mpl.replace(MetaProposal(ppl.proposalType, nel)))
            .getOrElse(mpl.filter(_.proposalType != ppl.proposalType))
            .pure[F]

      case None =>
        mpl.pure[F]
    }
  }
}
