package docspell.store.records

import doobie._
import doobie.implicits._
import docspell.common._
import docspell.store.impl.Column
import docspell.store.impl.Implicits._

case class RJobLog(
    id: Ident,
    jobId: Ident,
    level: LogLevel,
    created: Timestamp,
    message: String
) {}

object RJobLog {

  val table = fr"joblog"

  object Columns {
    val id      = Column("id")
    val jobId   = Column("jid")
    val level   = Column("level")
    val created = Column("created")
    val message = Column("message")
    val all     = List(id, jobId, level, created, message)
  }
  import Columns._

  def insert(v: RJobLog): ConnectionIO[Int] =
    insertRow(
      table,
      all,
      fr"${v.id},${v.jobId},${v.level},${v.created},${v.message}"
    ).update.run

  def findLogs(id: Ident): ConnectionIO[Vector[RJobLog]] =
    (selectSimple(all, table, jobId.is(id)) ++ orderBy(created.asc))
      .query[RJobLog]
      .to[Vector]

  def deleteAll(job: Ident): ConnectionIO[Int] =
    deleteFrom(table, jobId.is(job)).update.run
}
