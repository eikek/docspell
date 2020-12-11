package docspell.store.queries

import docspell.common._
import docspell.store.qb.DSL._
import docspell.store.qb._
import docspell.store.records._

import doobie._
import doobie.implicits._

object QPeriodicTask {

  private val RT = RPeriodicTask.T

  def clearWorkers(name: Ident): ConnectionIO[Int] =
    DML.update(
      RT,
      RT.worker === name,
      DML.set(RT.worker.setTo(None: Option[Ident]))
    )

  def setWorker(pid: Ident, name: Ident, ts: Timestamp): ConnectionIO[Int] =
    DML
      .update(
        RT,
        RT.id === pid && RT.worker.isNull,
        DML.set(
          RT.worker.setTo(name),
          RT.marked.setTo(ts)
        )
      )

  def unsetWorker(
      pid: Ident,
      nextRun: Option[Timestamp]
  ): ConnectionIO[Int] =
    DML.update(
      RT,
      RT.id === pid,
      DML.set(
        RT.worker.setTo(None),
        RT.nextrun.setTo(nextRun)
      )
    )

  def findNext(excl: Option[Ident]): ConnectionIO[Option[RPeriodicTask]] = {
    val where = excl match {
      case Some(id) => RT.id <> id && RT.enabled === true
      case None     => RT.enabled === true
    }
    val sql =
      Select(select(RT.all), from(RT), where).orderBy(RT.nextrun.asc).run

    sql.query[RPeriodicTask].streamWithChunkSize(2).take(1).compile.last
  }
}
