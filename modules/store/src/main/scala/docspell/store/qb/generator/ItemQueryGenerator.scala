package docspell.store.qb.generator

import java.time.Instant
import java.time.LocalDate

import cats.data.{NonEmptyList => Nel}

import docspell.common._
import docspell.query.ItemQuery._
import docspell.query.{Date, ItemQuery}
import docspell.store.qb.DSL._
import docspell.store.qb.{Operator => QOp, _}
import docspell.store.queries.QItem
import docspell.store.queries.QueryWildcard
import docspell.store.records._

import doobie.util.Put

object ItemQueryGenerator {

  def apply(today: LocalDate, tables: Tables, coll: Ident)(q: ItemQuery)(implicit
      PT: Put[Timestamp]
  ): Condition =
    fromExpr(today, tables, coll)(q.expr)

  final def fromExpr(today: LocalDate, tables: Tables, coll: Ident)(
      expr: Expr
  )(implicit PT: Put[Timestamp]): Condition =
    expr match {
      case Expr.AndExpr(inner) =>
        Condition.And(inner.map(fromExpr(today, tables, coll)))

      case Expr.OrExpr(inner) =>
        Condition.Or(inner.map(fromExpr(today, tables, coll)))

      case Expr.NotExpr(inner) =>
        inner match {
          case Expr.Exists(notExists) =>
            anyColumn(tables)(notExists).isNull

          case Expr.TagIdsMatch(op, tags) =>
            val ids = tags.toList.flatMap(s => Ident.fromString(s).toOption)
            Nel
              .fromList(ids)
              .map { nel =>
                op match {
                  case TagOperator.AnyMatch =>
                    tables.item.id.notIn(TagItemName.itemsWithEitherTag(nel))
                  case TagOperator.AllMatch =>
                    tables.item.id.notIn(TagItemName.itemsWithAllTags(nel))
                }
              }
              .getOrElse(Condition.unit)
          case Expr.TagsMatch(op, tags) =>
            op match {
              case TagOperator.AllMatch =>
                tables.item.id.notIn(TagItemName.itemsWithAllTagNameOrIds(tags))

              case TagOperator.AnyMatch =>
                tables.item.id.notIn(TagItemName.itemsWithEitherTagNameOrIds(tags))
            }

          case Expr.TagCategoryMatch(op, cats) =>
            op match {
              case TagOperator.AllMatch =>
                tables.item.id.notIn(TagItemName.itemsInAllCategories(cats))

              case TagOperator.AnyMatch =>
                tables.item.id.notIn(TagItemName.itemsInEitherCategory(cats))
            }

          case Expr.Fulltext(_) =>
            Condition.unit

          case _ =>
            Condition.Not(fromExpr(today, tables, coll)(inner))
        }

      case Expr.Exists(field) =>
        anyColumn(tables)(field).isNotNull

      case Expr.SimpleExpr(op, Property.StringProperty(attr, value)) =>
        val col = stringColumn(tables)(attr)
        op match {
          case Operator.Like =>
            Condition.CompareVal(col, makeOp(op), QueryWildcard.lower(value))
          case _ =>
            Condition.CompareVal(col, makeOp(op), value)
        }

      case Expr.SimpleExpr(op, Property.DateProperty(attr, value)) =>
        val dt       = dateToTimestamp(today)(value)
        val col      = timestampColumn(tables)(attr)
        val noLikeOp = if (op == Operator.Like) Operator.Eq else op
        Condition.CompareFVal(col, makeOp(noLikeOp), dt)

      case Expr.SimpleExpr(op, Property.IntProperty(attr, value)) =>
        val col = intColumn(tables)(attr)
        Condition.CompareVal(col, makeOp(op), value)

      case Expr.InExpr(attr, values) =>
        val col = stringColumn(tables)(attr)
        if (values.tail.isEmpty) col === values.head
        else col.in(values)

      case Expr.InDateExpr(attr, values) =>
        val col = timestampColumn(tables)(attr)
        val dts = values.map(dateToTimestamp(today))
        if (values.tail.isEmpty) col === dts.head
        else col.in(dts)

      case Expr.DirectionExpr(incoming) =>
        if (incoming) tables.item.incoming === Direction.Incoming
        else tables.item.incoming === Direction.Outgoing

      case Expr.InboxExpr(flag) =>
        if (flag) tables.item.state === ItemState.created
        else tables.item.state === ItemState.confirmed

      case Expr.ValidItemStates =>
        tables.item.state.in(ItemState.validStates)

      case Expr.TagIdsMatch(op, tags) =>
        val ids = tags.toList.flatMap(s => Ident.fromString(s).toOption)
        Nel
          .fromList(ids)
          .map { nel =>
            op match {
              case TagOperator.AnyMatch =>
                tables.item.id.in(TagItemName.itemsWithEitherTag(nel))
              case TagOperator.AllMatch =>
                tables.item.id.in(TagItemName.itemsWithAllTags(nel))
            }
          }
          .getOrElse(Condition.unit)

      case Expr.TagsMatch(op, tags) =>
        op match {
          case TagOperator.AllMatch =>
            tables.item.id.in(TagItemName.itemsWithAllTagNameOrIds(tags))

          case TagOperator.AnyMatch =>
            tables.item.id.in(TagItemName.itemsWithEitherTagNameOrIds(tags))
        }

      case Expr.TagCategoryMatch(op, cats) =>
        op match {
          case TagOperator.AllMatch =>
            tables.item.id.in(TagItemName.itemsInAllCategories(cats))

          case TagOperator.AnyMatch =>
            tables.item.id.in(TagItemName.itemsInEitherCategory(cats))
        }

      case Expr.CustomFieldMatch(field, op, value) =>
        tables.item.id.in(
          itemsWithCustomField(_.name ==== field)(coll, makeOp(op), value)
        )

      case Expr.CustomFieldIdMatch(field, op, value) =>
        tables.item.id.in(itemsWithCustomField(_.id ==== field)(coll, makeOp(op), value))

      case Expr.ChecksumMatch(checksum) =>
        val select = QItem.findByChecksumQuery(checksum, coll, Set.empty)
        tables.item.id.in(select.withSelect(Nel.of(RItem.as("i").id.s)))

      case Expr.AttachId(id) =>
        tables.item.id.in(
          Select(
            select(RAttachment.T.itemId),
            from(RAttachment.T),
            RAttachment.T.id.cast[String] === id
          ).distinct
        )

      case Expr.Fulltext(_) =>
        // not supported here
        Condition.unit

      case _: Expr.MacroExpr =>
        Condition.unit
    }

