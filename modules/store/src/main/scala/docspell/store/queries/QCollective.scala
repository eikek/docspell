package docspell.store.queries

import cats.data.OptionT
import fs2.Stream

import docspell.common.ContactKind
import docspell.common.{Direction, Ident}
import docspell.store.impl.Implicits._
import docspell.store.records._

import doobie._
import doobie.implicits._

object QCollective {

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
    val IC = RItem.Columns
    val q0 = selectCount(
      IC.id,
      RItem.table,
      and(IC.cid.is(coll), IC.incoming.is(Direction.incoming))
    ).query[Int].unique
    val q1 = selectCount(
      IC.id,
      RItem.table,
      and(IC.cid.is(coll), IC.incoming.is(Direction.outgoing))
    ).query[Int].unique

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
    val TC = RTag.Columns
    val RC = RTagItem.Columns

    val q3 = fr"SELECT" ++ commas(
      TC.all.map(_.prefix("t").f) ++ Seq(fr"count(" ++ RC.itemId.prefix("r").f ++ fr")")
    ) ++
      fr"FROM" ++ RTagItem.table ++ fr"r" ++
      fr"INNER JOIN" ++ RTag.table ++ fr"t ON" ++ RC.tagId
      .prefix("r")
      .is(TC.tid.prefix("t")) ++
      fr"WHERE" ++ TC.cid.prefix("t").is(coll) ++
      fr"GROUP BY" ++ commas(
      TC.name.prefix("t").f,
      TC.tid.prefix("t").f,
      TC.category.prefix("t").f
    )

    q3.query[TagCount].to[List]
  }

  def getContacts(
      coll: Ident,
      query: Option[String],
      kind: Option[ContactKind]
  ): Stream[ConnectionIO, RContact] = {
    val RO = ROrganization
    val RP = RPerson
    val RC = RContact

    val orgCond  = selectSimple(Seq(RO.Columns.oid), RO.table, RO.Columns.cid.is(coll))
    val persCond = selectSimple(Seq(RP.Columns.pid), RP.table, RP.Columns.cid.is(coll))
    val queryCond = query match {
      case Some(q) =>
        Seq(RC.Columns.value.lowerLike(s"%${q.toLowerCase}%"))
      case None =>
        Seq.empty
    }
    val kindCond = kind match {
      case Some(k) =>
        Seq(RC.Columns.kind.is(k))
      case None =>
        Seq.empty
    }

    val q = selectSimple(
      RC.Columns.all,
      RC.table,
      and(
        Seq(
          or(RC.Columns.orgId.isIn(orgCond), RC.Columns.personId.isIn(persCond))
        ) ++ queryCond ++ kindCond
      )
    ) ++ orderBy(RC.Columns.value.f)

    q.query[RContact].stream
  }
}
