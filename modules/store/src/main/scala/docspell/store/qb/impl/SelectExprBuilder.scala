package docspell.store.qb.impl

import docspell.store.qb._

import _root_.doobie.{Query => _, _}

object SelectExprBuilder extends CommonBuilder {

  def build(expr: SelectExpr): Fragment =
    expr match {
      case SelectExpr.SelectColumn(col, alias) =>
        column(col) ++ appendAs(alias)

      case s @ SelectExpr.SelectLit(value, aliasOpt) =>
        ConditionBuilder.buildValue(value)(s.P) ++ appendAs(aliasOpt)

      case SelectExpr.SelectFun(fun, alias) =>
        DBFunctionBuilder.build(fun) ++ appendAs(alias)

    }

}
