/*
 * Copyright 2020 Eike K. & Contributors
 *
 * SPDX-License-Identifier: AGPL-3.0-or-later
 */

package docspell.backend.ops

import java.io.PrintWriter
import java.io.StringWriter

import cats.data.OptionT
import cats.data.{NonEmptyList => Nel}
import cats.effect._
import cats.implicits._

import docspell.backend.ops.ONotification.Hook
import docspell.common._
import docspell.jsonminiq.JsonMiniQuery
import docspell.notification.api._
import docspell.store.AddResult
import docspell.store.Store
import docspell.store.UpdateResult
import docspell.store.queries.QNotification
import docspell.store.records._

trait ONotification[F[_]] {

  def sendMessage(
      logger: Logger[F],
      data: EventContext,
      channels: Seq[NotificationChannel]
  ): F[Unit]

  def offerEvents(ev: Iterable[Event]): F[Unit]

  def mkNotificationChannel(
      channel: Channel,
      userId: Ident
  ): F[Vector[NotificationChannel]]

  def findNotificationChannel(ref: ChannelRef): F[Vector[NotificationChannel]]

  def listChannels(account: AccountId): F[Vector[Channel]]

  def deleteChannel(id: Ident, account: AccountId): F[UpdateResult]

  def createChannel(channel: Channel, account: AccountId): F[AddResult]

  def updateChannel(channel: Channel, account: AccountId): F[UpdateResult]

  def listHooks(account: AccountId): F[Vector[Hook]]

  def deleteHook(id: Ident, account: AccountId): F[UpdateResult]

  def createHook(hook: Hook, account: AccountId): F[AddResult]

  def updateHook(hook: Hook, account: AccountId): F[UpdateResult]

  def sampleEvent(
      evt: EventType,
      account: AccountId,
      baseUrl: Option[LenientUri]
  ): F[EventContext]

  def sendSampleEvent(
      evt: EventType,
      channel: Channel,
      account: AccountId,
      baseUrl: Option[LenientUri]
  ): F[ONotification.SendTestResult]
}

object ONotification {
  private[this] val logger = org.log4s.getLogger

