package docspell.store.records

import cats.data.NonEmptyList
import cats.implicits._

import docspell.common._
import docspell.store.impl.Implicits._
import docspell.store.impl._

import doobie._
import doobie.implicits._

case class RTag(
    tagId: Ident,
    collective: Ident,
    name: String,
    category: Option[String],
    created: Timestamp
) {}

object RTag {

  val table = fr"tag"

  object Columns {
    val tid      = Column("tid")
    val cid      = Column("cid")
    val name     = Column("name")
    val category = Column("category")
    val created  = Column("created")
    val all      = List(tid, cid, name, category, created)
  }
  import Columns._

  def insert(v: RTag): ConnectionIO[Int] = {
    val sql =
      insertRow(
        table,
        all,
        fr"${v.tagId},${v.collective},${v.name},${v.category},${v.created}"
      )
    sql.update.run
  }

  def update(v: RTag): ConnectionIO[Int] = {
    val sql = updateRow(
      table,
      and(tid.is(v.tagId), cid.is(v.collective)),
      commas(
        cid.setTo(v.collective),
        name.setTo(v.name),
        category.setTo(v.category)
      )
    )
    sql.update.run
  }

  def findById(id: Ident): ConnectionIO[Option[RTag]] = {
    val sql = selectSimple(all, table, tid.is(id))
    sql.query[RTag].option
  }

  def findByIdAndCollective(id: Ident, coll: Ident): ConnectionIO[Option[RTag]] = {
    val sql = selectSimple(all, table, and(tid.is(id), cid.is(coll)))
    sql.query[RTag].option
  }

  def existsByName(tag: RTag): ConnectionIO[Boolean] = {
    val sql = selectCount(
      tid,
      table,
      and(cid.is(tag.collective), name.is(tag.name), category.is(tag.category))
    )
    sql.query[Int].unique.map(_ > 0)
  }

  def findAll(
      coll: Ident,
      nameQ: Option[String],
      order: Columns.type => Column
  ): ConnectionIO[Vector[RTag]] = {
    val q = Seq(cid.is(coll)) ++ (nameQ match {
      case Some(str) => Seq(name.lowerLike(s"%${str.toLowerCase}%"))
      case None      => Seq.empty
    })
    val sql = selectSimple(all, table, and(q)) ++ orderBy(order(Columns).f)
    sql.query[RTag].to[Vector]
  }

  def findAllById(ids: List[Ident]): ConnectionIO[Vector[RTag]] =
    selectSimple(all, table, tid.isIn(ids.map(id => sql"$id").toSeq))
      .query[RTag]
      .to[Vector]

  def findByItem(itemId: Ident): ConnectionIO[Vector[RTag]] = {
    val rcol = all.map(_.prefix("t"))
    (selectSimple(
      rcol,
      table ++ fr"t," ++ RTagItem.table ++ fr"i",
      and(
        RTagItem.Columns.itemId.prefix("i").is(itemId),
        RTagItem.Columns.tagId.prefix("i").is(tid.prefix("t"))
      )
    ) ++ orderBy(name.prefix("t").asc)).query[RTag].to[Vector]
  }

  def findAllByNameOrId(
      nameOrIds: List[String],
      coll: Ident
  ): ConnectionIO[Vector[RTag]] = {
    val idList =
      NonEmptyList.fromList(nameOrIds.flatMap(s => Ident.fromString(s).toOption)).toSeq
    val nameList = NonEmptyList.fromList(nameOrIds.map(_.toLowerCase)).toSeq

    val cond = idList.flatMap(ids => Seq(tid.isIn(ids))) ++
      nameList.flatMap(ns => Seq(name.isLowerIn(ns)))

    if (cond.isEmpty) Vector.empty.pure[ConnectionIO]
    else selectSimple(all, table, and(cid.is(coll), or(cond))).query[RTag].to[Vector]
  }

  def delete(tagId: Ident, coll: Ident): ConnectionIO[Int] =
    deleteFrom(table, and(tid.is(tagId), cid.is(coll))).update.run
}
