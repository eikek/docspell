package docspell.store.records

import cats.implicits._

import docspell.common._
import docspell.store.impl.Column
import docspell.store.impl.Implicits._

import doobie._
import doobie.implicits._

case class RJobGroupUse(groupId: Ident, workerId: Ident) {}

object RJobGroupUse {

  val table = fr"jobgroupuse"

  object Columns {
    val group  = Column("groupid")
    val worker = Column("workerid")
    val all    = List(group, worker)
  }
  import Columns._

  def insert(v: RJobGroupUse): ConnectionIO[Int] =
    insertRow(table, all, fr"${v.groupId},${v.workerId}").update.run

  def updateGroup(v: RJobGroupUse): ConnectionIO[Int] =
    updateRow(table, worker.is(v.workerId), group.setTo(v.groupId)).update.run

  def setGroup(v: RJobGroupUse): ConnectionIO[Int] =
    updateGroup(v).flatMap(n => if (n > 0) n.pure[ConnectionIO] else insert(v))

  def findGroup(workerId: Ident): ConnectionIO[Option[Ident]] =
    selectSimple(List(group), table, worker.is(workerId)).query[Ident].option
}
