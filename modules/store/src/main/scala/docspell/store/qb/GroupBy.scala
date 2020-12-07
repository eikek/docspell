package docspell.store.qb

case class GroupBy(name: SelectExpr, names: Vector[SelectExpr], having: Option[Condition])
