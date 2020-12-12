package docspell.store.qb

import docspell.store.qb.impl._

import doobie._
import doobie.implicits._

object DML {
  private val comma = fr","

  def delete(table: TableDef, cond: Condition): ConnectionIO[Int] =
    deleteFragment(table, cond).update.run

  def deleteFragment(table: TableDef, cond: Condition): Fragment =
    fr"DELETE FROM" ++ FromExprBuilder.buildTable(table) ++ fr"WHERE" ++ ConditionBuilder
      .build(cond)

  def insert(table: TableDef, cols: Seq[Column[_]], values: Fragment): ConnectionIO[Int] =
    insertFragment(table, cols, List(values)).update.run

  def insertMany(
      table: TableDef,
      cols: Seq[Column[_]],
      values: Seq[Fragment]
  ): ConnectionIO[Int] =
    insertFragment(table, cols, values).update.run

  def insertFragment(
      table: TableDef,
      cols: Seq[Column[_]],
      values: Seq[Fragment]
  ): Fragment =
    fr"INSERT INTO" ++ FromExprBuilder.buildTable(table) ++ sql"(" ++
      cols
        .map(SelectExprBuilder.columnNoPrefix)
        .reduce(_ ++ comma ++ _) ++ fr") VALUES" ++
      values.map(f => sql"(" ++ f ++ sql")").reduce(_ ++ comma ++ _)

  def update(
      table: TableDef,
      cond: Condition,
      setter: Seq[Setter[_]]
  ): ConnectionIO[Int] =
    updateFragment(table, Some(cond), setter).update.run

  def updateFragment(
      table: TableDef,
      cond: Option[Condition],
      setter: Seq[Setter[_]]
  ): Fragment = {
    val condFrag = cond.map(SelectBuilder.cond).getOrElse(Fragment.empty)
    fr"UPDATE" ++ FromExprBuilder.buildTable(table) ++ fr"SET" ++
      setter
        .map(s => buildSetter(s))
        .reduce(_ ++ comma ++ _) ++
      condFrag
  }

  private def buildSetter[A](setter: Setter[A]): Fragment =
    setter match {
      case s @ Setter.SetValue(column, value) =>
        SelectExprBuilder.columnNoPrefix(column) ++ fr" =" ++ ConditionBuilder.buildValue(
          value
        )(s.P)

      case s @ Setter.SetOptValue(column, optValue) =>
        SelectExprBuilder.columnNoPrefix(column) ++ fr" =" ++ ConditionBuilder
          .buildOptValue(
            optValue
          )(s.P)

      case Setter.Increment(column, amount) =>
        val colFrag = SelectExprBuilder.columnNoPrefix(column)
        colFrag ++ fr" =" ++ colFrag ++ fr" + $amount"
    }

  def set(s: Setter[_], more: Setter[_]*): Seq[Setter[_]] =
    more :+ s
}
