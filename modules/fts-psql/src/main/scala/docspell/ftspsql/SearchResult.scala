package docspell.ftspsql

import docspell.common._
import docspell.ftsclient.FtsResult.{ItemMatch, MatchData}
import docspell.ftsclient.FtsResult

final case class SearchResult(
    id: Ident,
    itemId: Ident,
    collective: Ident,
    language: Language,
    attachId: Option[Ident],
    folderId: Option[Ident],
    attachName: Option[String],
    itemName: Option[String],
    rank: Double,
    highlight: Option[String]
)

object SearchResult {

  def toFtsResult(summary: SearchSummary, results: Vector[SearchResult]): FtsResult = {
    def mkEntry(r: SearchResult): (ItemMatch, (Ident, List[String])) = {
      def create(md: MatchData) = ItemMatch(r.id, r.itemId, r.collective, r.rank, md)

      val itemMatch =
        r.attachId match {
          case Some(aId) =>
            create(FtsResult.AttachmentData(aId, r.attachName.getOrElse("")))
          case None =>
            create(FtsResult.ItemData)
        }

      (itemMatch, r.id -> r.highlight.toList)
    }

    val (items, hl) = results.map(mkEntry).unzip

    FtsResult(
      Duration.zero,
      summary.count.toInt,
      summary.maxScore,
      hl.toMap,
      items.toList
    )
  }
}
