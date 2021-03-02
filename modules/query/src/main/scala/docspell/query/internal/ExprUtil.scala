package docspell.query.internal

import docspell.query.ItemQuery.Expr._
import docspell.query.ItemQuery._

object ExprUtil {

  /** Does some basic transformation, like unfolding deeply nested and
    * trees containing one value etc.
    */
  def reduce(expr: Expr): Expr =
    expr match {
      case AndExpr(inner) =>
        if (inner.tail.isEmpty) reduce(inner.head)
        else AndExpr(inner.map(reduce))

      case OrExpr(inner) =>
        if (inner.tail.isEmpty) reduce(inner.head)
        else OrExpr(inner.map(reduce))

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
    }
}
