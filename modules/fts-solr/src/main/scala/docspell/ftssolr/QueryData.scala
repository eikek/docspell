package docspell.ftssolr

import io.circe._
import io.circe.generic.semiauto._
import docspell.ftsclient.FtsQuery

final case class QueryData(
    query: String,
    filter: String,
    limit: Int,
    offset: Int,
    fields: List[Field],
    params: Map[String, String]
) {

  def nextPage: QueryData =
    copy(offset = offset + limit)

  def withHighLight(fields: List[Field], pre: String, post: String): QueryData =
    copy(params =
      params ++ Map(
        "hl"                   -> "on",
        "hl.requireFieldMatch" -> "true",
        "hl.fl"                -> fields.map(_.name).mkString(","),
        "hl.simple.pre"        -> pre,
        "hl.simple.post"       -> post
      )
    )
}

object QueryData {

  implicit val jsonEncoder: Encoder[QueryData] =
    deriveEncoder[QueryData]

  def apply(search: List[Field], fields: List[Field], fq: FtsQuery): QueryData = {
    val q     = sanitize(fq.q)
    val extQ  = search.map(f => s"${f.name}:($q)").mkString(" OR ")
    val items = fq.items.map(_.id).mkString(" ")
    val collQ = s"""${Field.collectiveId.name}:"${fq.collective.id}""""
    val filterQ = fq.items match {
      case Nil =>
        collQ
      case _ =>
        (collQ :: List(s"""${Field.itemId.name}:($items)""")).mkString(" AND ")
    }
    QueryData(extQ, filterQ, fq.limit, fq.offset, fields, Map.empty).withHighLight(
      search,
      "**",
      "**"
    )
  }

  private def sanitize(q: String): String =
    q.replaceAll("[\\(,\\)]+", " ")
}
