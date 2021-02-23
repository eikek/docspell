package docspell.query

sealed trait Date
object Date {
  def apply(y: Int, m: Int, d: Int): Date =
    Local(y, m, d)

  def apply(ms: Long): Date =
    Millis(ms)

  final case class Local(year: Int, month: Int, day: Int) extends Date

  final case class Millis(ms: Long) extends Date
}
