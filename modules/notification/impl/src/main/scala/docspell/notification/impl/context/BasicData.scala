/*
 * Copyright 2020 Eike K. & Contributors
 *
 * SPDX-License-Identifier: AGPL-3.0-or-later
 */

package docspell.notification.impl.context

import cats.data.NonEmptyList
import cats.effect.Sync
import cats.implicits._

import docspell.common._
import docspell.query.ItemQuery
import docspell.query.ItemQueryDsl
import docspell.store.qb.Batch
import docspell.store.queries.ListItem
import docspell.store.queries.QItem
import docspell.store.queries.Query
import docspell.store.records._

import doobie._
import io.circe.Encoder
import io.circe.generic.semiauto.deriveEncoder

object BasicData {

  final case class Tag(id: Ident, name: String, category: Option[String])
  object Tag {
    implicit val jsonEncoder: Encoder[Tag] = deriveEncoder

    def apply(t: RTag): Tag = Tag(t.tagId, t.name, t.category)

    def sample[F[_]: Sync](id: String): F[Tag] =
      Sync[F]
        .delay(if (math.random() > 0.5) "Invoice" else "Receipt")
        .map(tag => Tag(Ident.unsafe(id), tag, Some("doctype")))
  }

  final case class Item(
      id: Ident,
      name: String,
      dateMillis: Timestamp,
      date: String,
      direction: Direction,
      state: ItemState,
      dueDateMillis: Option[Timestamp],
      dueDate: Option[String],
      source: String,
      overDue: Boolean,
      dueIn: Option[String],
      corrOrg: Option[String],
      notes: Option[String]
  )

  object Item {
    implicit val jsonEncoder: Encoder[Item] = deriveEncoder

    private def calcDueLabels(now: Timestamp, dueDate: Option[Timestamp]) = {
      val dueIn = dueDate.map(dt => Timestamp.daysBetween(now, dt))
      val dueInLabel = dueIn.map {
        case 0          => "**today**"
        case 1          => "**tomorrow**"
        case -1         => s"**yesterday**"
        case n if n > 0 => s"in $n days"
        case n          => s"${n * -1} days ago"
      }
      (dueIn, dueInLabel)
    }

    def find(
        itemIds: NonEmptyList[Ident],
        account: AccountInfo,
        now: Timestamp
    ): ConnectionIO[Vector[Item]] = {
      import ItemQueryDsl._

      val q = Query(
        Query.Fix(
          account,
          Some(ItemQuery.Attr.ItemId.in(itemIds.map(_.id))),
          Some(_.byItemColumnAsc(_.created))
        )
      )
      for {
        items <- QItem
          .queryItems(q, now.toUtcDate, 25, Batch.limit(itemIds.size), None)
          .compile
          .to(Vector)
      } yield items.map(apply(now))
    }

    def apply(now: Timestamp)(i: ListItem): Item = {
      val (dueIn, dueInLabel) = calcDueLabels(now, i.dueDate)
      Item(
        i.id,
        i.name,
        i.date,
        i.date.toUtcDate.toString,
        i.direction,
        i.state,
        i.dueDate,
        i.dueDate.map(_.toUtcDate.toString),
        i.source,
        dueIn.exists(_ < 0),
        dueInLabel,
        i.corrOrg.map(_.name),
        i.notes
      )
    }

    def sample[F[_]: Sync](id: Ident): F[Item] =
      Timestamp.current[F].map { now =>
        val dueDate = if (id.hashCode % 2 == 0) Some(now + Duration.days(3)) else None
        val (dueIn, dueInLabel) = calcDueLabels(now, dueDate)
        Item(
          id,
          "MapleSirupLtd_202331.pdf",
          now - Duration.days(62),
          (now - Duration.days(62)).toUtcDate.toString,
          Direction.Incoming,
          ItemState.Confirmed,
          dueDate,
          dueDate.map(_.toUtcDate.toString),
          "webapp",
          dueIn.exists(_ < 0),
          dueInLabel,
          Some("Acme AG"),
          None
        )
      }
  }

  final case class Field(
      id: Ident,
      name: Ident,
      label: Option[String],
      ftype: CustomFieldType
  )
  object Field {
    implicit val jsonEncoder: Encoder[Field] = deriveEncoder

    def apply(r: RCustomField): Field =
      Field(r.id, r.name, r.label, r.ftype)

    def sample[F[_]: Sync](id: Ident): F[Field] =
      Sync[F].delay(Field(id, Ident.unsafe("chf"), Some("CHF"), CustomFieldType.Money))
  }
}