  def apply[F[_]: Async](
      store: Store[F],
      notMod: NotificationModule[F]
  ): Resource[F, ONotification[F]] =
    Resource.pure[F, ONotification[F]](new ONotification[F] {
      val log = Logger.log4s[F](logger)

      def withUserId[A](
          account: AccountId
      )(f: Ident => F[UpdateResult]): F[UpdateResult] =
        OptionT(store.transact(RUser.findIdByAccount(account)))
          .semiflatMap(f)
          .getOrElse(UpdateResult.notFound)

      def offerEvents(ev: Iterable[Event]): F[Unit] =
        ev.toList.traverse(notMod.offer(_)).as(())

      def sendMessage(
          logger: Logger[F],
          data: EventContext,
          channels: Seq[NotificationChannel]
      ): F[Unit] =
        notMod.send(logger, data, channels)

      def sampleEvent(
          evt: EventType,
          account: AccountId,
          baseUrl: Option[LenientUri]
      ): F[EventContext] =
        Event
          .sample[F](evt, account, baseUrl)
          .flatMap(notMod.sampleEvent.run)

      def sendSampleEvent(
          evt: EventType,
          channel: Channel,
          account: AccountId,
          baseUrl: Option[LenientUri]
      ): F[SendTestResult] = {
        def doCreate(userId: Ident) =
          (for {
            ev <- sampleEvent(evt, account, baseUrl)
            logbuf <- Logger.buffer()
            ch <- mkNotificationChannel(channel, userId)
            _ <- notMod.send(logbuf._2.andThen(log), ev, ch)
            logs <- logbuf._1.get
            res = SendTestResult(true, logs)
          } yield res).attempt
            .map {
              case Right(res) => res
              case Left(ex) =>
                val ps = new StringWriter()
                ex.printStackTrace(new PrintWriter(ps))
                SendTestResult(false, Vector(s"${ex.getMessage}\n$ps"))
            }

        OptionT(store.transact(RUser.findIdByAccount(account)))
          .semiflatMap(doCreate)
          .getOrElse(
            SendTestResult(false, Vector(s"No user found in db for: ${account.asString}"))
          )
      }

      def listChannels(account: AccountId): F[Vector[Channel]] =
        store
          .transact(RNotificationChannel.getByAccount(account))
          .map(_.map(ChannelConv.makeChannel))

      def deleteChannel(id: Ident, account: AccountId): F[UpdateResult] =
        UpdateResult
          .fromUpdate(
            store.transact(RNotificationChannel.deleteByAccount(id, account))
          )
          .flatTap(_ => log.info(s"Deleted channel ${id.id} for ${account.asString}"))

      def createChannel(channel: Channel, account: AccountId): F[AddResult] =
        (for {
          newId <- OptionT.liftF(Ident.randomId[F])
          userId <- OptionT(store.transact(RUser.findIdByAccount(account)))
          r <- ChannelConv.makeRecord[F](store, log, Right(channel), newId, userId)
          _ <- OptionT.liftF(store.transact(RNotificationChannel.insert(r)))
          _ <- OptionT.liftF(log.debug(s"Created channel $r for $account"))
        } yield AddResult.Success)
          .getOrElse(AddResult.failure(new Exception("User not found!")))

      def updateChannel(channel: Channel, account: AccountId): F[UpdateResult] =
        (for {
          userId <- OptionT(store.transact(RUser.findIdByAccount(account)))
          r <- ChannelConv.makeRecord[F](store, log, Right(channel), channel.id, userId)
          n <- OptionT.liftF(store.transact(RNotificationChannel.update(r)))
        } yield UpdateResult.fromUpdateRows(n)).getOrElse(UpdateResult.notFound)

      def listHooks(account: AccountId): F[Vector[Hook]] =
        store.transact(for {
          list <- RNotificationHook.findAllByAccount(account)
          res <- list.traverse((Hook.fromRecord _).tupled)
        } yield res)

      def deleteHook(id: Ident, account: AccountId): F[UpdateResult] =
        UpdateResult
          .fromUpdate(store.transact(RNotificationHook.deleteByAccount(id, account)))

      def createHook(hook: Hook, account: AccountId): F[AddResult] =
        (for {
          _ <- OptionT.liftF(log.debug(s"Creating new notification hook: $hook"))
          channelId <- OptionT.liftF(Ident.randomId[F])
          userId <- OptionT(store.transact(RUser.findIdByAccount(account)))
          r <- ChannelConv.makeRecord[F](store, log, hook.channel, channelId, userId)
          _ <- OptionT.liftF(
            if (channelId == r.id) store.transact(RNotificationChannel.insert(r))
            else ().pure[F]
          )
          _ <- OptionT.liftF(log.debug(s"Created channel $r for $account"))
          hr <- OptionT.liftF(Hook.makeRecord(r, userId, hook))
          _ <- OptionT.liftF(store.transact(RNotificationHook.insert(hr)))
          _ <- OptionT.liftF(
            store.transact(RNotificationHookEvent.insertAll(hr.id, hook.events))
          )
        } yield AddResult.Success)
          .getOrElse(AddResult.failure(new Exception("User or channel not found!")))

      def updateHook(hook: Hook, account: AccountId): F[UpdateResult] = {
        def withHook(f: RNotificationHook => F[UpdateResult]): F[UpdateResult] =
          withUserId(account)(userId =>
            OptionT(store.transact(RNotificationHook.getById(hook.id, userId)))
              .semiflatMap(f)
              .getOrElse(UpdateResult.notFound)
          )

        def withChannel(
            r: RNotificationHook
        )(f: RNotificationChannel => F[UpdateResult]): F[UpdateResult] =
          ChannelConv
            .makeRecord(store, log, hook.channel, r.channelId, r.uid)
            .semiflatMap(f)
            .getOrElse(UpdateResult.notFound)

        def doUpdate(r: RNotificationHook): F[UpdateResult] =
          withChannel(r) { ch =>
            UpdateResult.fromUpdate(store.transact(for {
              nc <- RNotificationChannel.update(ch)
              ne <- RNotificationHookEvent.updateAll(
                r.id,
                if (hook.allEvents) Nil else hook.events
              )
              nr <- RNotificationHook.update(
                r.copy(
                  enabled = hook.enabled,
                  allEvents = hook.allEvents,
                  eventFilter = hook.eventFilter
                )
              )
            } yield nc + ne + nr))
          }

        withHook(doUpdate)
      }

      def mkNotificationChannel(
          channel: Channel,
          userId: Ident
      ): F[Vector[NotificationChannel]] =
        (for {
          rec <- ChannelConv
            .makeRecord(store, log, Right(channel), channel.id, userId)
          ch <- OptionT.liftF(store.transact(QNotification.readChannel(rec)))
        } yield ch).getOrElse(Vector.empty)

      def findNotificationChannel(ref: ChannelRef): F[Vector[NotificationChannel]] =
        (for {
          rec <- OptionT(store.transact(RNotificationChannel.getByRef(ref)))
          ch <- OptionT.liftF(store.transact(QNotification.readChannel(rec)))
        } yield ch).getOrElse(Vector.empty)
    })

