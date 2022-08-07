/*
 * Copyright 2020 Eike K. & Contributors
 *
 * SPDX-License-Identifier: AGPL-3.0-or-later
 */

package docspell.notification.impl.context

import cats.effect._
import cats.implicits._

import docspell.common._
import docspell.notification.api._
import docspell.notification.impl.AbstractEventContext
import docspell.notification.impl.context.Syntax._
import docspell.store.queries.ListItem

import doobie._
import io.circe.Encoder
import io.circe.syntax._
import yamusca.implicits._
import yamusca.imports._

final case class ItemSelectionCtx(event: Event.ItemSelection, data: ItemSelectionCtx.Data)
    extends AbstractEventContext {
  val content = data.asJson

  val titleTemplate = Right(mustache"Your items")
  val bodyTemplate = event.contentStart match {
    case Some(cnt) =>
      mustache
        .parse(cnt)
        .leftMap { case (in, err) =>
          s"Error parsing template: $err! Near ${in.pos}: ${in.raw}."
        }
        .map(start => start ++ ItemSelectionCtx.basicBody)

    case None =>
      Right(ItemSelectionCtx.basicBodyStart ++ ItemSelectionCtx.basicBody)
  }

  implicit final class TemplateOps(self: Template) {
    def ++(next: Template) = Template(self.els ++ next.els)
  }
}

object ItemSelectionCtx {
  import BasicData._

  type Factory = EventContext.Factory[ConnectionIO, Event.ItemSelection]

  def apply: Factory =
    EventContext.factory(ev =>
      for {
        now <- Timestamp.current[ConnectionIO]
        items <- Item.find(ev.items, ev.account, now)
        msg = ItemSelectionCtx(
          ev,
          Data(
            ev.account,
            items.toList,
            ev.itemUrl,
            ev.more,
            ev.account.login.id
          )
        )
      } yield msg
    )

  def sample[F[_]: Sync]: EventContext.Example[F, Event.ItemSelection] =
    EventContext.example(ev =>
      for {
        items <- ev.items.traverse(Item.sample[F])
      } yield ItemSelectionCtx(
        ev,
        Data(ev.account, items.toList, ev.itemUrl, ev.more, ev.account.login.id)
      )
    )

  final case class Data(
      account: AccountInfo,
      items: List[Item],
      itemUrl: Option[String],
      more: Boolean,
      username: String
  )
  object Data {
    implicit val jsonEncoder: Encoder[Data] =
      io.circe.generic.semiauto.deriveEncoder

    def create(
        account: AccountInfo,
        items: Vector[ListItem],
        baseUrl: Option[LenientUri],
        more: Boolean,
        now: Timestamp
    ): Data =
      Data(
        account,
        items.map(Item(now)).toList,
        baseUrl.map(_.asString),
        more,
        account.login.id
      )
  }

  private val basicBodyStart = mustache"""
Hello {{{ content.username }}},

this is Docspell informing you about your next items."""

  private val basicBody = mustache"""
{{#content}}
{{#itemUrl}}
{{#items}}
- {{#overDue}}**(OVERDUE)** {{/overDue}}[{{name}}]({{itemUrl}}/{{id}}){{#dueDate}}, {{#overDue}}was {{/overDue}}due {{dueIn}} on *{{dueDate}}*{{/dueDate}}; {{#corrOrg}}from {{corrOrg}}{{/corrOrg}} received on {{date}} via {{source}}
{{/items}}
{{/itemUrl}}
{{^itemUrl}}
{{#items}}
- {{#overDue}}**(OVERDUE)** {{/overDue}}*{{name}}*{{#dueDate}}, {{#overDue}}was {{/overDue}}due {{dueIn}} on *{{dueDate}}*{{/dueDate}}; {{#corrOrg}}from {{corrOrg}}{{/corrOrg}} received on {{date}} via {{source}}
{{/items}}
{{/itemUrl}}
{{#more}}
- … more have been left out for brevity
{{/more}}
{{/content}}"""
}