  private def dateToTimestamp(today: LocalDate)(date: Date): Timestamp =
    date match {
      case d: Date.DateLiteral =>
        val ld = dateLiteralToDate(today)(d)
        Timestamp.atUtc(ld.atStartOfDay)
      case Date.Calc(date, c, period) =>
        val ld = c match {
          case Date.CalcDirection.Plus =>
            dateLiteralToDate(today)(date).plus(period)
          case Date.CalcDirection.Minus =>
            dateLiteralToDate(today)(date).minus(period)
        }
        Timestamp.atUtc(ld.atStartOfDay())
    }

  private def dateLiteralToDate(today: LocalDate)(dateLit: Date.DateLiteral): LocalDate =
    dateLit match {
      case Date.Local(date) =>
        date
      case Date.Millis(ms) =>
        Instant.ofEpochMilli(ms).atZone(Timestamp.UTC).toLocalDate()
      case Date.Today =>
        today
    }

  private def anyColumn(tables: Tables)(attr: Attr): SelectExpr =
    attr match {
      case s: Attr.StringAttr =>
        stringColumn(tables)(s).s
      case t: Attr.DateAttr =>
        timestampColumn(tables)(t)
      case n: Attr.IntAttr =>
        intColumn(tables)(n).s
    }

  private def timestampColumn(tables: Tables)(attr: Attr.DateAttr): SelectExpr =
    attr match {
      case Attr.Date =>
        coalesce(tables.item.itemDate.s, tables.item.created.s).s
      case Attr.DueDate =>
        tables.item.dueDate.s
    }

  private def stringColumn(tables: Tables)(attr: Attr.StringAttr): Column[String] =
    attr match {
      case Attr.ItemId                   => tables.item.id.cast[String]
      case Attr.ItemName                 => tables.item.name
      case Attr.ItemSource               => tables.item.source
      case Attr.ItemNotes                => tables.item.notes
      case Attr.Correspondent.OrgId      => tables.corrOrg.oid.cast[String]
      case Attr.Correspondent.OrgName    => tables.corrOrg.name
      case Attr.Correspondent.PersonId   => tables.corrPers.pid.cast[String]
      case Attr.Correspondent.PersonName => tables.corrPers.name
      case Attr.Concerning.PersonId      => tables.concPers.pid.cast[String]
      case Attr.Concerning.PersonName    => tables.concPers.name
      case Attr.Concerning.EquipId       => tables.concEquip.eid.cast[String]
      case Attr.Concerning.EquipName     => tables.concEquip.name
      case Attr.Folder.FolderId          => tables.folder.id.cast[String]
      case Attr.Folder.FolderName        => tables.folder.name
    }

  private def intColumn(tables: Tables)(attr: Attr.IntAttr): Column[Int] =
    attr match {
      case Attr.AttachCount => tables.attachCount.num
    }

  private def makeOp(operator: Operator): QOp =
    operator match {
      case Operator.Eq =>
        QOp.Eq
      case Operator.Neq =>
        QOp.Neq
      case Operator.Like =>
        QOp.LowerLike
      case Operator.Gt =>
        QOp.Gt
      case Operator.Lt =>
        QOp.Lt
      case Operator.Gte =>
        QOp.Gte
      case Operator.Lte =>
        QOp.Lte
    }

  private def itemsWithCustomField(
      sel: RCustomField.Table => Condition
  )(coll: Ident, op: QOp, value: String): Select = {
    val cf  = RCustomField.as("cf")
    val cfv = RCustomFieldValue.as("cfv")

    val baseSelect =
      Select(
        select(cfv.itemId),
        from(cfv).innerJoin(cf, sel(cf) && cf.cid === coll && cf.id === cfv.field)
      )

    if (op == QOp.LowerLike) {
      val v = QueryWildcard.lower(value)
      baseSelect.where(Condition.CompareVal(cfv.value, op, v))
    } else {
      val stringCmp =
        Condition.CompareVal(cfv.value, op, value)

      value.toDoubleOption
        .map { n =>
          val numericCmp = Condition.CompareFVal(castNumeric(cfv.value.s).s, op, n)
          val fieldIsNumeric =
            cf.ftype === CustomFieldType.Numeric || cf.ftype === CustomFieldType.Money
          val fieldNotNumeric =
            cf.ftype <> CustomFieldType.Numeric && cf.ftype <> CustomFieldType.Money
          baseSelect.where(
            (fieldIsNumeric && numericCmp) || (fieldNotNumeric && stringCmp)
          )
        }
        .getOrElse(baseSelect.where(stringCmp))
    }
  }

}
