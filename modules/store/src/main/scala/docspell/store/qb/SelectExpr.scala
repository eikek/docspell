/*
 * Copyright 2020 Docspell Contributors
 *
 * SPDX-License-Identifier: GPL-3.0-or-later
 */

package docspell.store.qb

import doobie.Put

sealed trait SelectExpr {
  def as(alias: String): SelectExpr
}

object SelectExpr {

  case class SelectColumn(column: Column[_], alias: Option[String]) extends SelectExpr {
    def as(a: String): SelectColumn =
      copy(alias = Some(a))
  }

  case class SelectFun(fun: DBFunction, alias: Option[String]) extends SelectExpr {
    def as(a: String): SelectFun =
      copy(alias = Some(a))
  }

  case class SelectConstant[A](value: A, alias: Option[String])(implicit val P: Put[A])
      extends SelectExpr {
    def as(a: String): SelectConstant[A] =
      copy(alias = Some(a))
  }

  case class SelectLiteral(value: String, alias: Option[String]) extends SelectExpr {
    def as(a: String): SelectLiteral =
      copy(alias = Some(a))
  }

  case class SelectQuery(query: Select, alias: Option[String]) extends SelectExpr {
    def as(a: String): SelectQuery =
      copy(alias = Some(a))
  }

  case class SelectCondition(cond: Condition, alias: Option[String]) extends SelectExpr {
    def as(a: String): SelectCondition =
      copy(alias = Some(a))
  }

}
