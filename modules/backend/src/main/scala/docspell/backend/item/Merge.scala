/*
 * Copyright 2020 Eike K. & Contributors
 *
 * SPDX-License-Identifier: AGPL-3.0-or-later
 */

package docspell.backend.item

import cats.data.EitherT
import cats.data.NonEmptyList
import cats.effect._
import cats.implicits._

import docspell.backend.fulltext.CreateIndex
import docspell.backend.ops.OItem
import docspell.common._
import docspell.logging.Logger
import docspell.store.Store
import docspell.store.queries.QCustomField
import docspell.store.queries.QCustomField.FieldValue
import docspell.store.records._

trait Merge[F[_]] {
  def merge(items: NonEmptyList[Ident], collective: CollectiveId): F[Merge.Result[RItem]]
}

object Merge {

  type Result[A] = Either[Error, A]
  sealed trait Error
  object Error {
    final case object NoItems extends Error
    def noItems: Error = NoItems

  }

  def apply[F[_]: Async](
      logger: Logger[F],
      store: Store[F],
      itemOps: OItem[F],
      createIndex: CreateIndex[F]
  ): Merge[F] =
    new Merge[F] {
      def merge(
          givenIds: NonEmptyList[Ident],
          collective: CollectiveId
      ): F[Result[RItem]] =
        (for {
          items <- loadItems(givenIds, collective)
          ids = items.map(_.id)
          target = moveMainData(items)
          _ <- EitherT.right[Error](store.transact(RItem.updateAll(target)))
          _ <- EitherT.right[Error](moveTags(ids))
          _ <- EitherT.right[Error](moveCustomFields(ids))
          _ <- EitherT.right[Error](moveAttachments(ids))
          _ <- EitherT.right[Error](moveSentMails(ids))
          _ <- EitherT.right[Error](
            createIndex
              .reIndexData(logger, collective.some, NonEmptyList.one(ids.head).some, 50)
          )
          _ <- EitherT.right[Error](
            NonEmptyList.fromList(items.tail.map(_.id)) match {
              case Some(nel) => itemOps.deleteItemMultiple(nel, collective)
              case None      => 0.pure[F]
            }
          )
        } yield target).value

      def loadItems(
          items: NonEmptyList[Ident],
          collective: CollectiveId
      ): EitherT[F, Error, NonEmptyList[RItem]] = {
        val loaded =
          store
            .transact(
              items.toList.traverse(id => RItem.findByIdAndCollective(id, collective))
            )
            .map(_.flatten)
            .map(NonEmptyList.fromList)
        EitherT.fromOptionF(loaded, Error.NoItems)
      }

      def moveAttachments(items: NonEmptyList[Ident]): F[Int] = {
        val target = items.head
        for {
          nextPos <- store.transact(RAttachment.nextPosition(target))
          attachs <- store.transact(items.tail.traverse(id => RAttachment.findByItem(id)))
          attachFlat = attachs.flatMap(_.toList)
          n <- attachFlat.zipWithIndex.traverse { case (a, idx) =>
            store.transact(RAttachment.updateItemId(a.id, target, nextPos + idx))
          }
        } yield n.sum
      }

      def moveTags(items: NonEmptyList[Ident]): F[Int] = {
        val target = items.head
        items.tail
          .traverse(id => store.transact(RTagItem.moveTags(id, target)))
          .map(_.sum)
      }

      def moveMainData(items: NonEmptyList[RItem]): RItem =
        items.tail.foldLeft(items.head)(combine)

      def moveCustomFields(items: NonEmptyList[Ident]): F[Unit] =
        for {
          values <- store.transact(QCustomField.findAllValues(items))
          byField = values.groupBy(_.field.name)
          newValues = mergeFields(items.head, byField)
          _ <- newValues.traverse(fv =>
            store.transact(RCustomField.setValue(fv.field, items.head, fv.value))
          )
        } yield ()

      def moveSentMails(items: NonEmptyList[Ident]): F[Int] =
        NonEmptyList.fromList(items.tail) match {
          case Some(others) =>
            store.transact(RSentMailItem.moveToItem(items.head, others))
          case None =>
            0.pure[F]
        }
    }

  private def mergeFields(
      targetId: Ident,
      byField: Map[Ident, List[FieldValue]]
  ): List[FieldValue] =
    byField
      .filter(kv => kv._1 != targetId || kv._2.size > 1)
      .values
      .flatMap(NonEmptyList.fromList)
      .map { nel =>
        if (nel.tail.isEmpty) nel.head
        else mergeFieldSameName(nel)
      }
      .toList

  private def mergeFieldSameName(fields: NonEmptyList[FieldValue]): FieldValue =
    fields.head.field.ftype match {
      case CustomFieldType.Bool => fields.head
      case CustomFieldType.Date => fields.head
      case CustomFieldType.Money =>
        val amount =
          fields.toList
            .flatMap(fv => CustomFieldType.Money.parseValue(fv.value).toOption)
            .toList
            .sum
        fields.head.copy(value = CustomFieldType.Money.valueString(amount))

      case CustomFieldType.Numeric =>
        val amount =
          fields.toList
            .flatMap(fv => CustomFieldType.Numeric.parseValue(fv.value).toOption)
            .toList
            .sum
        fields.head.copy(value = CustomFieldType.Numeric.valueString(amount))

      case CustomFieldType.Text =>
        val text = fields.toList
          .flatMap(fv => CustomFieldType.Text.parseValue(fv.value).toOption)
          .mkString(", ")
        fields.head.copy(value = CustomFieldType.Text.valueString(text))
    }

  private def combine(target: RItem, source: RItem): RItem =
    MoveProp
      .all(
        MoveProp.whenNotExists(_.itemDate)((i, v) => i.copy(itemDate = v)),
        MoveProp.whenNotExists(_.corrPerson)((i, v) => i.copy(corrPerson = v)),
        MoveProp.whenNotExists(_.concPerson)((i, v) => i.copy(concPerson = v)),
        MoveProp.whenNotExists(_.concEquipment)((i, v) => i.copy(concEquipment = v)),
        MoveProp.whenNotExists(_.dueDate)((i, v) => i.copy(dueDate = v)),
        MoveProp.whenNotExists(_.folderId)((i, v) => i.copy(folderId = v)),
        MoveProp.concat(_.notes)((i, v) => i.copy(notes = v))
      )
      .move(target, source)

  trait MoveProp {
    def move(target: RItem, source: RItem): RItem
  }
  object MoveProp {
    def whenNotExists[A](
        get: RItem => Option[A]
    )(set: (RItem, Option[A]) => RItem): MoveProp =
      new MoveProp {
        def move(target: RItem, source: RItem): RItem =
          get(target) match {
            case Some(_) => target
            case None    => set(target, get(source))
          }
      }

    def concat(
        get: RItem => Option[String]
    )(set: (RItem, Option[String]) => RItem): MoveProp =
      new MoveProp {
        def move(target: RItem, source: RItem): RItem =
          (get(target), get(source)) match {
            case (Some(st), Some(ss)) => set(target, Some(st + "\n\n" + ss))
            case (Some(_), None)      => target
            case (None, src)          => set(target, src)
          }
      }

    def all(props: MoveProp*): MoveProp =
      new MoveProp {
        def move(target: RItem, source: RItem): RItem =
          props.foldLeft(target) { (el, move) =>
            move.move(el, source)
          }
      }
  }
}
