package docspell.joex.extract

import emil.BodyContent
import emil.jsoup._
import scodec.bits.ByteVector
import java.nio.charset.Charset

object JsoupSanitizer {

  private val change =
    BodyClean.whitelistClean(EmailWhitelist.default)

  def clean(html: String): String =
    BodyClean.modifyContent(change)(BodyContent(html)).asString

  def clean(html: ByteVector, cs: Option[Charset]): ByteVector =
    BodyClean.modifyContent(change)(BodyContent(html, cs)).bytes
}
