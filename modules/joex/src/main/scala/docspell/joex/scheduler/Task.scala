package docspell.joex.scheduler

import cats.implicits._
import cats.{Applicative, ApplicativeError, FlatMap, Functor}
import cats.data.Kleisli
import cats.effect.Sync
import docspell.common.Logger

/**
  * The code that is executed by the scheduler
  */
trait Task[F[_], A, B] {

  def run(ctx: Context[F, A]): F[B]

  def map[C](f: B => C)(implicit F: Functor[F]): Task[F, A, C] =
    Task(Task.toKleisli(this).map(f))

  def flatMap[C](f: B => Task[F, A, C])(implicit F: FlatMap[F]): Task[F, A, C] =
    Task(Task.toKleisli(this).flatMap(a => Task.toKleisli(f(a))))

  def andThen[C](f: B => F[C])(implicit F: FlatMap[F]): Task[F, A, C] =
    Task(Task.toKleisli(this).andThen(f))

  def mapF[C](f: F[B] => F[C]): Task[F, A, C] =
    Task(Task.toKleisli(this).mapF(f))

  def attempt(
      implicit F: ApplicativeError[F, Throwable]
  ): Task[F, A, Either[Throwable, B]] =
    mapF(_.attempt)

  def contramap[C](f: C => F[A])(implicit F: FlatMap[F]): Task[F, C, B] = {
    ctxc: Context[F, C] => f(ctxc.args).flatMap(a => run(ctxc.map(_ => a)))
  }
}

object Task {

  def pure[F[_]: Applicative, A, B](b: B): Task[F, A, B] =
    Task(_ => b.pure[F])

  def of[F[_], A, B](b: F[B]): Task[F, A, B] =
    Task(_ => b)

  def apply[F[_], A, B](f: Context[F, A] => F[B]): Task[F, A, B] =
    (ctx: Context[F, A]) => f(ctx)

  def apply[F[_], A, B](k: Kleisli[F, Context[F, A], B]): Task[F, A, B] =
    c => k.run(c)

  def toKleisli[F[_], A, B](t: Task[F, A, B]): Kleisli[F, Context[F, A], B] =
    Kleisli(t.run)

  def setProgress[F[_]: Sync, A, B](n: Int)(data: B): Task[F, A, B] =
    Task(_.setProgress(n).map(_ => data))

  def log[F[_], A](f: Logger[F] => F[Unit]): Task[F, A, Unit] =
    Task(ctx => f(ctx.logger))
}
