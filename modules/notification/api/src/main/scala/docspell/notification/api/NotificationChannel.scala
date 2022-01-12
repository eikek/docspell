/*
 * Copyright 2020 Eike K. & Contributors
 *
 * SPDX-License-Identifier: AGPL-3.0-or-later
 */

package docspell.notification.api

import cats.data.NonEmptyList

import docspell.common._

import emil._

sealed trait NotificationChannel { self: Product =>
  def name: String =
    productPrefix.toLowerCase
}

object NotificationChannel {

  final case class Email(
      config: MailConfig,
      from: MailAddress,
      recipients: NonEmptyList[MailAddress]
  ) extends NotificationChannel

  final case class HttpPost(
      url: LenientUri,
      headers: Map[String, String]
  ) extends NotificationChannel

  final case class Gotify(url: LenientUri, appKey: Password, priority: Option[Int])
      extends NotificationChannel

  final case class Matrix(
      homeServer: LenientUri,
      roomId: String,
      accessToken: Password,
      messageType: String
  ) extends NotificationChannel
}
