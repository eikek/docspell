package docspell.ftsclient

import docspell.common._

import FtsResult.ItemMatch

final case class FtsResult(
    qtime: Duration,
    count: Int,
    maxScore: Double,
    highlight: Map[Ident, List[String]],
    results: List[ItemMatch]
) {}

object FtsResult {

  sealed trait MatchData
  case class AttachmentData(attachId: Ident) extends MatchData
  case object ItemData                       extends MatchData

  case class ItemMatch(
      id: Ident,
      itemId: Ident,
      collectiveId: Ident,
      score: Double,
      data: MatchData
  )
}
