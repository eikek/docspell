package docspell.store.queries

//import cats.implicits._
import docspell.common._
//import docspell.common.syntax.all._
import docspell.store.impl.Implicits._
import docspell.store.records._
import doobie._
import doobie.implicits._
//import org.log4s._

object QPeriodicTask {
//  private[this] val logger = getLogger

  def clearWorkers(name: Ident): ConnectionIO[Int] = {
    val worker = RPeriodicTask.Columns.worker
    updateRow(RPeriodicTask.table, worker.is(name), worker.setTo[Ident](None)).update.run
  }

  def setWorker(pid: Ident, name: Ident): ConnectionIO[Int] = {
    val id     = RPeriodicTask.Columns.id
    val worker = RPeriodicTask.Columns.worker
    updateRow(RPeriodicTask.table, and(id.is(pid), worker.isNull), worker.setTo(name)).update.run
  }

  def unsetWorker(
      pid: Ident,
      nextRun: Option[Timestamp]
  ): ConnectionIO[Int] = {
    val id     = RPeriodicTask.Columns.id
    val worker = RPeriodicTask.Columns.worker
    val next   = RPeriodicTask.Columns.nextrun
    updateRow(
      RPeriodicTask.table,
      id.is(pid),
      commas(worker.setTo[Ident](None), next.setTo(nextRun))
    ).update.run
  }

  def findNext: ConnectionIO[Option[RPeriodicTask]] = {
    val order = orderBy(RPeriodicTask.Columns.nextrun.f) ++ fr"ASC"
    val sql =
      selectSimple(RPeriodicTask.Columns.all, RPeriodicTask.table, Fragment.empty) ++ order
    sql.query[RPeriodicTask].streamWithChunkSize(2).take(1).compile.last
  }

  def findNonFinal(pid: Ident): ConnectionIO[Option[RJob]] =
    selectSimple(
      RJob.Columns.all,
      RJob.table,
      and(
        RJob.Columns.tracker.is(pid),
        RJob.Columns.state.isOneOf(JobState.all.diff(JobState.done).toSeq)
      )
    ).query[RJob].option

}
