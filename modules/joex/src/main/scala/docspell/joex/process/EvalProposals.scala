/*
 * Copyright 2020 Eike K. & Contributors
 *
 * SPDX-License-Identifier: AGPL-3.0-or-later
 */

package docspell.joex.process

import java.time.{LocalDate, Period}

import cats.effect.Sync
import cats.implicits._

import docspell.common._
import docspell.scheduler.Task
import docspell.store.Store
import docspell.store.records.{RAttachmentMeta, RPerson}

/** Calculate weights for candidates that adds the most likely candidate a lower number.
  */
object EvalProposals {

  def apply[F[_]: Sync](
      store: Store[F]
  )(data: ItemData): Task[F, ProcessItemArgs, ItemData] =
    Task { _ =>
      for {
        now <- Timestamp.current[F]
        personRefs <- findOrganizationRelation[F](data, store)
        metas = data.metas.map(calcCandidateWeight(now.toUtcDate, personRefs))
      } yield data.copy(metas = metas)
    }

  def findOrganizationRelation[F[_]: Sync](
      data: ItemData,
      store: Store[F]
  ): F[Map[Ident, PersonRef]] = {
    val corrPersIds = data.metas
      .map(_.proposals)
      .appended(data.classifyProposals)
      .flatMap(_.find(MetaProposalType.CorrPerson))
      .flatMap(_.values.toList.map(_.ref.id))
      .toSet
    store
      .transact(RPerson.findOrganization(corrPersIds))
      .map(_.map(p => (p.id, p)).toMap)
  }

  def calcCandidateWeight(now: LocalDate, personRefs: Map[Ident, PersonRef])(
      rm: RAttachmentMeta
  ): RAttachmentMeta = {
    val list = rm.proposals.change(mp => mp.addWeights(weight(rm, mp, now, personRefs)))
    rm.copy(proposals = list.sortByWeights)
  }

  def weight(
      rm: RAttachmentMeta,
      mp: MetaProposal,
      ref: LocalDate,
      personRefs: Map[Ident, PersonRef]
  )(
      cand: MetaProposal.Candidate
  ): Double =
    mp.proposalType match {
      case MetaProposalType.DueDate =>
        // for due dates, sort earliest on top
        MetaProposal
          .parseDate(cand)
          .map { ld =>
            val p = Period.between(ref, ld)
            // conversion only for sorting
            val d = p.getYears * 365 + p.getMonths * 31 + p.getDays
            d.toDouble
          }
          .getOrElse(2000.0)
      case _ =>
        val textLen = rm.content.map(_.length).getOrElse(0)
        val tagCount = cand.origin.size.toDouble
        val pos = cand.origin.map(_.startPosition).min
        val words = cand.origin.map(_.label.split(' ').length).max.toDouble
        val nerFac =
          cand.origin.map(label => nerTagFactor(label.tag, mp.proposalType)).min
        val corrPerFac = corrOrgPersonFactor(rm, mp, personRefs, cand)
        1 / words * (1 / tagCount) * positionWeight(pos, textLen) * nerFac * corrPerFac
    }

  def corrOrgPersonFactor(
      rm: RAttachmentMeta,
      mp: MetaProposal,
      personRefs: Map[Ident, PersonRef],
      cand: MetaProposal.Candidate
  ): Double =
    mp.proposalType match {
      case MetaProposalType.CorrPerson =>
        (for {
          currentOrg <- rm.proposals
            .find(MetaProposalType.CorrOrg)
            .map(_.values.head.ref.id)
          personOrg <- personRefs.get(cand.ref.id).flatMap(_.organization)
          fac = if (currentOrg == personOrg) 0.5 else 1
        } yield fac).getOrElse(1)
      case _ =>
        1
    }

  def positionWeight(pos: Int, total: Int): Double =
    if (total <= 0) 1
    else {
      val p = math.abs(pos.toDouble / total.toDouble)
      if (p < 0.7) p / 2
      else p
    }

  def nerTagFactor(tag: NerTag, mt: MetaProposalType): Double =
    tag match {
      case NerTag.Date     => 1.0
      case NerTag.Email    => 0.5
      case NerTag.Location => 1.0
      case NerTag.Misc     => 1.0
      case NerTag.Organization =>
        if (mt == MetaProposalType.CorrOrg) 0.8
        else 1.0
      case NerTag.Person =>
        if (
          mt == MetaProposalType.CorrPerson ||
          mt == MetaProposalType.ConcPerson
        ) 0.8
        else 1.0
      case NerTag.Website => 0.5
    }
}
