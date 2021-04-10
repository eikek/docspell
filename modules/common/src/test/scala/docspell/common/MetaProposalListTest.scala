package docspell.common

import cats.data.NonEmptyList

import docspell.common.MetaProposal.Candidate

import munit._

class MetaProposalListTest extends FunSuite {

  test("flatten retains order of candidates") {
    val cand1 = Candidate(IdRef(Ident.unsafe("123"), "name"), Set.empty)
    val mpl1 = MetaProposalList.of(
      MetaProposal(
        MetaProposalType.CorrOrg,
        NonEmptyList.of(cand1)
      )
    )
    val cand2 = Candidate(IdRef(Ident.unsafe("456"), "name"), Set.empty)
    val mpl2 = MetaProposalList.of(
      MetaProposal(
        MetaProposalType.CorrOrg,
        NonEmptyList.of(cand2)
      )
    )

    val candidates1 = MetaProposalList
      .flatten(Seq(mpl1, mpl2))
      .find(MetaProposalType.CorrOrg)
      .get
      .values
    assertEquals(candidates1.head, cand1)
    assertEquals(candidates1.tail.head, cand2)

    val candidates2 = MetaProposalList
      .flatten(Seq(mpl2, mpl1))
      .find(MetaProposalType.CorrOrg)
      .get
      .values
    assertEquals(candidates2.head, cand2)
    assertEquals(candidates2.tail.head, cand1)
  }

  test("sort by weights") {
    val cand1 = Candidate(IdRef(Ident.unsafe("123"), "name"), Set.empty, Some(0.1))
    val cand2 = Candidate(IdRef(Ident.unsafe("456"), "name"), Set.empty, Some(0.05))
    val mpl = MetaProposalList
      .of(
        MetaProposal(MetaProposalType.CorrOrg, NonEmptyList.of(cand1)),
        MetaProposal(MetaProposalType.CorrOrg, NonEmptyList.of(cand2))
      )
      .sortByWeights

    val candidates = mpl.find(MetaProposalType.CorrOrg).get.values
    assertEquals(candidates.head, cand2)
    assertEquals(candidates.tail.head, cand1)
  }

  test("sort by weights: unset is last") {
    val cand1 = Candidate(IdRef(Ident.unsafe("123"), "name"), Set.empty, Some(0.1))
    val cand2 = Candidate(IdRef(Ident.unsafe("456"), "name"), Set.empty)
    val mpl = MetaProposalList
      .of(
        MetaProposal(MetaProposalType.CorrOrg, NonEmptyList.of(cand1)),
        MetaProposal(MetaProposalType.CorrOrg, NonEmptyList.of(cand2))
      )
      .sortByWeights

    val candidates = mpl.find(MetaProposalType.CorrOrg).get.values
    assertEquals(candidates.head, cand1)
    assertEquals(candidates.tail.head, cand2)
  }

  test("insert second") {
    val cand1 = Candidate(IdRef(Ident.unsafe("123"), "name"), Set.empty)
    val cand2 = Candidate(IdRef(Ident.unsafe("456"), "name"), Set.empty)
    val cand3 = Candidate(IdRef(Ident.unsafe("789"), "name"), Set.empty)
    val cand4 = Candidate(IdRef(Ident.unsafe("abc"), "name"), Set.empty)
    val cand5 = Candidate(IdRef(Ident.unsafe("def"), "name"), Set.empty)

    val mpl1 = MetaProposalList
      .of(
        MetaProposal(MetaProposalType.CorrOrg, NonEmptyList.of(cand1, cand2)),
        MetaProposal(MetaProposalType.ConcPerson, NonEmptyList.of(cand3))
      )

    val mpl2 = MetaProposalList
      .of(
        MetaProposal(MetaProposalType.CorrOrg, NonEmptyList.of(cand4)),
        MetaProposal(MetaProposalType.ConcPerson, NonEmptyList.of(cand5))
      )

    val result = mpl1.insertSecond(mpl2)
    assertEquals(
      result,
      MetaProposalList(
        List(
          MetaProposal(MetaProposalType.CorrOrg, NonEmptyList.of(cand1, cand4, cand2)),
          MetaProposal(MetaProposalType.ConcPerson, NonEmptyList.of(cand3, cand5))
        )
      )
    )
  }

  test("insert second, remove duplicates") {
    val cand1 = Candidate(IdRef(Ident.unsafe("123"), "name"), Set.empty)
    val cand2 = Candidate(IdRef(Ident.unsafe("456"), "name"), Set.empty)
    val cand3 = Candidate(IdRef(Ident.unsafe("789"), "name"), Set.empty)
    val cand5 = Candidate(IdRef(Ident.unsafe("def"), "name"), Set.empty)

    val mpl1 = MetaProposalList
      .of(
        MetaProposal(MetaProposalType.CorrOrg, NonEmptyList.of(cand1, cand2)),
        MetaProposal(MetaProposalType.ConcPerson, NonEmptyList.of(cand3))
      )

    val mpl2 = MetaProposalList
      .of(
        MetaProposal(MetaProposalType.CorrOrg, NonEmptyList.of(cand1)),
        MetaProposal(MetaProposalType.ConcPerson, NonEmptyList.of(cand5))
      )

    val result = mpl1.insertSecond(mpl2)
    assertEquals(
      result,
      MetaProposalList(
        List(
          MetaProposal(MetaProposalType.CorrOrg, NonEmptyList.of(cand1, cand2)),
          MetaProposal(MetaProposalType.ConcPerson, NonEmptyList.of(cand3, cand5))
        )
      )
    )
  }
}
