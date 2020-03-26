package docspell.backend.auth

import cats.effect._
import cats.implicits._
import java.time.Instant

import javax.crypto.Mac
import javax.crypto.spec.SecretKeySpec
import scodec.bits.ByteVector

import docspell.backend.Common
import AuthToken._
import docspell.common._

case class AuthToken(millis: Long, account: AccountId, salt: String, sig: String) {
  def asString = s"$millis-${b64enc(account.asString)}-$salt-$sig"

  def sigValid(key: ByteVector): Boolean = {
    val newSig = AuthToken.sign(this, key)
    AuthToken.constTimeEq(sig, newSig)
  }
  def sigInvalid(key: ByteVector): Boolean =
    !sigValid(key)

  def notExpired(validity: Duration): Boolean =
    !isExpired(validity)

  def isExpired(validity: Duration): Boolean = {
    val ends = Instant.ofEpochMilli(millis).plusMillis(validity.millis)
    Instant.now.isAfter(ends)
  }

  def validate(key: ByteVector, validity: Duration): Boolean =
    sigValid(key) && notExpired(validity)
}

object AuthToken {
  private val utf8 = java.nio.charset.StandardCharsets.UTF_8

  def fromString(s: String): Either[String, AuthToken] =
    s.split("\\-", 4) match {
      case Array(ms, as, salt, sig) =>
        for {
          millis <- asInt(ms).toRight("Cannot read authenticator data")
          acc    <- b64dec(as).toRight("Cannot read authenticator data")
          accId  <- AccountId.parse(acc)
        } yield AuthToken(millis, accId, salt, sig)

      case _ =>
        Left("Invalid authenticator")
    }

  def user[F[_]: Sync](accountId: AccountId, key: ByteVector): F[AuthToken] =
    for {
      salt <- Common.genSaltString[F]
      millis = Instant.now.toEpochMilli
      cd     = AuthToken(millis, accountId, salt, "")
      sig    = sign(cd, key)
    } yield cd.copy(sig = sig)

  private def sign(cd: AuthToken, key: ByteVector): String = {
    val raw = cd.millis.toString + cd.account.asString + cd.salt
    val mac = Mac.getInstance("HmacSHA1")
    mac.init(new SecretKeySpec(key.toArray, "HmacSHA1"))
    ByteVector.view(mac.doFinal(raw.getBytes(utf8))).toBase64
  }

  private def b64enc(s: String): String =
    ByteVector.view(s.getBytes(utf8)).toBase64

  private def b64dec(s: String): Option[String] =
    ByteVector.fromValidBase64(s).decodeUtf8.toOption

  private def asInt(s: String): Option[Long] =
    Either.catchNonFatal(s.toLong).toOption

  private def constTimeEq(s1: String, s2: String): Boolean =
    s1.zip(s2)
      .foldLeft(true)({ case (r, (c1, c2)) => r & c1 == c2 }) & s1.length == s2.length

}
