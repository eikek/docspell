package docspell.store.impl

import cats.data.NonEmptyList

import docspell.common.Timestamp

import doobie._
import doobie.implicits._

trait DoobieSyntax {

  def groupBy(c0: Column, cs: Column*): Fragment =
    groupBy(NonEmptyList.of(c0, cs: _*))

  def groupBy(cs: NonEmptyList[Column]): Fragment =
    fr" GROUP BY " ++ commas(cs.toList.map(_.f))

  def coalesce(f0: Fragment, fs: Fragment*): Fragment =
    sql" coalesce(" ++ commas(f0 :: fs.toList) ++ sql") "

  def power2(c: Column): Fragment =
    sql"power(2," ++ c.f ++ sql")"

  def commas(fs: Seq[Fragment]): Fragment =
    fs.reduce(_ ++ Fragment.const(",") ++ _)

  def commas(fa: Fragment, fas: Fragment*): Fragment =
    commas(fa :: fas.toList)

  def and(fs: Seq[Fragment]): Fragment =
    Fragment.const(" (") ++ fs
      .filter(f => !isEmpty(f))
      .reduce(_ ++ Fragment.const(" AND ") ++ _) ++ Fragment.const(") ")

  def and(f0: Fragment, fs: Fragment*): Fragment =
    and(f0 :: fs.toList)

  def or(fs: Seq[Fragment]): Fragment =
    Fragment.const(" (") ++ fs.reduce(_ ++ Fragment.const(" OR ") ++ _) ++ Fragment.const(
      ") "
    )
  def or(f0: Fragment, fs: Fragment*): Fragment =
    or(f0 :: fs.toList)

  def where(fa: Fragment): Fragment =
    if (isEmpty(fa)) Fragment.empty
    else Fragment.const(" WHERE ") ++ fa

  def orderBy(fa: Fragment): Fragment =
    Fragment.const(" ORDER BY ") ++ fa

  def orderBy(c0: Fragment, cs: Fragment*): Fragment =
    fr"ORDER BY" ++ commas(c0 :: cs.toList)

  def updateRow(table: Fragment, where: Fragment, setter: Fragment): Fragment =
    Fragment.const("UPDATE ") ++ table ++ Fragment.const(" SET ") ++ setter ++ this.where(
      where
    )

  def insertRow(table: Fragment, cols: List[Column], vals: Fragment): Fragment =
    Fragment.const("INSERT INTO ") ++ table ++ Fragment.const(" (") ++
      commas(cols.map(_.f)) ++ Fragment.const(") VALUES (") ++ vals ++ Fragment.const(")")

  def insertRows(table: Fragment, cols: List[Column], vals: List[Fragment]): Fragment =
    Fragment.const("INSERT INTO ") ++ table ++ Fragment.const(" (") ++
      commas(cols.map(_.f)) ++ Fragment.const(") VALUES ") ++ commas(
        vals.map(f => sql"(" ++ f ++ sql")")
      )

  def selectSimple(cols: Seq[Column], table: Fragment, where: Fragment): Fragment =
    selectSimple(commas(cols.map(_.f)), table, where)

  def selectSimple(cols: Fragment, table: Fragment, where: Fragment): Fragment =
    Fragment.const("SELECT ") ++ cols ++
      Fragment.const(" FROM ") ++ table ++ this.where(where)

  def selectDistinct(cols: Seq[Column], table: Fragment, where: Fragment): Fragment =
    Fragment.const("SELECT DISTINCT ") ++ commas(cols.map(_.f)) ++
      Fragment.const(" FROM ") ++ table ++ this.where(where)

  def selectCount(col: Column, table: Fragment, where: Fragment): Fragment =
    Fragment.const("SELECT COUNT(") ++ col.f ++ Fragment.const(") FROM ") ++ table ++ this
      .where(
        where
      )

  def deleteFrom(table: Fragment, where: Fragment): Fragment =
    fr"DELETE FROM" ++ table ++ this.where(where)

  def withCTE(ps: (String, Fragment)*): Fragment = {
    val subsel: Seq[Fragment] =
      ps.map(p => Fragment.const(p._1) ++ fr"AS (" ++ p._2 ++ fr")")
    fr"WITH" ++ commas(subsel)
  }

  def isEmpty(fragment: Fragment): Boolean =
    Fragment.empty.toString() == fragment.toString()

  def currentTime: ConnectionIO[Timestamp] =
    Timestamp.current[ConnectionIO]
}

object DoobieSyntax extends DoobieSyntax
