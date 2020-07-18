package docspell.extract.pdfbox

import docspell.common.Timestamp

final case class PdfMetaData(
    title: Option[String],
    author: Option[String],
    subject: Option[String],
    keywords: Option[String],
    creator: Option[String],
    creationDate: Option[Timestamp]
) {

  def isEmpty: Boolean =
    title.isEmpty &&
      author.isEmpty &&
      subject.isEmpty &&
      keywords.isEmpty &&
      creator.isEmpty &&
      creationDate.isEmpty

  def nonEmpty: Boolean =
    !isEmpty

  def keywordList: List[String] =
    keywords.map(kws => kws.split("[,;]\\s*").toList).getOrElse(Nil)
}

object PdfMetaData {
  val empty = PdfMetaData(None, None, None, None, None, None)
}
