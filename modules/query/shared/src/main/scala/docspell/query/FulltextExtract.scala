/*
 * Copyright 2020 Docspell Contributors
 *
 * SPDX-License-Identifier: GPL-3.0-or-later
 */

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
  sealed trait SuccessResult extends Result {
    def getFulltextPart: Option[String]
    def getExprPart: Option[Expr]
  }
  sealed trait FailureResult extends Result
  object Result {
    final case class SuccessNoFulltext(query: Expr) extends SuccessResult {
      val getExprPart     = Some(query)
      val getFulltextPart = None
    }
    final case class SuccessNoExpr(fts: String) extends SuccessResult {
      val getExprPart     = None
      val getFulltextPart = Some(fts)
    }
    final case class SuccessBoth(query: Expr, fts: String) extends SuccessResult {
      val getExprPart     = Some(query)
      val getFulltextPart = Some(fts)
    }
    final case object TooMany             extends FailureResult
    final case object UnsupportedPosition extends FailureResult
  }

  def findFulltext(expr: Expr): Result =
    lookForFulltext(expr)

  /** Extracts the fulltext node from the given expr and returns it
    * together with the expr without that node.
    */
  private def lookForFulltext(expr: Expr): Result =
    expr match {
      case Expr.Fulltext(ftq) =>
        Result.SuccessNoExpr(ftq)
      case Expr.AndExpr(inner) =>
        inner.collect({ case Expr.Fulltext(fq) => fq }) match {
          case Nil =>
            checkPosition(expr, 0)
          case e :: Nil =>
            val c = foldMap(isFulltextExpr)(expr)
            if (c > 1) Result.TooMany
            else Result.SuccessBoth(expr, e)
          case _ =>
            Result.TooMany
        }
      case _ =>
        checkPosition(expr, 0)
    }

  private def checkPosition(expr: Expr, max: Int): Result = {
    val c = foldMap(isFulltextExpr)(expr)
    if (c > max) Result.UnsupportedPosition
    else Result.SuccessNoFulltext(expr)
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
