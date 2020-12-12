package docspell.store.qb.impl

import docspell.store.qb._

import doobie._
import doobie.implicits._

trait CommonBuilder {
  def column(col: Column[_]): Fragment = {
    val prefix = col.table.alias.getOrElse(col.table.tableName)
    if (prefix.isEmpty) columnNoPrefix(col)
    else Fragment.const0(prefix) ++ Fragment.const0(".") ++ Fragment.const0(col.name)
  }

  def columnNoPrefix(col: Column[_]): Fragment =
    Fragment.const0(col.name)

  def appendAs(alias: Option[String]): Fragment =
    alias.map(a => fr" AS" ++ Fragment.const(a)).getOrElse(Fragment.empty)
}
