package docspell.query.internal

import cats.parse.{Parser => P}

import docspell.query.ItemQuery._

object MacroParser {
  private def macroDef(name: String): P[Unit] =
    P.char('$').soft.with1 *> P.string(name) <* P.char(':')

  private def dateRangeMacroImpl(
      name: String,
      attr: Attr.DateAttr
  ): P[Expr.DateRangeMacro] =
    (macroDef(name) *> DateParser.dateRange).map { case (left, right) =>
      Expr.DateRangeMacro(attr, left, right)
    }

  val namesMacro: P[Expr.NamesMacro] =
    (macroDef("names") *> BasicParser.singleString).map(Expr.NamesMacro.apply)

  val dateRangeMacro: P[Expr.DateRangeMacro] =
    dateRangeMacroImpl("datein", Attr.Date)

  val dueDateRangeMacro: P[Expr.DateRangeMacro] =
    dateRangeMacroImpl("duein", Attr.DueDate)

  // --- all macro parser

  val all: P[Expr] =
    P.oneOf(List(namesMacro, dateRangeMacro, dueDateRangeMacro))

}
