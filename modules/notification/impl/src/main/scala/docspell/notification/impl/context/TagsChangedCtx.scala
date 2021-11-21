/*
 * Copyright 2020 Eike K. & Contributors
 *
 * SPDX-License-Identifier: AGPL-3.0-or-later
 */

package docspell.notification.impl.context

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

final case class TagsChangedCtx(event: Event.TagsChanged, data: TagsChangedCtx.Data)
    extends AbstractEventContext {

  val content = data.asJson

  val titleTemplate = mustache"{{eventType}} (by *{{account.user}}*)"
  val bodyTemplate =
    mustache"""{{#content}}{{#added}}{{#-first}}Adding {{/-first}}{{^-first}}, {{/-first}}*{{name}}*{{/added}}{{#removed}}{{#added}}{{#-first}};{{/-first}}{{/added}}{{#-first}} Removing {{/-first}}{{^-first}}, {{/-first}}*{{name}}*{{/removed}} on {{#items}}{{^-first}}, {{/-first}}{{#itemUrl}}[`{{name}}`]({{{itemUrl}}}/{{{id}}}){{/itemUrl}}{{^itemUrl}}`{{name}}`{{/itemUrl}}{{/items}}.{{/content}}"""

}

object TagsChangedCtx {
  type Factory = EventContext.Factory[ConnectionIO, Event.TagsChanged]

  def apply: Factory =
    EventContext.factory(ev =>
      for {
        tagsAdded <- RTag.findAllByNameOrId(ev.added, ev.account.collective)
        tagsRemov <- RTag.findAllByNameOrId(ev.removed, ev.account.collective)
        now <- Timestamp.current[ConnectionIO]
        items <- Item.find(ev.items, ev.account, now)
        msg = TagsChangedCtx(
          ev,
          Data(
            ev.account,
            items.toList,
            tagsAdded.map(Tag.apply).toList,
            tagsRemov.map(Tag.apply).toList,
            ev.itemUrl
          )
        )
      } yield msg
    )

  def sample[F[_]: Sync]: EventContext.Example[F, Event.TagsChanged] =
    EventContext.example(ev =>
      for {
        items <- ev.items.traverse(Item.sample[F])
        added <- ev.added.traverse(Tag.sample[F])
        remov <- ev.removed.traverse(Tag.sample[F])
      } yield TagsChangedCtx(
        ev,
        Data(ev.account, items.toList, added, remov, ev.itemUrl)
      )
    )

  final case class Data(
      account: AccountId,
      items: List[Item],
      added: List[Tag],
      removed: List[Tag],
      itemUrl: Option[String]
  )

  object Data {
    implicit val jsonEncoder: Encoder[Data] =
      io.circe.generic.semiauto.deriveEncoder
  }
}
