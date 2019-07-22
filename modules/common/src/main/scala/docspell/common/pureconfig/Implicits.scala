package docspell.common.pureconfig

import docspell.common._
import _root_.pureconfig._
import _root_.pureconfig.error.{CannotConvert, FailureReason}
import scodec.bits.ByteVector

import scala.reflect.ClassTag

object Implicits {
  implicit val lenientUriReader: ConfigReader[LenientUri] =
    ConfigReader[String].emap(reason(LenientUri.parse))

  implicit val durationReader: ConfigReader[Duration] =
    ConfigReader[scala.concurrent.duration.Duration].map(sd => Duration(sd))

  implicit val passwordReader: ConfigReader[Password] =
    ConfigReader[String].map(Password(_))

  implicit val mimeTypeReader: ConfigReader[MimeType] =
    ConfigReader[String].emap(reason(MimeType.parse))

  implicit val identReader: ConfigReader[Ident] =
    ConfigReader[String].emap(reason(Ident.fromString))

  implicit val byteVectorReader: ConfigReader[ByteVector] =
    ConfigReader[String].emap(reason(str => {
      if (str.startsWith("hex:")) ByteVector.fromHex(str.drop(4)).toRight("Invalid hex value.")
      else if (str.startsWith("b64:")) ByteVector.fromBase64(str.drop(4)).toRight("Invalid Base64 string.")
      else ByteVector.fromHex(str).toRight("Invalid hex value.")
    }))

  def reason[A: ClassTag](f: String => Either[String, A]): String => Either[FailureReason, A] =
    in => f(in).left.map(str => CannotConvert(in, implicitly[ClassTag[A]].runtimeClass.toString, str))
}