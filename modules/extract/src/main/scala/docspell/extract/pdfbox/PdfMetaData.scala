package docspell.extract.pdfbox

import docspell.common.Timestamp

final case class PdfMetaData(
    title: Option[String],
    author: Option[String],
    subject: Option[String],
    keywords: Option[String],
    creator: Option[String],
    creationDate: Option[Timestamp],
    pageCount: Int
) {

  def isEmpty: Boolean =
    title.isEmpty &&
      author.isEmpty &&
      subject.isEmpty &&
      keywords.isEmpty &&
      creator.isEmpty &&
      creationDate.isEmpty &&
      pageCount <= 0

  def nonEmpty: Boolean =
    !isEmpty

  def keywordList: List[String] =
    keywords.map(kws => kws.split("[,;]\\s*").toList).getOrElse(Nil)

  /** Return all data in lines, except keywords. Keywords are handled separately. */
  def asText: Option[String] =
    (title.toList ++ author.toList ++ subject.toList ++ creationDate.toList.map(
      _.toUtcDate.toString
    )) match {
      case Nil  => None
      case list => Some(list.mkString("\n"))
    }
}

object PdfMetaData {
  val empty = PdfMetaData(None, None, None, None, None, None, 0)
}
