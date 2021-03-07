package docspell.query

import cats._
import cats.implicits._

import docspell.query.ItemQuery.Expr.AndExpr
import docspell.query.ItemQuery.Expr.NotExpr
import docspell.query.ItemQuery.Expr.OrExpr
import docspell.query.ItemQuery._

/** Currently, fulltext in a query is only supported when in "root
  * AND" position
  */
object FulltextExtract {

  sealed trait Result
  sealed trait SuccessResult extends Result
  sealed trait FailureResult extends Result
  object Result {
    case class Success(query: Expr, fts: Option[String]) extends SuccessResult
    case object TooMany                                  extends FailureResult
    case object UnsupportedPosition                      extends FailureResult
  }

  def findFulltext(expr: Expr): Result =
    lookForFulltext(expr)

  private def lookForFulltext(expr: Expr): Result =
    expr match {
      case Expr.Fulltext(ftq) =>
        Result.Success(ItemQuery.all.expr, ftq.some)
      case Expr.AndExpr(inner) =>
        inner.collect({ case Expr.Fulltext(fq) => fq }) match {
          case Nil =>
            checkPosition(expr, 0)
          case e :: Nil =>
            val c = foldMap(isFulltextExpr)(expr)
            if (c > 1) Result.TooMany
            else Result.Success(expr, e.some)
          case _ =>
            Result.TooMany
        }
      case _ =>
        checkPosition(expr, 0)
    }

  private def checkPosition(expr: Expr, max: Int): Result = {
    val c = foldMap(isFulltextExpr)(expr)
    if (c > max) Result.UnsupportedPosition
    else Result.Success(expr, None)
  }

  private def foldMap[B: Monoid](f: Expr => B)(expr: Expr): B =
    expr match {
      case OrExpr(inner) =>
        inner.map(foldMap(f)).fold
      case AndExpr(inner) =>
        inner.map(foldMap(f)).fold
      case NotExpr(e) =>
        f(e)
      case _ =>
        f(expr)
    }

  private def isFulltextExpr(expr: Expr): Int =
    expr match {
      case Expr.Fulltext(_) => 1
      case _                => 0
    }

}
