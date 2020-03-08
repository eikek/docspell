package docspell.store.queue

import cats.effect._
import cats.implicits._
import fs2.Stream
import docspell.common._
import docspell.store.Store
import docspell.store.records._

trait PeriodicTaskStore[F[_]] {

  /** Get the free periodic task due next and reserve it to the given
    * worker.
    *
    * If found, the task is returned and resource finalization takes
    * care of unmarking the task after use and updating `nextRun` with
    * the next timestamp.
    */
  def takeNext(worker: Ident): Resource[F, Option[RPeriodicTask]]

  def clearMarks(name: Ident): F[Unit]

  def findNonFinalJob(pjobId: Ident): F[Option[RJob]]

  def insert(task: RPeriodicTask): F[Unit]
}

object PeriodicTaskStore {

  def create[F[_]: Sync](store: Store[F]): Resource[F, PeriodicTaskStore[F]] =
    Resource.pure[F, PeriodicTaskStore[F]](new PeriodicTaskStore[F] {
      println(s"$store")

      def takeNext(worker: Ident): Resource[F, Option[RPeriodicTask]] = {
        val chooseNext: F[Either[String, Option[RPeriodicTask]]] =
          getNext.flatMap {
            case Some(pj) =>
              mark(pj.id, worker).map {
                case true  => Right(Some(pj.copy(worker = worker.some)))
                case false => Left("Cannot mark periodic task")
              }
            case None =>
              val result: Either[String, Option[RPeriodicTask]] =
                Right(None)
              result.pure[F]
          }
        val get =
          Stream.eval(chooseNext).repeat.take(10).find(_.isRight).compile.lastOrError
        val r = Resource.make(get)({
          case Right(Some(pj)) => unmark(pj)
          case _               => ().pure[F]
        })
        r.flatMap {
          case Right(job) => Resource.pure(job)
          case Left(err)  => Resource.liftF(Sync[F].raiseError(new Exception(err)))
        }
      }

      def getNext: F[Option[RPeriodicTask]] =
        Sync[F].raiseError(new Exception("not implemented"))

      def mark(pid: Ident, name: Ident): F[Boolean] =
        Sync[F].raiseError(new Exception(s"not implemented $pid $name"))

      def unmark(job: RPeriodicTask): F[Unit] =
        Sync[F].raiseError(new Exception(s"not implemented $job"))

      def clearMarks(name: Ident): F[Unit] =
        Sync[F].raiseError(new Exception("not implemented"))

      def findNonFinalJob(pjobId: Ident): F[Option[RJob]] =
        Sync[F].raiseError(new Exception("not implemented"))

      def insert(task: RPeriodicTask): F[Unit] =
        Sync[F].raiseError(new Exception("not implemented"))
    })
}
