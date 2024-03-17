/*
 * Copyright 2020 Eike K. & Contributors
 *
 * SPDX-License-Identifier: AGPL-3.0-or-later
 */

package docspell.notification.api

import cats.data.{NonEmptyList => Nel}
import cats.effect.kernel.Sync
import cats.implicits._

import docspell.common._

import io.circe.{Decoder, Encoder, Json}

/** An event generated in the platform. */
sealed trait Event {

  /** The type of event */
  def eventType: EventType

  /** The user who caused it. */
  def account: AccountInfo

  /** The base url for generating links. This is dynamic. */
  def baseUrl: Option[LenientUri]
}

sealed trait EventType { self: Product =>

  def name: String =
    productPrefix
}

object EventType {

  def all: Nel[EventType] =
    Nel.of(
      Event.TagsChanged,
      Event.SetFieldValue,
      Event.DeleteFieldValue,
      Event.ItemSelection,
      Event.JobSubmitted,
      Event.JobDone
    )

  def fromString(str: String): Either[String, EventType] =
    all.find(_.name.equalsIgnoreCase(str)).toRight(s"Unknown event type: $str")

  def unsafeFromString(str: String): EventType =
    fromString(str).fold(sys.error, identity)

  implicit val jsonDecoder: Decoder[EventType] =
    Decoder.decodeString.emap(fromString)

  implicit val jsonEncoder: Encoder[EventType] =
    Encoder.encodeString.contramap(_.name)
}

object Event {

  /** Event triggered when tags of one or more items have changed */
  final case class TagsChanged(
      account: AccountInfo,
      items: Nel[Ident],
      added: List[String],
      removed: List[String],
      baseUrl: Option[LenientUri]
  ) extends Event {
    val eventType = TagsChanged
  }
  case object TagsChanged extends EventType {
    def partial(
        items: Nel[Ident],
        added: List[String],
        removed: List[String]
    ): (AccountInfo, Option[LenientUri]) => TagsChanged =
      (acc, url) => TagsChanged(acc, items, added, removed, url)

    def sample[F[_]: Sync](
        account: AccountInfo,
        baseUrl: Option[LenientUri]
    ): F[TagsChanged] =
      for {
        id1 <- Ident.randomId[F]
        id2 <- Ident.randomId[F]
        id3 <- Ident.randomId[F]
      } yield TagsChanged(account, Nel.of(id1), List(id2.id), List(id3.id), baseUrl)
  }

  /** Event triggered when a custom field on an item changes. */
  final case class SetFieldValue(
      account: AccountInfo,
      items: Nel[Ident],
      field: Ident,
      value: String,
      baseUrl: Option[LenientUri]
  ) extends Event {
    val eventType = SetFieldValue
  }
  case object SetFieldValue extends EventType {
    def partial(
        items: Nel[Ident],
        field: Ident,
        value: String
    ): (AccountInfo, Option[LenientUri]) => SetFieldValue =
      (acc, url) => SetFieldValue(acc, items, field, value, url)

    def sample[F[_]: Sync](
        account: AccountInfo,
        baseUrl: Option[LenientUri]
    ): F[SetFieldValue] =
      for {
        id1 <- Ident.randomId[F]
        id2 <- Ident.randomId[F]
      } yield SetFieldValue(account, Nel.of(id1), id2, "10.15", baseUrl)
  }

  final case class DeleteFieldValue(
      account: AccountInfo,
      items: Nel[Ident],
      field: Ident,
      baseUrl: Option[LenientUri]
  ) extends Event {
    val eventType = DeleteFieldValue
  }
  case object DeleteFieldValue extends EventType {
    def partial(
        items: Nel[Ident],
        field: Ident
    ): (AccountInfo, Option[LenientUri]) => DeleteFieldValue =
      (acc, url) => DeleteFieldValue(acc, items, field, url)

    def sample[F[_]: Sync](
        account: AccountInfo,
        baseUrl: Option[LenientUri]
    ): F[DeleteFieldValue] =
      for {
        id1 <- Ident.randomId[F]
        id2 <- Ident.randomId[F]
      } yield DeleteFieldValue(account, Nel.of(id1), id2, baseUrl)

  }

  /** Some generic list of items, chosen by a user. This is use to notify about periodic
    * search results.
    */
  final case class ItemSelection(
      account: AccountInfo,
      items: Nel[Ident],
      more: Boolean,
      baseUrl: Option[LenientUri],
      contentStart: Option[String]
  ) extends Event {
    val eventType = ItemSelection
  }

  case object ItemSelection extends EventType {
    def sample[F[_]: Sync](
        account: AccountInfo,
        baseUrl: Option[LenientUri]
    ): F[ItemSelection] =
      for {
        id1 <- Ident.randomId[F]
        id2 <- Ident.randomId[F]
      } yield ItemSelection(account, Nel.of(id1, id2), more = true, baseUrl, None)
  }

  /** Event when a new job is added to the queue */
  final case class JobSubmitted(
      account: AccountInfo,
      jobId: Ident,
      group: Ident,
      task: Ident,
      args: String,
      state: JobState,
      subject: String,
      submitter: Ident
  ) extends Event {
    val eventType = JobSubmitted
    val baseUrl = None
  }
  case object JobSubmitted extends EventType {
    def sample[F[_]: Sync](account: AccountInfo): F[JobSubmitted] =
      for {
        id <- Ident.randomId[F]
        ev = JobSubmitted(
          account,
          id,
          account.collective,
          Ident.unsafe("process-something-task"),
          "",
          JobState.running,
          "Process 3 files",
          account.login
        )
      } yield ev
  }

  /** Event when a job is finished (in final state). */
  final case class JobDone(
      account: AccountInfo,
      jobId: Ident,
      group: Ident,
      task: Ident,
      args: String,
      state: JobState,
      subject: String,
      submitter: Ident,
      resultData: Json,
      resultMsg: Option[String]
  ) extends Event {
    val eventType = JobDone
    val baseUrl = None
  }
  case object JobDone extends EventType {
    def sample[F[_]: Sync](account: AccountInfo): F[JobDone] =
      for {
        id <- Ident.randomId[F]
        ev = JobDone(
          account,
          id,
          account.collective,
          Ident.unsafe("process-something-task"),
          "",
          JobState.running,
          "Process 3 files",
          account.login,
          Json.Null,
          None
        )
      } yield ev
  }

  def sample[F[_]: Sync](
      evt: EventType,
      account: AccountInfo,
      baseUrl: Option[LenientUri]
  ): F[Event] =
    evt match {
      case TagsChanged =>
        TagsChanged.sample[F](account, baseUrl).map(x => x: Event)
      case SetFieldValue =>
        SetFieldValue.sample[F](account, baseUrl).map(x => x: Event)
      case ItemSelection =>
        ItemSelection.sample[F](account, baseUrl).map(x => x: Event)
      case JobSubmitted =>
        JobSubmitted.sample[F](account).map(x => x: Event)
      case JobDone =>
        JobDone.sample[F](account).map(x => x: Event)
      case DeleteFieldValue =>
        DeleteFieldValue.sample[F](account, baseUrl).map(x => x: Event)
    }
}
