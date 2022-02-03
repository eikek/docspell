/*
 * Copyright 2020 Eike K. & Contributors
 *
 * SPDX-License-Identifier: AGPL-3.0-or-later
 */

package docspell.store.records

import cats.data.{NonEmptyList => Nel, OptionT}
import cats.implicits._

import docspell.common._
import docspell.notification.api.{Channel, ChannelRef, ChannelType}
import docspell.store.qb.DSL._

import doobie._

sealed trait RNotificationChannel {

  def id: Ident = fold(_.id, _.id, _.id, _.id)

  def name: Option[String] = fold(_.name, _.name, _.name, _.name)

  def channelType: ChannelType =
    fold(
      _ => ChannelType.Mail,
      _ => ChannelType.Gotify,
      _ => ChannelType.Matrix,
      _ => ChannelType.Http
    )

  def asRef: ChannelRef =
    ChannelRef(id, channelType, name)

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

  def getById(id: Ident, userId: Ident): ConnectionIO[Vector[RNotificationChannel]] =
    for {
      mail <- RNotificationChannelMail.getById(userId)(id)
      gotify <- RNotificationChannelGotify.getById(userId)(id)
      matrix <- RNotificationChannelMatrix.getById(userId)(id)
      http <- RNotificationChannelHttp.getById(userId)(id)
    } yield mail.map(Email.apply).toVector ++
      gotify.map(Gotify.apply).toVector ++
      matrix.map(Matrix.apply).toVector ++
      http.map(Http.apply).toVector

  def getByRef(
      ref: ChannelRef,
      userId: Ident
  ): ConnectionIO[Option[RNotificationChannel]] =
    ref.channelType match {
      case ChannelType.Mail =>
        RNotificationChannelMail.getById(userId)(ref.id).map(_.map(Email.apply))
      case ChannelType.Matrix =>
        RNotificationChannelMatrix.getById(userId)(ref.id).map(_.map(Matrix.apply))
      case ChannelType.Gotify =>
        RNotificationChannelGotify.getById(userId)(ref.id).map(_.map(Gotify.apply))
      case ChannelType.Http =>
        RNotificationChannelHttp.getById(userId)(ref.id).map(_.map(Http.apply))
    }

  def resolveRefs(refs: Nel[ChannelRef]): ConnectionIO[List[ChannelRef]] = {
    val byType = refs.groupByNem(_.channelType)
    val queries = byType.toNel
      .map {
        case (ChannelType.Mail, refs) =>
          RNotificationChannelMail.findRefs(refs.map(_.id))
        case (ChannelType.Matrix, refs) =>
          RNotificationChannelMatrix.findRefs(refs.map(_.id))
        case (ChannelType.Gotify, refs) =>
          RNotificationChannelGotify.findRefs(refs.map(_.id))
        case (ChannelType.Http, refs) =>
          RNotificationChannelHttp.findRefs(refs.map(_.id))
      }
    union(queries).build.query[ChannelRef].to[List]
  }

  def getByHook(hook: RNotificationHook): ConnectionIO[Vector[RNotificationChannel]] = {
    def opt(id: Option[Ident]): OptionT[ConnectionIO, Ident] =
      OptionT.fromOption(id)

    def find(
        r: RNotificationHookChannel
    ): ConnectionIO[Vector[RNotificationChannel]] =
      for {
        mail <- opt(r.channelMail)
          .flatMapF(RNotificationChannelMail.getById(hook.uid))
          .value
        gotify <- opt(r.channelGotify)
          .flatMapF(RNotificationChannelGotify.getById(hook.uid))
          .value
        matrix <- opt(r.channelMatrix)
          .flatMapF(RNotificationChannelMatrix.getById(hook.uid))
          .value
        http <- opt(r.channelHttp)
          .flatMapF(RNotificationChannelHttp.getById(hook.uid))
          .value
      } yield mail.map(Email.apply).toVector ++
        gotify.map(Gotify.apply).toVector ++
        matrix.map(Matrix.apply).toVector ++
        http.map(Http.apply).toVector

    RNotificationHookChannel
      .allOf(hook.id)
      .flatMap(_.flatTraverse(find))
  }

  def deleteByAccount(id: Ident, account: AccountId): ConnectionIO[Int] =
    for {
      n1 <- RNotificationChannelMail.deleteByAccount(id, account)
      n2 <- RNotificationChannelGotify.deleteByAccount(id, account)
      n3 <- RNotificationChannelMatrix.deleteByAccount(id, account)
      n4 <- RNotificationChannelHttp.deleteByAccount(id, account)
    } yield n1 + n2 + n3 + n4

  def fromChannel(
      channel: Channel,
      id: Ident,
      userId: Ident
  ): OptionT[ConnectionIO, RNotificationChannel] =
    for {
      time <- OptionT.liftF(Timestamp.current[ConnectionIO])
      logger = Logger.log4s[ConnectionIO](org.log4s.getLogger)
      r <-
        channel match {
          case Channel.Mail(_, name, conn, recipients) =>
            for {
              _ <- OptionT.liftF(
                logger.debug(
                  s"Looking up user smtp for ${userId.id} and ${conn.id}"
                )
              )
              mailConn <- OptionT(RUserEmail.getByUser(userId, conn))
              rec = RNotificationChannelMail(
                id,
                userId,
                name,
                mailConn.id,
                recipients.toList,
                time
              ).vary
            } yield rec
          case Channel.Gotify(_, name, url, appKey, prio) =>
            OptionT.pure[ConnectionIO](
              RNotificationChannelGotify(
                id,
                userId,
                name,
                url,
                appKey,
                prio,
                time
              ).vary
            )
          case Channel.Matrix(_, name, homeServer, roomId, accessToken) =>
            OptionT.pure[ConnectionIO](
              RNotificationChannelMatrix(
                id,
                userId,
                name,
                homeServer,
                roomId,
                accessToken,
                "m.text",
                time
              ).vary
            )
          case Channel.Http(_, name, url) =>
            OptionT.pure[ConnectionIO](
              RNotificationChannelHttp(id, userId, name, url, time).vary
            )
        }
    } yield r
}
