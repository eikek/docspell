package docspell.store.queries

import cats.data.OptionT
import fs2.Stream

import docspell.common.ContactKind
import docspell.common.{Direction, Ident}
import docspell.store.qb.DSL._
import docspell.store.qb._
import docspell.store.records._

import doobie._
import doobie.implicits._

object QCollective {
  private val ti = RTagItem.as("ti")
  private val t  = RTag.as("t")
  private val ro = ROrganization.as("o")
  private val rp = RPerson.as("p")
  private val rc = RContact.as("c")
  private val i  = RItem.as("i")

  case class Names(org: Vector[String], pers: Vector[String], equip: Vector[String])
  object Names {
    val empty = Names(Vector.empty, Vector.empty, Vector.empty)
  }

  def allNames(collective: Ident): ConnectionIO[Names] =
    (for {
      orgs <- OptionT.liftF(ROrganization.findAllRef(collective, None, _.name))
      pers <- OptionT.liftF(RPerson.findAllRef(collective, None, _.name))
      equp <- OptionT.liftF(REquipment.findAll(collective, None, _.name))
    } yield Names(orgs.map(_.name), pers.map(_.name), equp.map(_.name)))
      .getOrElse(Names.empty)

  case class TagCount(tag: RTag, count: Int)

  case class InsightData(
      incoming: Int,
      outgoing: Int,
      bytes: Long,
      tags: List[TagCount]
  )

  def getInsights(coll: Ident): ConnectionIO[InsightData] = {
    val q0 = Select(
      count(i.id).s,
      from(i),
      i.cid === coll && i.incoming === Direction.incoming
    ).build.query[Int].unique
    val q1 = Select(
      count(i.id).s,
      from(i),
      i.cid === coll && i.incoming === Direction.outgoing
    ).build.query[Int].unique

    val fileSize = sql"""
      select sum(length) from (
      with attachs as
            (select a.attachid as aid, a.filemetaid as fid
             from attachment a
             inner join item i on a.itemid = i.itemid
             where i.cid = $coll)
         select a.fid,m.length from attachs a
         inner join filemeta m on m.id = a.fid
         union distinct
         select a.file_id,m.length from attachment_source a
         inner join filemeta m on m.id = a.file_id where a.id in (select aid from attachs)
         union distinct
         select p.file_id,m.length from attachment_preview p
         inner join filemeta m on m.id = p.file_id where p.id in (select aid from attachs)
         union distinct
         select a.file_id,m.length from attachment_archive a
         inner join filemeta m on m.id = a.file_id where a.id in (select aid from attachs)
      ) as t""".query[Option[Long]].unique

    for {
      n0 <- q0
      n1 <- q1
      n2 <- fileSize
      n3 <- tagCloud(coll)
    } yield InsightData(n0, n1, n2.getOrElse(0L), n3)
  }

  def tagCloud(coll: Ident): ConnectionIO[List[TagCount]] = {
    val sql =
      Select(
        select(t.all).append(count(ti.itemId).s),
        from(ti).innerJoin(t, ti.tagId === t.tid),
        t.cid === coll
      ).group(GroupBy(t.name, t.tid, t.category))

    sql.build.query[TagCount].to[List]
  }

  def getContacts(
      coll: Ident,
      query: Option[String],
      kind: Option[ContactKind]
  ): Stream[ConnectionIO, RContact] = {
    val orgCond     = Select(select(ro.oid), from(ro), ro.cid === coll)
    val persCond    = Select(select(rp.pid), from(rp), rp.cid === coll)
    val valueFilter = query.map(s => rc.value.like(s"%${s.toLowerCase}%"))
    val kindFilter  = kind.map(k => rc.kind === k)

    Select(
      select(rc.all),
      from(rc),
      (rc.orgId.in(orgCond) || rc.personId.in(persCond)) &&? valueFilter &&? kindFilter
    ).orderBy(rc.value).build.query[RContact].stream
  }
}
