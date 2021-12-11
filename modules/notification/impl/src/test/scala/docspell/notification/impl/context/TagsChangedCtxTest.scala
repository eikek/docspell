/*
 * Copyright 2020 Eike K. & Contributors
 *
 * SPDX-License-Identifier: AGPL-3.0-or-later
 */

package docspell.notification.impl.context

import cats.data.{NonEmptyList => Nel}
import cats.implicits._

import docspell.common._
import docspell.notification.api.Event
import docspell.notification.impl.context.BasicData._

import munit._

class TagsChangedCtxTest extends FunSuite {

  val url = LenientUri.unsafe("http://test")
  val account = AccountId(id("user2"), id("user2"))
  val tag = Tag(id("a-b-1"), "tag-red", Some("doctype"))
  val item = Item(
    id = id("item-1"),
    name = "Report 2",
    dateMillis = Timestamp.Epoch,
    date = "2020-11-11",
    direction = Direction.Incoming,
    state = ItemState.created,
    dueDateMillis = None,
    dueDate = None,
    source = "webapp",
    overDue = false,
    dueIn = None,
    corrOrg = Some("Acme"),
    notes = None
  )

  def id(str: String): Ident = Ident.unsafe(str)

  test("create tags changed message") {
    val event =
      Event.TagsChanged(account, Nel.of(id("item1")), List("tag-id"), Nil, url.some)
    val ctx = TagsChangedCtx(
      event,
      TagsChangedCtx.Data(account, List(item), List(tag), Nil, url.some.map(_.asString))
    )

    assertEquals(ctx.defaultTitle, "TagsChanged (by *user2*)")
    assertEquals(
      ctx.defaultBody,
      "Adding *tag-red* on [`Report 2`](http://test/item-1)."
    )
  }
  test("create tags changed message") {
    val event = Event.TagsChanged(account, Nel.of(id("item1")), Nil, Nil, url.some)
    val ctx = TagsChangedCtx(
      event,
      TagsChangedCtx.Data(
        account,
        List(item),
        List(tag),
        List(tag.copy(name = "tag-blue")),
        url.asString.some
      )
    )

    assertEquals(ctx.defaultTitle, "TagsChanged (by *user2*)")
    assertEquals(
      ctx.defaultBody,
      "Adding *tag-red*; Removing *tag-blue* on [`Report 2`](http://test/item-1)."
    )
  }

}
