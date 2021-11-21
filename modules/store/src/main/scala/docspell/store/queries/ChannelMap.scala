/*
 * Copyright 2020 Eike K. & Contributors
 *
 * SPDX-License-Identifier: AGPL-3.0-or-later
 */

package docspell.store.queries

import cats.data.{NonEmptyList, OptionT}
import cats.effect._

import docspell.notification.api.NotificationChannel
import docspell.store.records._

import doobie.ConnectionIO

object ChannelMap {

  def readMail(r: RNotificationChannelMail): ConnectionIO[Vector[NotificationChannel]] =
    (for {
      em <- OptionT(RUserEmail.getById(r.connection))
      rec <- OptionT.fromOption[ConnectionIO](NonEmptyList.fromList(r.recipients))
      ch = NotificationChannel.Email(em.toMailConfig, em.mailFrom, rec)
    } yield Vector(ch)).getOrElse(Vector.empty)

  def readGotify(
      r: RNotificationChannelGotify
  ): ConnectionIO[Vector[NotificationChannel]] =
    pure(NotificationChannel.Gotify(r.url, r.appKey))

  def readMatrix(
      r: RNotificationChannelMatrix
  ): ConnectionIO[Vector[NotificationChannel]] =
    pure(NotificationChannel.Matrix(r.homeServer, r.roomId, r.accessToken, r.messageType))

  def readHttp(
      r: RNotificationChannelHttp
  ): ConnectionIO[Vector[NotificationChannel]] =
    pure(NotificationChannel.HttpPost(r.url, Map.empty))

  private def pure[A](a: A): ConnectionIO[Vector[A]] =
    Sync[ConnectionIO].pure(Vector(a))

}
