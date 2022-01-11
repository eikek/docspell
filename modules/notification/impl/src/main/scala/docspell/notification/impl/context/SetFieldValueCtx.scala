/*
 * Copyright 2020 Eike K. & Contributors
 *
 * SPDX-License-Identifier: AGPL-3.0-or-later
 */

package docspell.notification.impl.context

import cats.data.Kleisli
import cats.data.OptionT
import cats.effect.Sync
import cats.implicits._

import docspell.common._
import docspell.notification.api.{Event, EventContext}
import docspell.notification.impl.AbstractEventContext
import docspell.notification.impl.context.BasicData._
import docspell.notification.impl.context.Syntax._
import docspell.store.records._

import doobie._
import io.circe.Encoder
import io.circe.syntax._
import yamusca.implicits._

final case class SetFieldValueCtx(event: Event.SetFieldValue, data: SetFieldValueCtx.Data)
    extends AbstractEventContext {

  val content = data.asJson

  val titleTemplate = Right(mustache"{{eventType}} (by *{{account.user}}*)")
  val bodyTemplate =
    Right(mustache"""{{#content}}{{#field.label}}*{{field.label}}* {{/field.label}}{{^field.label}}*{{field.name}}* {{/field.label}} was set to '{{value}}' on {{#items}}{{^-first}}, {{/-first}}{{#itemUrl}}[`{{name}}`]({{{itemUrl}}}/{{{id}}}){{/itemUrl}}{{^itemUrl}}`{{name}}`{{/itemUrl}}{{/items}}.{{/content}}""")

}

object SetFieldValueCtx {
  type Factory = EventContext.Factory[ConnectionIO, Event.SetFieldValue]

  def apply: Factory =
    Kleisli(ev =>
      for {
        now <- OptionT.liftF(Timestamp.current[ConnectionIO])
        items <- OptionT.liftF(Item.find(ev.items, ev.account, now))
        field <- OptionT(RCustomField.findById(ev.field, ev.account.collective))
        msg = SetFieldValueCtx(
          ev,
          Data(
            ev.account,
            items.toList,
            Field(field),
            ev.value,
            ev.itemUrl
          )
        )
      } yield msg
    )

  def sample[F[_]: Sync]: EventContext.Example[F, Event.SetFieldValue] =
    EventContext.example(ev =>
      for {
        items <- ev.items.traverse(Item.sample[F])
        field <- Field.sample[F](ev.field)
      } yield SetFieldValueCtx(
        ev,
        Data(ev.account, items.toList, field, ev.value, ev.itemUrl)
      )
    )

  final case class Data(
      account: AccountId,
      items: List[Item],
      field: Field,
      value: String,
      itemUrl: Option[String]
  )

  object Data {
    implicit val jsonEncoder: Encoder[Data] =
      io.circe.generic.semiauto.deriveEncoder
  }

}
