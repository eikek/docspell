package docspell.store

import cats.implicits._
import emil._
import emil.javamail.syntax._

object EmilUtil {

  def readSSLType(str: String): Either[String, SSLType] =
    str.toLowerCase match {
      case "ssl"      => Right(SSLType.SSL)
      case "starttls" => Right(SSLType.StartTLS)
      case "none"     => Right(SSLType.NoEncryption)
      case _          => Left(s"Invalid ssl-type: $str")
    }

  def unsafeReadSSLType(str: String): SSLType =
    readSSLType(str).fold(sys.error, identity)

  def sslTypeString(st: SSLType): String =
    st match {
      case SSLType.SSL          => "ssl"
      case SSLType.StartTLS     => "starttls"
      case SSLType.NoEncryption => "none"
    }

  def readMailAddress(str: String): Either[String, MailAddress] =
    MailAddress.parse(str)

  def unsafeReadMailAddress(str: String): MailAddress =
    readMailAddress(str).fold(sys.error, identity)

  def readMultipleAddresses(str: String): Either[String, List[MailAddress]] =
    str.split(',').toList.map(_.trim).traverse(readMailAddress)

  def mailAddressString(ma: MailAddress): String =
    ma.asUnicodeString
}
