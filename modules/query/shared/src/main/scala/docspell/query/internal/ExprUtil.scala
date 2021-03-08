package docspell.query.internal

import cats.data.{NonEmptyList => Nel}

import docspell.query.ItemQuery.Expr._
import docspell.query.ItemQuery._

object ExprUtil {

  /** Does some basic transformation, like unfolding nested and trees
    * containing one value etc.
    */
  def reduce(expr: Expr): Expr =
    expr match {
      case AndExpr(inner) =>
        val nodes = spliceAnd(inner)
        if (nodes.tail.isEmpty) reduce(nodes.head)
        else AndExpr(nodes.map(reduce))

      case OrExpr(inner) =>
        val nodes = spliceOr(inner)
        if (nodes.tail.isEmpty) reduce(nodes.head)
        else OrExpr(nodes.map(reduce))

      case NotExpr(inner) =>
        inner match {
          case NotExpr(inner2) =>
            reduce(inner2)
          case InboxExpr(flag) =>
            InboxExpr(!flag)
          case DirectionExpr(flag) =>
            DirectionExpr(!flag)
          case _ =>
            expr
        }

      case m: MacroExpr =>
        reduce(m.body)

      case DirectionExpr(_) =>
        expr

      case InboxExpr(_) =>
        expr

      case InExpr(_, _) =>
        expr

      case InDateExpr(_, _) =>
        expr

      case TagsMatch(_, _) =>
        expr
      case TagIdsMatch(_, _) =>
        expr
      case Exists(_) =>
        expr
      case Fulltext(_) =>
        expr
      case SimpleExpr(_, _) =>
        expr
      case TagCategoryMatch(_, _) =>
        expr
      case CustomFieldMatch(_, _, _) =>
        expr
      case CustomFieldIdMatch(_, _, _) =>
        expr
      case ChecksumMatch(_) =>
        expr
    }

  private def spliceAnd(nodes: Nel[Expr]): Nel[Expr] =
    nodes.flatMap {
      case Expr.AndExpr(inner) =>
        spliceAnd(inner)
      case node =>
        Nel.of(node)
    }
  private def spliceOr(nodes: Nel[Expr]): Nel[Expr] =
    nodes.flatMap {
      case Expr.OrExpr(inner) =>
        spliceOr(inner)
      case node =>
        Nel.of(node)
    }
}
