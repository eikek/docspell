package docspell.store.qb

sealed trait DBFunction {
  def alias: String

  def as(alias: String): DBFunction
}

object DBFunction {

  def countAllAs(alias: String) =
    CountAll(alias)

  def countAs[A](column: Column[A], alias: String): DBFunction =
    Count(column, alias)

  case class CountAll(alias: String) extends DBFunction {
    def as(a: String) =
      copy(alias = a)
  }

  case class Count(column: Column[_], alias: String) extends DBFunction {
    def as(a: String) =
      copy(alias = a)
  }
}
