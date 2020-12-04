package docspell.backend.auth

import javax.crypto.Mac
import javax.crypto.spec.SecretKeySpec

import cats.implicits._

import scodec.bits._

private[auth] object TokenUtil {
  private val utf8 = java.nio.charset.StandardCharsets.UTF_8

  def sign(cd: RememberToken, key: ByteVector): String = {
    val raw = cd.nowMillis.toString + cd.rememberId.id + cd.salt
    val mac = Mac.getInstance("HmacSHA1")
    mac.init(new SecretKeySpec(key.toArray, "HmacSHA1"))
    ByteVector.view(mac.doFinal(raw.getBytes(utf8))).toBase64
  }

  def sign(cd: AuthToken, key: ByteVector): String = {
    val raw = cd.nowMillis.toString + cd.account.asString + cd.salt
    val mac = Mac.getInstance("HmacSHA1")
    mac.init(new SecretKeySpec(key.toArray, "HmacSHA1"))
    ByteVector.view(mac.doFinal(raw.getBytes(utf8))).toBase64
  }

  def b64enc(s: String): String =
    ByteVector.view(s.getBytes(utf8)).toBase64

  def b64dec(s: String): Option[String] =
    ByteVector.fromBase64(s).flatMap(_.decodeUtf8.toOption)

  def asInt(s: String): Option[Long] =
    Either.catchNonFatal(s.toLong).toOption

  def constTimeEq(s1: String, s2: String): Boolean =
    s1.zip(s2)
      .foldLeft(true)({ case (r, (c1, c2)) => r & c1 == c2 }) & s1.length == s2.length

}
