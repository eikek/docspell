/*
 * Copyright 2020 Eike K. & Contributors
 *
 * SPDX-License-Identifier: AGPL-3.0-or-later
 */

package docspell.notification.api

import cats.Applicative
import cats.Functor
import cats.data.Kleisli
import cats.data.OptionT

import io.circe.Json
import io.circe.syntax._

trait EventContext {

  def event: Event

  def content: Json

  lazy val asJson: Json =
    Json.obj(
      "eventType" -> event.eventType.asJson,
      "account" -> Json.obj(
        "collective" -> event.account.collective.asJson,
        "user" -> event.account.user.asJson,
        "login" -> event.account.asJson
      ),
      "content" -> content
    )

  def defaultTitle: String
  def defaultTitleHtml: String

  def defaultBody: String
  def defaultBodyHtml: String

  def defaultBoth: String
  def defaultBothHtml: String

  lazy val asJsonWithMessage: Json = {
    val data = asJson
    val msg = Json.obj(
      "message" -> Json.obj(
        "title" -> defaultTitle.asJson,
        "body" -> defaultBody.asJson
      ),
      "messageHtml" -> Json.obj(
        "title" -> defaultTitleHtml.asJson,
        "body" -> defaultBodyHtml.asJson
      )
    )

    data.withObject(o1 => msg.withObject(o2 => o1.deepMerge(o2).asJson))
  }
}

object EventContext {
  def empty[F[_]](ev: Event): EventContext =
    new EventContext {
      val event = ev
      def content = Json.obj()
      def defaultTitle = ""
      def defaultTitleHtml = ""
      def defaultBody = ""
      def defaultBodyHtml = ""
      def defaultBoth: String = ""
      def defaultBothHtml: String = ""
    }

  /** For an event, the context can be created that is usually amended with more
    * information. Since these information may be missing, it is possible that no context
    * can be created.
    */
  type Factory[F[_], E <: Event] = Kleisli[OptionT[F, *], E, EventContext]

  def factory[F[_]: Functor, E <: Event](
      run: E => F[EventContext]
  ): Factory[F, E] =
    Kleisli(run).mapK(OptionT.liftK[F])

  def pure[F[_]: Applicative, E <: Event](run: E => EventContext): Factory[F, E] =
    factory(ev => Applicative[F].pure(run(ev)))

  type Example[F[_], E <: Event] = Kleisli[F, E, EventContext]

  def example[F[_], E <: Event](run: E => F[EventContext]): Example[F, E] =
    Kleisli(run)
}
