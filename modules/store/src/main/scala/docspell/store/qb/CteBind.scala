package docspell.store.qb

case class CteBind(name: TableDef, coldef: Vector[Column[_]], select: Select) {}

object CteBind {

  def apply(t: (TableDef, Select)): CteBind =
    CteBind(t._1, Vector.empty, t._2)

  def apply(name: TableDef, col: Column[_], cols: Column[_]*)(select: Select): CteBind =
    CteBind(name, cols.toVector.prepended(col), select)
}
