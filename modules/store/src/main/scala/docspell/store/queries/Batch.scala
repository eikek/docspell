package docspell.store.queries

case class Batch(offset: Int, limit: Int) {
  def restrictLimitTo(n: Int): Batch =
    Batch(offset, math.min(n, limit))

  def next: Batch =
    Batch(offset + limit, limit)

  def first: Batch =
    Batch(0, limit)
}

object Batch {
  val all: Batch = Batch(0, Int.MaxValue)

  def page(n: Int, size: Int): Batch =
    Batch(n * size, size)

  def limit(c: Int): Batch =
    Batch(0, c)
}
