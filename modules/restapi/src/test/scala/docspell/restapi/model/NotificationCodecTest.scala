/*
 * Copyright 2020 Eike K. & Contributors
 *
 * SPDX-License-Identifier: AGPL-3.0-or-later
 */

package docspell.restapi.model

import docspell.common._
import docspell.notification.api.ChannelRef
import docspell.notification.api.ChannelType

import io.circe.Decoder
import io.circe.parser
import munit._

class NotificationCodecTest extends FunSuite {

  def parse[A: Decoder](str: String): A =
    parser.parse(str).fold(throw _, identity).as[A].fold(throw _, identity)

  def id(str: String): Ident =
    Ident.unsafe(str)

  test("decode with channelref") {
    val json = """{"id":"",
 "enabled": true,
 "channel": {"id":"abcde", "channelType":"matrix"},
 "allEvents": false,
 "events": ["TagsChanged", "SetFieldValue"]
}"""

    val hook = parse[NotificationHook](json)
    assertEquals(hook.enabled, true)
    assertEquals(hook.channel, Left(ChannelRef(id("abcde"), ChannelType.Matrix)))
  }

  test("decode with gotify data") {
    val json = """{"id":"",
 "enabled": true,
 "channel": {"id":"", "channelType":"gotify", "url":"http://test.gotify.com", "appKey": "abcde"},
 "allEvents": false,
 "eventFilter": null,
 "events": ["TagsChanged", "SetFieldValue"]
}"""
    val hook = parse[NotificationHook](json)
    assertEquals(hook.enabled, true)
    assertEquals(
      hook.channel,
      Right(
        NotificationChannel.Gotify(
          NotificationGotify(
            id(""),
            ChannelType.Gotify,
            LenientUri.unsafe("http://test.gotify.com"),
            Password("abcde"),
            None
          )
        )
      )
    )
  }

  test("decode with gotify data with prio") {
    val json = """{"id":"",
 "enabled": true,
 "channel": {"id":"", "channelType":"gotify", "url":"http://test.gotify.com", "appKey": "abcde", "priority":9},
 "allEvents": false,
 "eventFilter": null,
 "events": ["TagsChanged", "SetFieldValue"]
}"""
    val hook = parse[NotificationHook](json)
    assertEquals(hook.enabled, true)
    assertEquals(
      hook.channel,
      Right(
        NotificationChannel.Gotify(
          NotificationGotify(
            id(""),
            ChannelType.Gotify,
            LenientUri.unsafe("http://test.gotify.com"),
            Password("abcde"),
            Some(9)
          )
        )
      )
    )
  }
}
