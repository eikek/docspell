package docspell.extract.poi

import docspell.common.MimeType

object PoiTypes {

  val msoffice = MimeType.application("x-tika-msoffice")
  val ooxml = MimeType.application("x-tika-ooxml")
  val docx = MimeType.application("vnd.openxmlformats-officedocument.wordprocessingml.document")
  val xlsx = MimeType.application("vnd.openxmlformats-officedocument.spreadsheetml.sheet")
  val xls = MimeType.application("vnd.ms-excel")
  val doc = MimeType.application("msword")

  val all = Set(msoffice, ooxml, docx, xlsx, xls, doc)

}
