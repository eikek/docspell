package docspell.store.qb

case class CteBind(name: TableDef, select: Select) {}

object CteBind {

  def apply(t: (TableDef, Select)): CteBind =
    CteBind(t._1, t._2)
}
