package docspell.store.queries

import docspell.common._
import docspell.store.impl.Implicits._
import docspell.store.records._

import doobie._
import doobie.implicits._

object QPeriodicTask {

  def clearWorkers(name: Ident): ConnectionIO[Int] = {
    val worker = RPeriodicTask.Columns.worker
    updateRow(RPeriodicTask.table, worker.is(name), worker.setTo[Ident](None)).update.run
  }

  def setWorker(pid: Ident, name: Ident, ts: Timestamp): ConnectionIO[Int] = {
    val id     = RPeriodicTask.Columns.id
    val worker = RPeriodicTask.Columns.worker
    val marked = RPeriodicTask.Columns.marked
    updateRow(
      RPeriodicTask.table,
      and(id.is(pid), worker.isNull),
      commas(worker.setTo(name), marked.setTo(ts))
    ).update.run
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

  def findNext(excl: Option[Ident]): ConnectionIO[Option[RPeriodicTask]] = {
    val enabled = RPeriodicTask.Columns.enabled
    val pid     = RPeriodicTask.Columns.id
    val order   = orderBy(RPeriodicTask.Columns.nextrun.f) ++ fr"ASC"

    val where = excl match {
      case Some(id) => and(pid.isNot(id), enabled.is(true))
      case None     => enabled.is(true)
    }
    val sql =
      selectSimple(RPeriodicTask.Columns.all, RPeriodicTask.table, where) ++ order
    sql.query[RPeriodicTask].streamWithChunkSize(2).take(1).compile.last
  }
}
