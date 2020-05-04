package docspell.joex.process

import java.time.{LocalDate, Period}
import cats.implicits._
import cats.effect.Sync
import docspell.common._
import docspell.joex.scheduler.Task
import docspell.store.records.RAttachmentMeta

/** Reorders the proposals to put most probable fits first.
  */
object EvalProposals {

  def apply[F[_]: Sync](data: ItemData): Task[F, ProcessItemArgs, ItemData] =
    Task { _ =>
      Timestamp
        .current[F]
        .map { now =>
          val metas = data.metas.map(reorderCandidates(now.toUtcDate))
          data.copy(metas = metas)
        }
    }

  def reorderCandidates(now: LocalDate)(rm: RAttachmentMeta): RAttachmentMeta = {
    val list = rm.proposals.getTypes.toList
      .map(mpt =>
        rm.proposals.find(mpt) match {
          case Some(mp) =>
            val v = mp.values.sortBy(weight(rm, mp, now))
            Some(mp.copy(values = v))
          case None =>
            None
        }
      )

    rm.copy(proposals = MetaProposalList(list.flatMap(identity)))
  }

  def weight(rm: RAttachmentMeta, mp: MetaProposal, ref: LocalDate)(
      cand: MetaProposal.Candidate
  ): Double =
    mp.proposalType match {
      case MetaProposalType.DueDate =>
        //for due dates, sort earliest on top
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
        val textLen  = rm.content.map(_.length).getOrElse(0)
        val tagCount = cand.origin.size.toDouble
        val pos      = cand.origin.map(_.startPosition).min
        val words    = cand.origin.map(_.label.split(' ').length).max.toDouble
        val nerFac =
          cand.origin.map(label => nerTagFactor(label.tag, mp.proposalType)).min
        (1 / words) * (1 / tagCount) * positionWeight(pos, textLen) * nerFac
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
