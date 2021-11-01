/*
 * Copyright 2020 Eike K. & Contributors
 *
 * SPDX-License-Identifier: AGPL-3.0-or-later
 */

package docspell.pubsub.api

import scala.reflect.{ClassTag, classTag}

import io.circe.{Codec, Decoder, Encoder}

final case class TypedTopic[A](topic: Topic, codec: Codec[A], msgClass: Class[_]) {
  def name: String = topic.name

  def withTopic(topic: Topic): TypedTopic[A] =
    copy(topic = topic)

  def withName(name: String): TypedTopic[A] =
    withTopic(Topic(name))
}

object TypedTopic {

  def apply[A: ClassTag](
      topic: Topic
  )(implicit dec: Decoder[A], enc: Encoder[A]): TypedTopic[A] =
    TypedTopic(topic, Codec.from(dec, enc), classTag[A].runtimeClass)
}
