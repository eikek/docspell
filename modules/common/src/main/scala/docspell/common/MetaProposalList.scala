package docspell.common

import cats.data.NonEmptyList
import cats.kernel.Monoid

import docspell.common.MetaProposal.Candidate

import io.circe._
import io.circe.generic.semiauto._

/** A list of proposals for meta data to an item.
  *
  * The list usually keeps only one value for each `MetaProposalType'.
  */
case class MetaProposalList private (proposals: List[MetaProposal]) {

  def isEmpty: Boolean  = proposals.isEmpty
  def nonEmpty: Boolean = proposals.nonEmpty

  def hasResults(mt: MetaProposalType, mts: MetaProposalType*): Boolean =
    (mts :+ mt).map(mtp => proposals.exists(_.proposalType == mtp)).reduce(_ && _)

  def hasResultsAll: Boolean =
    proposals.map(_.proposalType).toSet == MetaProposalType.all.toSet

  def getTypes: Set[MetaProposalType] =
    proposals.foldLeft(Set.empty[MetaProposalType])(_ + _.proposalType)

  def fillEmptyFrom(ml: MetaProposalList): MetaProposalList = {
    val list = ml.proposals.foldLeft(proposals) { (mine, mp) =>
      if (hasResults(mp.proposalType)) mine
      else mp :: mine
    }
    new MetaProposalList(list)
  }

  def find(mpt: MetaProposalType): Option[MetaProposal] =
    proposals.find(_.proposalType == mpt)

  def change(f: MetaProposal => MetaProposal): MetaProposalList =
    new MetaProposalList(proposals.map(f))

  def filter(f: MetaProposal => Boolean): MetaProposalList =
    new MetaProposalList(proposals.filter(f))

  def sortByWeights: MetaProposalList =
    change(_.sortByWeight)
}

object MetaProposalList {
  val empty = MetaProposalList(Nil)

  def apply(lmp: List[MetaProposal]): MetaProposalList =
    flatten(lmp.map(m => new MetaProposalList(List(m))))

  def of(mps: MetaProposal*): MetaProposalList =
    flatten(mps.toList.map(mp => MetaProposalList(List(mp))))

  def from(mt: MetaProposalType, label: NerLabel)(refs: Seq[IdRef]): MetaProposalList =
    fromSeq1(mt, refs.map(ref => Candidate(ref, Set(label))))

  def fromSeq1(mt: MetaProposalType, refs: Seq[Candidate]): MetaProposalList =
    NonEmptyList
      .fromList(refs.toList)
      .map(nl => MetaProposalList.of(MetaProposal(mt, nl)))
      .getOrElse(empty)

  def fromMap(m: Map[MetaProposalType, MetaProposal]): MetaProposalList =
    new MetaProposalList(m.toList.map({ case (k, v) => v.copy(proposalType = k) }))

  /** Flattens the given list of meta-proposals into a single list,
    * where each meta-proposal type exists at most once. Candidates to
    * equal proposal-types are merged together. The candidate's order
    * is preserved and candidates of proposals are appended as given
    * by the order of the given `seq'.
    */
  def flatten(ml: Seq[MetaProposalList]): MetaProposalList = {
    val init: Map[MetaProposalType, MetaProposal] = Map.empty

    def updateMap(
        map: Map[MetaProposalType, MetaProposal],
        mp: MetaProposal
    ): Map[MetaProposalType, MetaProposal] =
      map.get(mp.proposalType) match {
        case Some(mp0) => map.updated(mp.proposalType, mp0.addIdRef(mp.values.toList))
        case None      => map.updated(mp.proposalType, mp)
      }

    val merged = ml.foldLeft(init)((map, el) => el.proposals.foldLeft(map)(updateMap))

    fromMap(merged)
  }

  implicit val jsonEncoder: Encoder[MetaProposalList] =
    deriveEncoder[MetaProposalList]
  implicit val jsonDecoder: Decoder[MetaProposalList] =
    deriveDecoder[MetaProposalList]

  implicit val metaProposalListMonoid: Monoid[MetaProposalList] =
    Monoid.instance(empty, (m0, m1) => flatten(Seq(m0, m1)))
}
