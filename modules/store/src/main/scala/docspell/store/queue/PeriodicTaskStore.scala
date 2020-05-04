package docspell.store.queue

import cats.effect._
import cats.implicits._
import org.log4s.getLogger
import com.github.eikek.fs2calev._
import docspell.common._
import docspell.common.syntax.all._
import docspell.store.{AddResult, Store}
import docspell.store.records._
import docspell.store.queries.QPeriodicTask

trait PeriodicTaskStore[F[_]] {

  /** Get the free periodic task due next and reserve it to the given
    * worker.
    *
    * If found, the task is returned and resource finalization takes
    * care of unmarking the task after use and updating `nextRun` with
    * the next timestamp.
    */
  def takeNext(
      worker: Ident,
      excludeId: Option[Ident]
  ): Resource[F, Marked[RPeriodicTask]]

  def clearMarks(name: Ident): F[Unit]

  def findNonFinalJob(pjobId: Ident): F[Option[RJob]]

  /** Insert a task or update if it already exists.
    */
  def insert(task: RPeriodicTask): F[Unit]

  /** Adds the task only if it not already exists.
    */
  def add(task: RPeriodicTask): F[AddResult]

  /** Find all joex nodes as registered in the database.
    */
  def findJoexNodes: F[Vector[RNode]]
}

object PeriodicTaskStore {
  private[this] val logger = getLogger

  def create[F[_]: Sync](store: Store[F]): Resource[F, PeriodicTaskStore[F]] =
    Resource.pure[F, PeriodicTaskStore[F]](new PeriodicTaskStore[F] {

      def takeNext(
          worker: Ident,
          excludeId: Option[Ident]
      ): Resource[F, Marked[RPeriodicTask]] = {
        val chooseNext: F[Marked[RPeriodicTask]] =
          getNext(excludeId).flatMap {
            case Some(pj) =>
              mark(pj.id, worker).map {
                case true  => Marked.found(pj.copy(worker = worker.some))
                case false => Marked.notMarkable
              }
            case None =>
              Marked.notFound.pure[F]
          }

        Resource.make(chooseNext)({
          case Marked.Found(pj) => unmark(pj)
          case _                => ().pure[F]
        })
      }

      def getNext(excl: Option[Ident]): F[Option[RPeriodicTask]] =
        store.transact(QPeriodicTask.findNext(excl))

      def mark(pid: Ident, name: Ident): F[Boolean] =
        Timestamp
          .current[F]
          .flatMap(now =>
            store.transact(QPeriodicTask.setWorker(pid, name, now)).map(_ > 0)
          )

      def unmark(job: RPeriodicTask): F[Unit] =
        for {
          now <- Timestamp.current[F]
          nextRun <-
            CalevFs2
              .nextElapses[F](now.atUTC)(job.timer)
              .take(1)
              .compile
              .last
              .map(_.map(Timestamp.from))
          _ <- store.transact(QPeriodicTask.unsetWorker(job.id, nextRun))
        } yield ()

      def clearMarks(name: Ident): F[Unit] =
        store
          .transact(QPeriodicTask.clearWorkers(name))
          .flatMap { n =>
            if (n > 0) logger.finfo(s"Clearing $n periodic tasks from worker ${name.id}")
            else ().pure[F]
          }

      def findNonFinalJob(pjobId: Ident): F[Option[RJob]] =
        store.transact(QPeriodicTask.findNonFinal(pjobId))

      def insert(task: RPeriodicTask): F[Unit] = {
        val update = store.transact(RPeriodicTask.update(task))
        val insertAttempt = store.transact(RPeriodicTask.insert(task)).attempt.map {
          case Right(n) => n > 0
          case Left(_)  => false
        }

        for {
          n1  <- update
          ins <- if (n1 == 0) insertAttempt else true.pure[F]
          _   <- if (ins) 1.pure[F] else update
        } yield ()
      }

      def add(task: RPeriodicTask): F[AddResult] = {
        val insert = RPeriodicTask.insert(task)
        val exists = RPeriodicTask.exists(task.id)
        store.add(insert, exists)
      }

      def findJoexNodes: F[Vector[RNode]] =
        store.transact(RNode.findAll(NodeType.Joex))

    })
}
