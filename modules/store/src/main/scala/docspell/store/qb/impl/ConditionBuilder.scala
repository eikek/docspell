/*
 * Copyright 2020 Eike K. & Contributors
 *
 * SPDX-License-Identifier: AGPL-3.0-or-later
 */

package docspell.store.qb.impl

import cats.data.NonEmptyList

import docspell.store.qb._

import _root_.doobie.implicits._
import _root_.doobie.{Query => _, _}

object ConditionBuilder {
  val or = fr" OR"
  val and = fr" AND"
  val comma = fr","
  val parenOpen = Fragment.const0("(")
  val parenClose = Fragment.const0(")")

  final def reduce(c: Condition): Condition =
    c match {
      case Condition.And(inner) =>
        NonEmptyList.fromList(flatten(inner.toList, Condition.And.Inner)) match {
          case Some(rinner) =>
            if (rinner.tail.isEmpty) reduce(rinner.head)
            else Condition.And(rinner.reverse.map(reduce))
          case None =>
            Condition.unit
        }

      case Condition.Or(inner) =>
        NonEmptyList.fromList(flatten(inner.toList, Condition.Or.Inner)) match {
          case Some(rinner) =>
            if (rinner.tail.isEmpty) reduce(rinner.head)
            else Condition.Or(rinner.reverse.map(reduce))
          case None =>
            Condition.unit
        }

      case Condition.Not(Condition.UnitCondition) =>
        Condition.unit

      case Condition.Not(Condition.Not(inner)) =>
        reduce(inner)

      case _ =>
        c
    }

  private def flatten(
      els: List[Condition],
      nodePattern: Condition.InnerCondition,
      result: List[Condition] = Nil
  ): List[Condition] =
    els match {
      case Nil =>
        result
      case nodePattern(more) :: tail =>
        val spliced = flatten(more.toList, nodePattern, result)
        flatten(tail, nodePattern, spliced)
      case Condition.UnitCondition :: tail =>
        flatten(tail, nodePattern, result)
      case h :: tail =>
        flatten(tail, nodePattern, h :: result)
    }

  final def build(expr: Condition): Fragment =
    reduce(expr) match {
      case c @ Condition.CompareVal(col, op, value) =>
        val opFrag = operator(op)
        val valFrag = buildValue(value)(c.P)
        val colFrag = op match {
          case Operator.LowerLike =>
            lower(col)
          case Operator.LowerEq =>
            lower(col)
          case _ =>
            SelectExprBuilder.column(col)
        }
        colFrag ++ opFrag ++ valFrag

      case c @ Condition.CompareFVal(dbf, op, value) =>
        val opFrag = operator(op)
        val valFrag = buildValue(value)(c.P)
        val dbfFrag = op match {
          case Operator.LowerLike =>
            lower(dbf)
          case Operator.LowerEq =>
            lower(dbf)
          case _ =>
            SelectExprBuilder.build(dbf)
        }
        dbfFrag ++ opFrag ++ valFrag

      case Condition.CompareCol(c1, op, c2) =>
        val (c1Frag, c2Frag) = op match {
          case Operator.LowerLike =>
            (lower(c1), lower(c2))
          case Operator.LowerEq =>
            (lower(c1), lower(c2))
          case _ =>
            (SelectExprBuilder.column(c1), SelectExprBuilder.column(c2))
        }
        c1Frag ++ operator(op) ++ c2Frag

      case Condition.CompareSelect(col, op, subsel) =>
        val opFrag = operator(op)
        val colFrag = op match {
          case Operator.LowerLike =>
            lower(col)
          case Operator.LowerEq =>
            lower(col)
          case _ =>
            SelectExprBuilder.build(col)
        }
        val sub = SelectBuilder(subsel)
        colFrag ++ opFrag ++ sql"(" ++ sub ++ sql")"

      case Condition.InSubSelect(col, subsel) =>
        val sub = SelectBuilder(subsel)
        SelectExprBuilder.column(col) ++ sql" IN (" ++ sub ++ parenClose

      case c @ Condition.InValues(col, values, toLower) =>
        val cfrag = if (toLower) lower(col) else SelectExprBuilder.build(col)
        cfrag ++ sql" IN (" ++ values.toList
          .map(a => buildValue(a)(c.P))
          .reduce(_ ++ comma ++ _) ++ parenClose

      case Condition.IsNull(col) =>
        SelectExprBuilder.build(col) ++ fr" is null"

      case Condition.And(ands) =>
        val inner = ands.map(build).reduceLeft(_ ++ and ++ _)
        if (ands.tail.isEmpty) inner
        else parenOpen ++ inner ++ parenClose

      case Condition.Or(ors) =>
        val inner = ors.map(build).reduceLeft(_ ++ or ++ _)
        if (ors.tail.isEmpty) inner
        else parenOpen ++ inner ++ parenClose

      case Condition.Not(Condition.IsNull(col)) =>
        SelectExprBuilder.build(col) ++ fr" is not null"

      case Condition.Not(c) =>
        fr"NOT" ++ build(c)

      case Condition.UnitCondition =>
        Fragment.empty
    }

  def operator(op: Operator): Fragment =
    op match {
      case Operator.Eq =>
        fr" ="
      case Operator.LowerEq =>
        fr" ="
      case Operator.Neq =>
        fr" <>"
      case Operator.Gt =>
        fr" >"
      case Operator.Lt =>
        fr" <"
      case Operator.Gte =>
        fr" >="
      case Operator.Lte =>
        fr" <="
      case Operator.LowerLike =>
        fr" LIKE"
    }

  def buildValue[A: Put](v: A): Fragment =
    fr"$v"

  def buildOptValue[A: Put](v: Option[A]): Fragment =
    fr"$v"

  def lower(sel: SelectExpr): Fragment =
    Fragment.const0("LOWER(") ++ SelectExprBuilder.build(sel) ++ parenClose

  def lower(col: Column[_]): Fragment =
    Fragment.const0("LOWER(") ++ SelectExprBuilder.column(col) ++ parenClose

  def lower(dbf: DBFunction): Fragment =
    Fragment.const0("LOWER(") ++ DBFunctionBuilder.build(dbf) ++ parenClose
}
