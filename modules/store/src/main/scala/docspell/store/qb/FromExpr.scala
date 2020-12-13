package docspell.store.qb

sealed trait FromExpr

object FromExpr {

  case class From(table: TableDef) extends FromExpr {
    def innerJoin(other: TableDef, on: Condition): Joined =
      Joined(this, Vector(Join.InnerJoin(other, on)))

    def leftJoin(other: TableDef, on: Condition): Joined =
      Joined(this, Vector(Join.LeftJoin(other, on)))
  }

  case class Joined(from: From, joins: Vector[Join]) extends FromExpr {
    def innerJoin(other: TableDef, on: Condition): Joined =
      Joined(from, joins :+ Join.InnerJoin(other, on))

    def leftJoin(other: TableDef, on: Condition): Joined =
      Joined(from, joins :+ Join.LeftJoin(other, on))
  }

  case class SubSelect(sel: Select, name: String) extends FromExpr {
    def as(name: String): SubSelect =
      copy(name = name)
  }
}
