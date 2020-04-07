package docspell.joex.extract

import org.jsoup.Jsoup
import org.jsoup.nodes._
import emil.jsoup._
import scodec.bits.ByteVector
import java.io.ByteArrayInputStream
import java.nio.charset.{Charset, StandardCharsets}

object JsoupSanitizer {

  //BIG NOTE: this changes the input document
  def apply(doc: Document): Document =
    BodyClean.whitelistClean(EmailWhitelist.default)(doc)

  def clean(html: String): String = {
    //note: Jsoup.clean throws away the html head, which removes the
    //charset if present
    val doc = Jsoup.parse(html)
    apply(doc).outerHtml
  }

  def clean(html: ByteVector, cs: Option[Charset]): ByteVector = {
    val in  = new ByteArrayInputStream(html.toArray)
    val doc = Jsoup.parse(in, cs.map(_.name).orNull, "")
    ByteVector.view(apply(doc).outerHtml.getBytes(cs.getOrElse(StandardCharsets.UTF_8)))
  }

}
