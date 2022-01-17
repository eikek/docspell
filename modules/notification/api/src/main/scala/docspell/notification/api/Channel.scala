/*
 * Copyright 2020 Eike K. & Contributors
 *
 * SPDX-License-Identifier: AGPL-3.0-or-later
 */

package docspell.notification.api

import cats.data.{NonEmptyList => Nel}

import docspell.common._

import emil.MailAddress
import io.circe.generic.extras.Configuration
import io.circe.generic.extras.semiauto.{deriveConfiguredDecoder, deriveConfiguredEncoder}
import io.circe.{Decoder, Encoder}

/** A type for representing channels as stored in the database. */
sealed trait Channel {
  def id: Ident
  def channelType: ChannelType
  def fold[A](
      f1: Channel.Mail => A,
      f2: Channel.Gotify => A,
      f3: Channel.Matrix => A,
      f4: Channel.Http => A
  ): A
  def asRef: ChannelRef = ChannelRef(id, channelType)
}

object Channel {
  implicit val jsonConfig = Configuration.default.withDiscriminator("channelType")

  final case class Mail(
      id: Ident,
      name: Option[String],
      connection: Ident,
      recipients: Nel[MailAddress]
  ) extends Channel {
    val channelType = ChannelType.Mail
    def fold[A](
        f1: Mail => A,
        f2: Gotify => A,
        f3: Matrix => A,
        f4: Http => A
    ): A = f1(this)
  }

  object Mail {
    implicit def jsonDecoder(implicit D: Decoder[MailAddress]): Decoder[Mail] =
      deriveConfiguredDecoder[Mail]

    implicit def jsonEncoder(implicit E: Encoder[MailAddress]): Encoder[Mail] =
      deriveConfiguredEncoder[Mail]
  }

  final case class Gotify(
      id: Ident,
      name: Option[String],
      url: LenientUri,
      appKey: Password,
      priority: Option[Int]
  ) extends Channel {
    val channelType = ChannelType.Gotify
    def fold[A](
        f1: Mail => A,
        f2: Gotify => A,
        f3: Matrix => A,
        f4: Http => A
    ): A = f2(this)
  }

  object Gotify {
    implicit val jsonDecoder: Decoder[Gotify] =
      deriveConfiguredDecoder
    implicit val jsonEncoder: Encoder[Gotify] =
      deriveConfiguredEncoder
  }

  final case class Matrix(
      id: Ident,
      name: Option[String],
      homeServer: LenientUri,
      roomId: String,
      accessToken: Password
  ) extends Channel {
    val channelType = ChannelType.Matrix
    def fold[A](
        f1: Mail => A,
        f2: Gotify => A,
        f3: Matrix => A,
        f4: Http => A
    ): A = f3(this)
  }

  object Matrix {
    implicit val jsonDecoder: Decoder[Matrix] = deriveConfiguredDecoder
    implicit val jsonEncoder: Encoder[Matrix] = deriveConfiguredEncoder
  }

  final case class Http(id: Ident, name: Option[String], url: LenientUri) extends Channel {
    val channelType = ChannelType.Http
    def fold[A](
        f1: Mail => A,
        f2: Gotify => A,
        f3: Matrix => A,
        f4: Http => A
    ): A = f4(this)
  }

  object Http {
    implicit val jsonDecoder: Decoder[Http] = deriveConfiguredDecoder
    implicit val jsonEncoder: Encoder[Http] = deriveConfiguredEncoder
  }

  implicit def jsonDecoder(implicit mc: Decoder[MailAddress]): Decoder[Channel] =
    deriveConfiguredDecoder
  implicit def jsonEncoder(implicit mc: Encoder[MailAddress]): Encoder[Channel] =
    deriveConfiguredEncoder
}
