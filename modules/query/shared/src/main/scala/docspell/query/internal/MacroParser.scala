package docspell.query.internal

import cats.parse.{Parser => P}

import docspell.query.ItemQuery._
import docspell.query.internal.{Constants => C}

object MacroParser {
  private def macroDef(name: String): P[Unit] =
    P.ignoreCase(name).soft.with1 <* P.char(':')

  private def dateRangeMacroImpl(
      name: String,
      attr: Attr.DateAttr
  ): P[Expr.DateRangeMacro] =
    (macroDef(name) *> DateParser.dateRange).map { case (left, right) =>
      Expr.DateRangeMacro(attr, left, right)
    }

  private def yearMacroImpl(name: String, attr: Attr.DateAttr): P[Expr.YearMacro] =
    (macroDef(name) *> DateParser.yearOnly).map(year => Expr.YearMacro(attr, year))

  val namesMacro: P[Expr.NamesMacro] =
    (macroDef(C.names) *> BasicParser.singleString).map(Expr.NamesMacro.apply)

  val dateRangeMacro: P[Expr.DateRangeMacro] =
    dateRangeMacroImpl(C.dateIn, Attr.Date)

  val dueDateRangeMacro: P[Expr.DateRangeMacro] =
    dateRangeMacroImpl(C.dueIn, Attr.DueDate)

  val yearDateMacro: P[Expr.YearMacro] =
    yearMacroImpl(C.year, Attr.Date)

  val corrMacro: P[Expr.CorrMacro] =
    (macroDef(C.corr) *> BasicParser.singleString).map(Expr.CorrMacro.apply)

  val concMacro: P[Expr.ConcMacro] =
    (macroDef(C.conc) *> BasicParser.singleString).map(Expr.ConcMacro.apply)

  // --- all macro parser

  val all: P[Expr] =
    P.oneOf(
      List(
        namesMacro,
        dateRangeMacro,
        dueDateRangeMacro,
        yearDateMacro,
        corrMacro,
        concMacro
      )
    )

}
