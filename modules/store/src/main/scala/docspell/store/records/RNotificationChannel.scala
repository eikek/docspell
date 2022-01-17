/*
 * Copyright 2020 Eike K. & Contributors
 *
 * SPDX-License-Identifier: AGPL-3.0-or-later
 */

package docspell.store.records

import cats.data.OptionT

import docspell.common._
import docspell.notification.api.ChannelRef
import docspell.notification.api.ChannelType

import doobie._

sealed trait RNotificationChannel {

  def id: Ident = fold(_.id, _.id, _.id, _.id)

  def name: Option[String] = fold(_.name, _.name, _.name, _.name)

  def fold[A](
      f1: RNotificationChannelMail => A,
      f2: RNotificationChannelGotify => A,
      f3: RNotificationChannelMatrix => A,
      f4: RNotificationChannelHttp => A
  ): A
}

object RNotificationChannel {

  final case class Email(r: RNotificationChannelMail) extends RNotificationChannel {

    override def fold[A](
        f1: RNotificationChannelMail => A,
        f2: RNotificationChannelGotify => A,
        f3: RNotificationChannelMatrix => A,
        f4: RNotificationChannelHttp => A
    ): A = f1(r)
  }

  final case class Gotify(r: RNotificationChannelGotify) extends RNotificationChannel {
    override def fold[A](
        f1: RNotificationChannelMail => A,
        f2: RNotificationChannelGotify => A,
        f3: RNotificationChannelMatrix => A,
        f4: RNotificationChannelHttp => A
    ): A = f2(r)
  }

  final case class Matrix(r: RNotificationChannelMatrix) extends RNotificationChannel {
    override def fold[A](
        f1: RNotificationChannelMail => A,
        f2: RNotificationChannelGotify => A,
        f3: RNotificationChannelMatrix => A,
        f4: RNotificationChannelHttp => A
    ): A = f3(r)
  }

  final case class Http(r: RNotificationChannelHttp) extends RNotificationChannel {
    override def fold[A](
        f1: RNotificationChannelMail => A,
        f2: RNotificationChannelGotify => A,
        f3: RNotificationChannelMatrix => A,
        f4: RNotificationChannelHttp => A
    ): A = f4(r)
  }

  def insert(r: RNotificationChannel): ConnectionIO[Int] =
    r.fold(
      RNotificationChannelMail.insert,
      RNotificationChannelGotify.insert,
      RNotificationChannelMatrix.insert,
      RNotificationChannelHttp.insert
    )

  def update(r: RNotificationChannel): ConnectionIO[Int] =
    r.fold(
      RNotificationChannelMail.update,
      RNotificationChannelGotify.update,
      RNotificationChannelMatrix.update,
      RNotificationChannelHttp.update
    )

  def getByAccount(account: AccountId): ConnectionIO[Vector[RNotificationChannel]] =
    for {
      mail <- RNotificationChannelMail.getByAccount(account)
      gotify <- RNotificationChannelGotify.getByAccount(account)
      matrix <- RNotificationChannelMatrix.getByAccount(account)
      http <- RNotificationChannelHttp.getByAccount(account)
    } yield mail.map(Email.apply) ++ gotify.map(Gotify.apply) ++ matrix.map(
      Matrix.apply
    ) ++ http.map(Http.apply)

  def getById(id: Ident): ConnectionIO[Vector[RNotificationChannel]] =
    for {
      mail <- RNotificationChannelMail.getById(id)
      gotify <- RNotificationChannelGotify.getById(id)
      matrix <- RNotificationChannelMatrix.getById(id)
      http <- RNotificationChannelHttp.getById(id)
    } yield mail.map(Email.apply).toVector ++
      gotify.map(Gotify.apply).toVector ++
      matrix.map(Matrix.apply).toVector ++
      http.map(Http.apply).toVector

  def getByRef(ref: ChannelRef): ConnectionIO[Option[RNotificationChannel]] =
    ref.channelType match {
      case ChannelType.Mail =>
        RNotificationChannelMail.getById(ref.id).map(_.map(Email.apply))
      case ChannelType.Matrix =>
        RNotificationChannelMatrix.getById(ref.id).map(_.map(Matrix.apply))
      case ChannelType.Gotify =>
        RNotificationChannelGotify.getById(ref.id).map(_.map(Gotify.apply))
      case ChannelType.Http =>
        RNotificationChannelHttp.getById(ref.id).map(_.map(Http.apply))
    }

  def getByHook(r: RNotificationHook): ConnectionIO[Vector[RNotificationChannel]] = {
    def opt(id: Option[Ident]): OptionT[ConnectionIO, Ident] =
      OptionT.fromOption(id)

    for {
      mail <- opt(r.channelMail).flatMapF(RNotificationChannelMail.getById).value
      gotify <- opt(r.channelGotify).flatMapF(RNotificationChannelGotify.getById).value
      matrix <- opt(r.channelMatrix).flatMapF(RNotificationChannelMatrix.getById).value
      http <- opt(r.channelHttp).flatMapF(RNotificationChannelHttp.getById).value
    } yield mail.map(Email.apply).toVector ++
      gotify.map(Gotify.apply).toVector ++
      matrix.map(Matrix.apply).toVector ++
      http.map(Http.apply).toVector
  }

  def deleteByAccount(id: Ident, account: AccountId): ConnectionIO[Int] =
    for {
      n1 <- RNotificationChannelMail.deleteByAccount(id, account)
      n2 <- RNotificationChannelGotify.deleteByAccount(id, account)
      n3 <- RNotificationChannelMatrix.deleteByAccount(id, account)
      n4 <- RNotificationChannelHttp.deleteByAccount(id, account)
    } yield n1 + n2 + n3 + n4
}
