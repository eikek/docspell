/*
 * Copyright 2020 Eike K. & Contributors
 *
 * SPDX-License-Identifier: AGPL-3.0-or-later
 */

package docspell.common

import java.time.LocalDate

import cats.Order
import cats.data.NonEmptyList
import cats.implicits._

import docspell.common.MetaProposal.Candidate
import docspell.common._

import io.circe._
import io.circe.generic.semiauto._

/** A proposed meta data to an item.
  *
  * There is only one value for each proposal type. The list of candidates is meant to be
  * ordered from the best match to the lowest match.
  *
  * The candidate is already "resolved" against the database and contains a valid record
  * (with its ID and a human readable name). Additionally it carries a set of "labels"
  * (which may be empty) that are the source of this candidate.
  */
case class MetaProposal(proposalType: MetaProposalType, values: NonEmptyList[Candidate]) {

  def addIdRef(refs: Seq[Candidate]): MetaProposal =
    copy(values = MetaProposal.flatten(values ++ refs.toList))

  def isSingleValue: Boolean =
    values.tail.isEmpty

  def isMultiValue: Boolean =
    !isSingleValue

  def size: Int =
    values.size

  def addWeights(wf: Candidate => Double): MetaProposal =
    MetaProposal(proposalType, values.map(c => c.withWeight(wf(c))))

  def sortByWeight: MetaProposal =
    MetaProposal(proposalType, values.sortBy(_.weight)(Candidate.weightOrder))
}

object MetaProposal {

  def apply(pt: MetaProposalType, v0: Candidate, vm: Candidate*): MetaProposal =
    MetaProposal(pt, NonEmptyList.of(v0, vm: _*))

  def docDate(ts: Timestamp, origin: Option[NerLabel]): MetaProposal = {
    val label = ts.toUtcDate.toString
    MetaProposal(
      MetaProposalType.DocDate,
      Candidate(IdRef(Ident.unsafe(label), label), origin.toSet)
    )
  }

  def parseDate(cand: Candidate): Option[LocalDate] =
    parseDate(cand.ref.id)

  def parseDate(date: Ident): Option[LocalDate] =
    Either.catchNonFatal(LocalDate.parse(date.id)).toOption

  case class Candidate(ref: IdRef, origin: Set[NerLabel], weight: Option[Double] = None) {
    def withWeight(w: Double): Candidate =
      copy(weight = Some(w))
  }

  object Candidate {
    implicit val jsonEncoder: Encoder[Candidate] =
      deriveEncoder[Candidate]
    implicit val jsonDecoder: Decoder[Candidate] =
      deriveDecoder[Candidate]

    implicit val order: Order[Candidate] =
      Order.by(_.ref)

    /** This deviates from standard order to sort None at last.
      */
    val weightOrder: Order[Option[Double]] = new Order[Option[Double]] {
      def compare(x: Option[Double], y: Option[Double]) =
        (x, y) match {
          case (None, None)       => 0
          case (None, _)          => 1
          case (_, None)          => -1
          case (Some(x), Some(y)) => Order[Double].compare(x, y)
        }
    }
  }

  /** Merges candidates with same `IdRef` values and concatenates their respective labels.
    * The candidate order is preserved.
    */
  def flatten(s: NonEmptyList[Candidate]): NonEmptyList[Candidate] = {
    def mergeInto(
        res: NonEmptyList[Candidate],
        el: Candidate
    ): NonEmptyList[Candidate] = {
      val l = res.map(c =>
        if (c.ref.id == el.ref.id) c.copy(origin = c.origin ++ el.origin) else c
      )
      if (l == res) l :+ el
      else l
    }
    val init = NonEmptyList.of(s.head)
    s.tail.foldLeft(init)(mergeInto)
  }

  implicit val jsonDecoder: Decoder[MetaProposal] =
    deriveDecoder[MetaProposal]
  implicit val jsonEncoder: Encoder[MetaProposal] =
    deriveEncoder[MetaProposal]

}
