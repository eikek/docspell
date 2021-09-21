/*
 * Copyright 2020 Eike K. & Contributors
 *
 * SPDX-License-Identifier: AGPL-3.0-or-later
 */

package docspell.oidc

import java.security.spec.X509EncodedKeySpec
import java.security.{KeyFactory, PublicKey}
import javax.crypto.SecretKey
import javax.crypto.spec.SecretKeySpec

import cats.data.NonEmptyList
import cats.implicits._

import pdi.jwt.{JwtAlgorithm, JwtCirce}
import scodec.bits.ByteVector

sealed trait SignatureAlgo { self: Product =>

  def name: String =
    self.productPrefix
}

object SignatureAlgo {

  case object RS256 extends SignatureAlgo
  case object RS384 extends SignatureAlgo
  case object RS512 extends SignatureAlgo

  case object ES256   extends SignatureAlgo
  case object ES384   extends SignatureAlgo
  case object ES512   extends SignatureAlgo
  case object Ed25519 extends SignatureAlgo

  case object HMD5  extends SignatureAlgo
  case object HS224 extends SignatureAlgo
  case object HS256 extends SignatureAlgo
  case object HS384 extends SignatureAlgo
  case object HS512 extends SignatureAlgo

  val all: NonEmptyList[SignatureAlgo] =
    NonEmptyList.of(
      RS256,
      RS384,
      RS512,
      ES256,
      ES384,
      ES512,
      Ed25519,
      HMD5,
      HS224,
      HS256,
      HS384,
      HS512
    )

  def fromString(str: String): Either[String, SignatureAlgo] =
    str.toUpperCase() match {
      case "RS256"   => Right(RS256)
      case "RS384"   => Right(RS384)
      case "RS512"   => Right(RS512)
      case "ES256"   => Right(ES256)
      case "ES384"   => Right(ES384)
      case "ES512"   => Right(ES512)
      case "ED25519" => Right(Ed25519)
      case "HMD5"    => Right(HMD5)
      case "HS224"   => Right(HS224)
      case "HS256"   => Right(HS256)
      case "HS384"   => Right(HS384)
      case "HS512"   => Right(HS512)
      case _         => Left(s"Unknown signature algo: $str")
    }

  def unsafeFromString(str: String): SignatureAlgo =
    fromString(str).fold(sys.error, identity)

  private[oidc] def decoder(
      sigKey: ByteVector,
      algo: SignatureAlgo
  ): String => Either[Throwable, Jwt] = { token =>
    algo match {
      case RS256 =>
        for {
          pubKey <- createPublicKey(sigKey, "RSA")
          decoded <- JwtCirce
            .decodeJsonAll(token, pubKey, Seq(JwtAlgorithm.RS256))
            .toEither
        } yield Jwt.create(decoded)

      case RS384 =>
        for {
          pubKey <- createPublicKey(sigKey, "RSA")
          decoded <- JwtCirce
            .decodeJsonAll(token, pubKey, Seq(JwtAlgorithm.RS384))
            .toEither
        } yield Jwt.create(decoded)

      case RS512 =>
        for {
          pubKey <- createPublicKey(sigKey, "RSA")
          decoded <- JwtCirce
            .decodeJsonAll(token, pubKey, Seq(JwtAlgorithm.RS512))
            .toEither
        } yield Jwt.create(decoded)

      case ES256 =>
        for {
          pubKey <- createPublicKey(sigKey, "EC")
          decoded <- JwtCirce
            .decodeJsonAll(token, pubKey, Seq(JwtAlgorithm.ES256))
            .toEither
        } yield Jwt.create(decoded)
      case ES384 =>
        for {
          pubKey <- createPublicKey(sigKey, "EC")
          decoded <- JwtCirce
            .decodeJsonAll(token, pubKey, Seq(JwtAlgorithm.ES384))
            .toEither
        } yield Jwt.create(decoded)
      case ES512 =>
        for {
          pubKey <- createPublicKey(sigKey, "EC")
          decoded <- JwtCirce
            .decodeJsonAll(token, pubKey, Seq(JwtAlgorithm.ES512))
            .toEither
        } yield Jwt.create(decoded)

      case Ed25519 =>
        for {
          pubKey <- createPublicKey(sigKey, "EdDSA")
          decoded <- JwtCirce
            .decodeJsonAll(token, pubKey, Seq(JwtAlgorithm.Ed25519))
            .toEither
        } yield Jwt.create(decoded)

      case HMD5 =>
        for {
          key     <- createSecretKey(sigKey, JwtAlgorithm.HMD5.fullName)
          decoded <- JwtCirce.decodeJsonAll(token, key, Seq(JwtAlgorithm.HMD5)).toEither
        } yield Jwt.create(decoded)

      case HS224 =>
        for {
          key     <- createSecretKey(sigKey, JwtAlgorithm.HS224.fullName)
          decoded <- JwtCirce.decodeJsonAll(token, key, Seq(JwtAlgorithm.HS224)).toEither
        } yield Jwt.create(decoded)

      case HS256 =>
        for {
          key     <- createSecretKey(sigKey, JwtAlgorithm.HS256.fullName)
          decoded <- JwtCirce.decodeJsonAll(token, key, Seq(JwtAlgorithm.HS256)).toEither
        } yield Jwt.create(decoded)

      case HS384 =>
        for {
          key     <- createSecretKey(sigKey, JwtAlgorithm.HS384.fullName)
          decoded <- JwtCirce.decodeJsonAll(token, key, Seq(JwtAlgorithm.HS384)).toEither
        } yield Jwt.create(decoded)

      case HS512 =>
        for {
          key     <- createSecretKey(sigKey, JwtAlgorithm.HS512.fullName)
          decoded <- JwtCirce.decodeJsonAll(token, key, Seq(JwtAlgorithm.HS512)).toEither
        } yield Jwt.create(decoded)
    }
  }

  private def createSecretKey(
      key: ByteVector,
      keyAlgo: String
  ): Either[Throwable, SecretKey] =
    Either.catchNonFatal(new SecretKeySpec(key.toArray, keyAlgo))

  private def createPublicKey(
      key: ByteVector,
      keyAlgo: String
  ): Either[Throwable, PublicKey] =
    Either.catchNonFatal {
      val spec = new X509EncodedKeySpec(key.toArray)
      KeyFactory.getInstance(keyAlgo).generatePublic(spec)
    }

}
