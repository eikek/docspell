package docspell.convert
import scodec.bits.ByteVector
import java.nio.charset.Charset

@FunctionalInterface
trait SanitizeHtml {

  /** The given `bytes' are html which can be modified to strip out
    * unwanted content.
    *
    * The result should use the same character encoding as the given
    * charset implies, or utf8 if not specified.
    */
  def apply(bytes: ByteVector, charset: Option[Charset]): ByteVector

}
