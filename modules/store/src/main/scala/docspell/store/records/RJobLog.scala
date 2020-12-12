package docspell.store.records

import docspell.common._
import docspell.store.qb.DSL._
import docspell.store.qb._

import doobie._
import doobie.implicits._

case class RJobLog(
    id: Ident,
    jobId: Ident,
    level: LogLevel,
    created: Timestamp,
    message: String
) {}

object RJobLog {
  final case class Table(alias: Option[String]) extends TableDef {
    val tableName = "joblog"

    val id      = Column[Ident]("id", this)
    val jobId   = Column[Ident]("jid", this)
    val level   = Column[LogLevel]("level", this)
    val created = Column[Timestamp]("created", this)
    val message = Column[String]("message", this)
    val all     = List(id, jobId, level, created, message)

    // separate column only for sorting, so not included in `all` and
    // the case class
    val counter = Column[Long]("counter", this)
  }

  val T = Table(None)
  def as(alias: String): Table =
    Table(Some(alias))

  def insert(v: RJobLog): ConnectionIO[Int] =
    DML.insert(
      T,
      T.all,
      fr"${v.id},${v.jobId},${v.level},${v.created},${v.message}"
    )

  def findLogs(id: Ident): ConnectionIO[Vector[RJobLog]] =
    Select(select(T.all), from(T), T.jobId === id)
      .orderBy(T.created.asc, T.counter.asc)
      .run
      .query[RJobLog]
      .to[Vector]

  def deleteAll(job: Ident): ConnectionIO[Int] =
    DML.delete(T, T.jobId === job)
}
