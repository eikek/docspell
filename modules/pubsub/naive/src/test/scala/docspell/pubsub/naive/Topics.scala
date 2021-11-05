/*
 * Copyright 2020 Eike K. & Contributors
 *
 * SPDX-License-Identifier: AGPL-3.0-or-later
 */

package docspell.pubsub.naive

import cats.data.NonEmptyList

import docspell.common.Ident
import docspell.pubsub.api._

import io.circe.generic.semiauto.{deriveDecoder, deriveEncoder}
import io.circe.{Decoder, Encoder}

object Topics {
  val jobSubmitted: TypedTopic[JobSubmittedMsg] =
    TypedTopic[JobSubmittedMsg](Topic("test-job-submitted"))

  final case class JobSubmittedMsg(task: Ident)
  object JobSubmittedMsg {
    implicit val encode: Encoder[JobSubmittedMsg] = deriveEncoder[JobSubmittedMsg]
    implicit val decode: Decoder[JobSubmittedMsg] = deriveDecoder[JobSubmittedMsg]
  }

  val jobCancel: TypedTopic[JobCancelMsg] =
    TypedTopic[JobCancelMsg](Topic("test-job-done"))
  final case class JobCancelMsg(id: Ident)
  object JobCancelMsg {
    implicit val encode: Encoder[JobCancelMsg] = deriveEncoder[JobCancelMsg]
    implicit val decode: Decoder[JobCancelMsg] = deriveDecoder[JobCancelMsg]
  }

  def all: NonEmptyList[TypedTopic[_]] =
    NonEmptyList.of(jobSubmitted, jobCancel)
}
