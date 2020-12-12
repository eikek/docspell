package docspell.store.qb

case class GroupBy(name: SelectExpr, names: Vector[SelectExpr], having: Option[Condition])

object GroupBy {

  def apply(c: Column[_], cs: Column[_]*): GroupBy =
    GroupBy(
      SelectExpr.SelectColumn(c, None),
      cs.toVector.map(c => SelectExpr.SelectColumn(c, None)),
      None
    )
}
