package docspell.query.internal

import cats.parse.{Parser => P}

import docspell.query.ItemQuery._

object MacroParser {
  private[this] val macroDef: P[String] =
    P.char('$') *> BasicParser.identParser <* P.char(':')

  def parser[A](macros: Map[String, P[A]]): P[A] = {
    val p: P[P[A]] = macroDef.map { name =>
      macros
        .get(name)
        .getOrElse(P.failWith(s"Unknown macro: $name"))
    }

    val px = (p ~ P.index ~ BasicParser.singleString).map { case ((pexpr, index), str) =>
      pexpr
        .parseAll(str)
        .left
        .map(err => err.copy(failedAtOffset = err.failedAtOffset + index))
    }

    P.select(px)(P.Fail)
  }

  // --- definitions of available macros

  /** Expands in an OR expression that matches name fields of item and
    * correspondent/concerning metadata.
    */
  val names: P[Expr] =
    P.string(P.anyChar.rep.void).map { input =>
      Expr.or(
        Expr.like(Attr.ItemName, input),
        Expr.like(Attr.ItemNotes, input),
        Expr.like(Attr.Correspondent.OrgName, input),
        Expr.like(Attr.Correspondent.PersonName, input),
        Expr.like(Attr.Concerning.PersonName, input),
        Expr.like(Attr.Concerning.EquipName, input)
      )
    }

  def dateRange(attr: Attr.DateAttr): P[Expr] =
    DateParser.dateRange.map { case (left, right) =>
      Expr.and(
        Expr.date(Operator.Gte, attr, left),
        Expr.date(Operator.Lte, attr, right)
      )
    }

  // --- all macro parser

  val allMacros: Map[String, P[Expr]] =
    Map(
      "names"  -> names,
      "datein" -> dateRange(Attr.Date),
      "duein"  -> dateRange(Attr.DueDate)
    )

  val all: P[Expr] =
    parser(allMacros)

}
