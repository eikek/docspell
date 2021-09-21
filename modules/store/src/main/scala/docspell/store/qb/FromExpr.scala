/*
 * Copyright 2020 Eike K. & Contributors
 *
 * SPDX-License-Identifier: AGPL-3.0-or-later
 */

package docspell.store.qb

import docspell.store.qb.FromExpr.{Joined, Relation}

sealed trait FromExpr {
  def innerJoin(other: Relation, on: Condition): Joined

  def innerJoin(other: TableDef, on: Condition): Joined =
    innerJoin(Relation.Table(other), on)

  def leftJoin(other: Relation, on: Condition): Joined

  def leftJoin(other: TableDef, on: Condition): Joined =
    leftJoin(Relation.Table(other), on)

  def leftJoin(sel: Select, alias: String, on: Condition): Joined =
    leftJoin(Relation.SubSelect(sel, alias), on)

  /** Prepends the given from expression to existing joins. It will replace the current
    * [[FromExpr.From]] value.
    *
    * If this is a [[FromExpr.From]], it is replaced by the given expression. If this is a
    * [[FromExpr.Joined]] then the given expression replaces the current `From` and the
    * joins are prepended to the existing joins.
    */
  def prepend(fe: FromExpr): FromExpr
}

object FromExpr {

  case class From(table: Relation) extends FromExpr {
    def innerJoin(other: Relation, on: Condition): Joined =
      Joined(this, Vector(Join.InnerJoin(other, on)))

    def leftJoin(other: Relation, on: Condition): Joined =
      Joined(this, Vector(Join.LeftJoin(other, on)))

    def prepend(fe: FromExpr): FromExpr =
      fe
  }

  object From {
    def apply(td: TableDef): From =
      From(Relation.Table(td))

    def apply(select: Select, alias: String): From =
      From(Relation.SubSelect(select, alias))
  }

  case class Joined(from: From, joins: Vector[Join]) extends FromExpr {
    def innerJoin(other: Relation, on: Condition): Joined =
      Joined(from, joins :+ Join.InnerJoin(other, on))

    def leftJoin(other: Relation, on: Condition): Joined =
      Joined(from, joins :+ Join.LeftJoin(other, on))

    def prepend(fe: FromExpr): FromExpr =
      fe match {
        case f: From =>
          Joined(f, joins)
        case Joined(f, js) =>
          Joined(f, js ++ joins)
      }
  }

  sealed trait Relation
  object Relation {
    final case class Table(table: TableDef) extends Relation
    final case class SubSelect(select: Select, alias: String) extends Relation {
      def as(a: String): SubSelect =
        copy(alias = a)
    }
  }

  sealed trait Join
  object Join {
    final case class InnerJoin(table: Relation, cond: Condition) extends Join
    final case class LeftJoin(table: Relation, cond: Condition)  extends Join
  }

}
