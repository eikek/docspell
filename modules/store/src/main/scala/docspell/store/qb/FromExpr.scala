package docspell.store.qb

sealed trait FromExpr

object FromExpr {

  case class From(table: Relation) extends FromExpr {
    def innerJoin(other: Relation, on: Condition): Joined =
      Joined(this, Vector(Join.InnerJoin(other, on)))

    def innerJoin(other: TableDef, on: Condition): Joined =
      innerJoin(Relation.Table(other), on)

    def leftJoin(other: Relation, on: Condition): Joined =
      Joined(this, Vector(Join.LeftJoin(other, on)))

    def leftJoin(other: TableDef, on: Condition): Joined =
      leftJoin(Relation.Table(other), on)
  }

  object From {
    def apply(td: TableDef): From =
      From(Relation.Table(td))

    def apply(select: Select, alias: String): From =
      From(Relation.SubSelect(select, alias))
  }

  case class Joined(from: From, joins: Vector[Join]) extends FromExpr {
    def innerJoin(other: Relation, on: Condition): Joined =
      Joined(from, joins :+ Join.InnerJoin(other, on))

    def innerJoin(other: TableDef, on: Condition): Joined =
      innerJoin(Relation.Table(other), on)

    def leftJoin(other: Relation, on: Condition): Joined =
      Joined(from, joins :+ Join.LeftJoin(other, on))

    def leftJoin(other: TableDef, on: Condition): Joined =
      leftJoin(Relation.Table(other), on)
  }

  sealed trait Relation
  object Relation {
    final case class Table(table: TableDef) extends Relation
    final case class SubSelect(select: Select, alias: String) extends Relation {
      def as(a: String): SubSelect =
        copy(alias = a)
    }
  }

  sealed trait Join
  object Join {
    final case class InnerJoin(table: Relation, cond: Condition) extends Join
    final case class LeftJoin(table: Relation, cond: Condition)  extends Join
  }

}
