/*
 * Copyright 2020 Eike K. & Contributors
 *
 * SPDX-License-Identifier: AGPL-3.0-or-later
 */

package docspell.store.queries

import fs2.Stream

import docspell.common._
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
  private val re = REquipment.as("e")
  private val rc = RContact.as("c")
  private val i  = RItem.as("i")

  case class Names(org: Vector[String], pers: Vector[String], equip: Vector[String])
  object Names {
    val empty = Names(Vector.empty, Vector.empty, Vector.empty)
  }

  def allNames(collective: Ident, maxEntries: Int): ConnectionIO[Names] = {
    val created = Column[Timestamp]("created", TableDef(""))
    union(
      Select(
        select(ro.name.s, lit("1").as("kind"), ro.created.as(created)),
        from(ro),
        ro.cid === collective
      ),
      Select(
        select(rp.name.s, lit("2").as("kind"), rp.created.as(created)),
        from(rp),
        rp.cid === collective
      ),
      Select(
        select(re.name.s, lit("3").as("kind"), re.created.as(created)),
        from(re),
        re.cid === collective
      )
    ).orderBy(created.desc)
      .limit(Batch.limit(maxEntries))
      .build
      .query[(String, Int)]
      .streamWithChunkSize(maxEntries)
      .fold(Names.empty) { case (names, (name, kind)) =>
        if (kind == 1) names.copy(org = names.org :+ name)
        else if (kind == 2) names.copy(pers = names.pers :+ name)
        else names.copy(equip = names.equip :+ name)
      }
      .compile
      .lastOrError
  }

  case class InsightData(
      incoming: Int,
      outgoing: Int,
      deleted: Int,
      bytes: Long,
      tags: List[TagCount]
  )

  def getInsights(coll: Ident): ConnectionIO[InsightData] = {
    val q0 = Select(
      count(i.id).s,
      from(i),
      i.cid === coll && i.incoming === Direction.incoming && i.state.in(
        ItemState.validStates
      )
    ).build.query[Int].unique
    val q1 = Select(
      count(i.id).s,
      from(i),
      i.cid === coll && i.incoming === Direction.outgoing && i.state.in(
        ItemState.validStates
      )
    ).build.query[Int].unique
    val q2 = Select(
      count(i.id).s,
      from(i),
      i.cid === coll && i.state === ItemState.Deleted
    ).build.query[Int].unique

    val fileSize = sql"""
      select sum(length) from (
      with attachs as
            (select a.attachid as aid, a.filemetaid as fid
             from attachment a
             inner join item i on a.itemid = i.itemid
             where i.cid = $coll)
         select a.fid,m.length from attachs a
         inner join filemeta m on m.file_id = a.fid
         union distinct
         select a.file_id,m.length from attachment_source a
         inner join filemeta m on m.file_id = a.file_id where a.id in (select aid from attachs)
         union distinct
         select p.file_id,m.length from attachment_preview p
         inner join filemeta m on m.file_id = p.file_id where p.id in (select aid from attachs)
         union distinct
         select a.file_id,m.length from attachment_archive a
         inner join filemeta m on m.file_id = a.file_id where a.id in (select aid from attachs)
      ) as t""".query[Option[Long]].unique

    for {
      incoming <- q0
      outgoing <- q1
      size     <- fileSize
      tags     <- tagCloud(coll)
      deleted  <- q2
    } yield InsightData(incoming, outgoing, deleted, size.getOrElse(0L), tags)
  }

  def tagCloud(coll: Ident): ConnectionIO[List[TagCount]] = {
    val sql =
      Select(
        select(t.all).append(count(ti.itemId).s),
        from(ti).innerJoin(t, ti.tagId === t.tid).innerJoin(i, i.id === ti.itemId),
        t.cid === coll && i.state.in(ItemState.validStates)
      ).groupBy(t.name, t.tid, t.category)

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