  object ChannelConv {

    private[ops] def makeChannel(r: RNotificationChannel): Channel =
      r.fold(
        mail =>
          Channel.Mail(mail.id, mail.connection, Nel.fromListUnsafe(mail.recipients)),
        gotify => Channel.Gotify(r.id, gotify.url, gotify.appKey, gotify.priority),
        matrix =>
          Channel.Matrix(r.id, matrix.homeServer, matrix.roomId, matrix.accessToken),
        http => Channel.Http(r.id, http.url)
      )

    private[ops] def makeRecord[F[_]: Sync](
        store: Store[F],
        logger: Logger[F],
        channelIn: Either[ChannelRef, Channel],
        id: Ident,
        userId: Ident
    ): OptionT[F, RNotificationChannel] =
      channelIn match {
        case Left(ref) =>
          OptionT.liftF(logger.debug(s"Loading channel for ref: ${ref}")) *>
            OptionT(store.transact(RNotificationChannel.getByRef(ref)))

        case Right(channel) =>
          for {
            time <- OptionT.liftF(Timestamp.current[F])
            r <-
              channel match {
                case Channel.Mail(_, conn, recipients) =>
                  for {
                    _ <- OptionT.liftF(
                      logger.debug(
                        s"Looking up user smtp for ${userId.id} and ${conn.id}"
                      )
                    )
                    mailConn <- OptionT(
                      store.transact(RUserEmail.getByUser(userId, conn))
                    )
                    rec = RNotificationChannelMail(
                      id,
                      userId,
                      mailConn.id,
                      recipients.toList,
                      time
                    ).vary
                  } yield rec
                case Channel.Gotify(_, url, appKey, prio) =>
                  OptionT.pure[F](
                    RNotificationChannelGotify(id, userId, url, appKey, prio, time).vary
                  )
                case Channel.Matrix(_, homeServer, roomId, accessToken) =>
                  OptionT.pure[F](
                    RNotificationChannelMatrix(
                      id,
                      userId,
                      homeServer,
                      roomId,
                      accessToken,
                      "m.text",
                      time
                    ).vary
                  )
                case Channel.Http(_, url) =>
                  OptionT.pure[F](RNotificationChannelHttp(id, userId, url, time).vary)
              }
          } yield r
      }
  }

  final case class Hook(
      id: Ident,
      enabled: Boolean,
      channel: Either[ChannelRef, Channel],
      allEvents: Boolean,
      eventFilter: Option[JsonMiniQuery],
      events: List[EventType]
  )

  object Hook {
    import doobie._

    private[ops] def fromRecord(
        r: RNotificationHook,
        events: List[EventType]
    ): ConnectionIO[Hook] =
      RNotificationChannel
        .getByHook(r)
        .map(_.head)
        .map(ChannelConv.makeChannel)
        .map(ch => Hook(r.id, r.enabled, Right(ch), r.allEvents, r.eventFilter, events))

    private[ops] def makeRecord[F[_]: Sync](
        ch: RNotificationChannel,
        userId: Ident,
        hook: Hook
    ): F[RNotificationHook] =
      for {
        id <- Ident.randomId[F]
        time <- Timestamp.current[F]
        h = RNotificationHook(
          id,
          userId,
          hook.enabled,
          ch.fold(_.id.some, _ => None, _ => None, _ => None),
          ch.fold(_ => None, _.id.some, _ => None, _ => None),
          ch.fold(_ => None, _ => None, _.id.some, _ => None),
          ch.fold(_ => None, _ => None, _ => None, _.id.some),
          hook.allEvents,
          hook.eventFilter,
          time
        )
      } yield h
  }

  final case class SendTestResult(success: Boolean, logMessages: Vector[String])
}
