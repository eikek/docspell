package docspell.store.queries

import cats.implicits._

import docspell.common._
import docspell.store.qb.DSL._
import docspell.store.qb._
import docspell.store.records._

import doobie._

object QCustomField {
  private val f = RCustomField.as("f")
  private val v = RCustomFieldValue.as("v")

  case class CustomFieldData(field: RCustomField, usageCount: Int)

  def findAllLike(
      coll: Ident,
      nameQuery: Option[String]
  ): ConnectionIO[Vector[CustomFieldData]] =
    findFragment(coll, nameQuery, None).build.query[CustomFieldData].to[Vector]

  def findById(field: Ident, collective: Ident): ConnectionIO[Option[CustomFieldData]] =
    findFragment(collective, None, field.some).build.query[CustomFieldData].option

  private def findFragment(
      coll: Ident,
      nameQuery: Option[String],
      fieldId: Option[Ident]
  ): Select = {
//    val fId    = RCustomField.Columns.id.prefix("f")
//    val fColl  = RCustomField.Columns.cid.prefix("f")
//    val fName  = RCustomField.Columns.name.prefix("f")
//    val fLabel = RCustomField.Columns.label.prefix("f")
//    val vField = RCustomFieldValue.Columns.field.prefix("v")
//
//    val join = RCustomField.table ++ fr"f LEFT OUTER JOIN" ++
//      RCustomFieldValue.table ++ fr"v ON" ++ fId.is(vField)
//
//    val cols = RCustomField.Columns.all.map(_.prefix("f")) :+ Column("COUNT(v.id)")
//
//    val nameCond = nameQuery.map(QueryWildcard.apply) match {
//      case Some(q) =>
//        or(fName.lowerLike(q), and(fLabel.isNotNull, fLabel.lowerLike(q)))
//      case None =>
//        Fragment.empty
//    }
//    val fieldCond = fieldId match {
//      case Some(id) =>
//        fId.is(id)
//      case None =>
//        Fragment.empty
//    }
//    val cond = and(fColl.is(coll), nameCond, fieldCond)
//
//    val group = NonEmptyList.fromList(RCustomField.Columns.all) match {
//      case Some(nel) => groupBy(nel.map(_.prefix("f")))
//      case None      => Fragment.empty
//    }
//
//    selectSimple(cols, join, cond) ++ group

    val nameFilter = nameQuery.map { q =>
      f.name.likes(q) || (f.label.isNotNull && f.label.like(q))
    }

    Select(
      f.all.map(_.s).append(count(v.id).as("num")),
      from(f).leftJoin(v, f.id === v.field),
      f.cid === coll &&? nameFilter &&? fieldId.map(fid => f.id === fid),
      GroupBy(f.all)
    )
  }
}
