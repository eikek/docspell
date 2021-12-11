/*
 * Copyright 2020 Eike K. & Contributors
 *
 * SPDX-License-Identifier: AGPL-3.0-or-later
 */

package docspell.restapi.model

import cats.data.NonEmptyList
import cats.implicits._

import docspell.notification.api.Channel
import docspell.notification.api.ChannelType
import docspell.restapi.model._

import emil.MailAddress
import emil.javamail.syntax._
import io.circe.{Decoder, Encoder}

sealed trait NotificationChannel {
  def fold[A](
      f1: NotificationMail => A,
      f2: NotificationGotify => A,
      f3: NotificationMatrix => A,
      f4: NotificationHttp => A
  ): A
}

object NotificationChannel {
  final case class Mail(c: NotificationMail) extends NotificationChannel {
    def fold[A](
        f1: NotificationMail => A,
        f2: NotificationGotify => A,
        f3: NotificationMatrix => A,
        f4: NotificationHttp => A
    ): A = f1(c)
  }
  final case class Gotify(c: NotificationGotify) extends NotificationChannel {
    def fold[A](
        f1: NotificationMail => A,
        f2: NotificationGotify => A,
        f3: NotificationMatrix => A,
        f4: NotificationHttp => A
    ): A = f2(c)
  }
  final case class Matrix(c: NotificationMatrix) extends NotificationChannel {
    def fold[A](
        f1: NotificationMail => A,
        f2: NotificationGotify => A,
        f3: NotificationMatrix => A,
        f4: NotificationHttp => A
    ): A = f3(c)
  }
  final case class Http(c: NotificationHttp) extends NotificationChannel {
    def fold[A](
        f1: NotificationMail => A,
        f2: NotificationGotify => A,
        f3: NotificationMatrix => A,
        f4: NotificationHttp => A
    ): A = f4(c)
  }

  def mail(c: NotificationMail): NotificationChannel = Mail(c)
  def gotify(c: NotificationGotify): NotificationChannel = Gotify(c)
  def matrix(c: NotificationMatrix): NotificationChannel = Matrix(c)
  def http(c: NotificationHttp): NotificationChannel = Http(c)

  def convert(c: NotificationChannel): Either[Throwable, Channel] =
    c.fold(
      mail =>
        mail.recipients
          .traverse(MailAddress.parse)
          .map(NonEmptyList.fromList)
          .flatMap(_.toRight("No recipients given!"))
          .leftMap(new IllegalArgumentException(_))
          .map(rec => Channel.Mail(mail.id, mail.connection, rec)),
      gotify => Right(Channel.Gotify(gotify.id, gotify.url, gotify.appKey)),
      matrix =>
        Right(
          Channel
            .Matrix(matrix.id, matrix.homeServer, matrix.roomId, matrix.accessToken)
        ),
      http => Right(Channel.Http(http.id, http.url))
    )

  def convert(c: Channel): NotificationChannel =
    c.fold(
      m =>
        mail {
          NotificationMail(
            m.id,
            ChannelType.Mail,
            m.connection,
            m.recipients.toList.map(_.displayString)
          )
        },
      g => gotify(NotificationGotify(g.id, ChannelType.Gotify, g.url, g.appKey)),
      m =>
        matrix(
          NotificationMatrix(
            m.id,
            ChannelType.Matrix,
            m.homeServer,
            m.roomId,
            m.accessToken
          )
        ),
      h => http(NotificationHttp(h.id, ChannelType.Http, h.url))
    )

  implicit val jsonDecoder: Decoder[NotificationChannel] =
    ChannelType.jsonDecoder.at("channelType").flatMap {
      case ChannelType.Mail   => Decoder[NotificationMail].map(mail)
      case ChannelType.Gotify => Decoder[NotificationGotify].map(gotify)
      case ChannelType.Matrix => Decoder[NotificationMatrix].map(matrix)
      case ChannelType.Http   => Decoder[NotificationHttp].map(http)
    }

  implicit val jsonEncoder: Encoder[NotificationChannel] =
    Encoder.instance {
      case NotificationChannel.Mail(c) =>
        Encoder[NotificationMail].apply(c)
      case NotificationChannel.Gotify(c) =>
        Encoder[NotificationGotify].apply(c)
      case NotificationChannel.Matrix(c) =>
        Encoder[NotificationMatrix].apply(c)
      case NotificationChannel.Http(c) =>
        Encoder[NotificationHttp].apply(c)
    }
}
