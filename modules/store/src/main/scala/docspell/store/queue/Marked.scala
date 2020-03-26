package docspell.store.queue

sealed trait Marked[+A] {}

object Marked {

  final case class Found[A](value: A) extends Marked[A]

  final case object NotFound extends Marked[Nothing]

  final case object NotMarkable extends Marked[Nothing]

  def found[A](v: A): Marked[A] = Found(v)
  def notFound[A]: Marked[A]    = NotFound
  def notMarkable[A]: Marked[A] = NotMarkable
}
