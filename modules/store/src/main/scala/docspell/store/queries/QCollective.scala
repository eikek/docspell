package docspell.store.queries

import fs2.Stream
import doobie._
import doobie.implicits._
import docspell.common.{Direction, Ident}
import docspell.store.impl.Implicits._
import docspell.store.records._
import docspell.common.ContactKind

object QCollective {

  case class InsightData(incoming: Int, outgoing: Int, bytes: Long, tags: Map[String, Int])

  def getInsights(coll: Ident): ConnectionIO[InsightData] = {
    val IC = RItem.Columns
    val AC = RAttachment.Columns
    val TC = RTag.Columns
    val RC = RTagItem.Columns
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

    val q2 = fr"SELECT sum(m.length) FROM" ++ RItem.table ++ fr"i" ++
      fr"INNER JOIN" ++ RAttachment.table ++ fr"a ON" ++ AC.itemId
      .prefix("a")
      .is(IC.id.prefix("i")) ++
      fr"INNER JOIN filemeta m ON m.id =" ++ AC.fileId.prefix("a").f ++
      fr"WHERE" ++ IC.cid.is(coll)

    val q3 = fr"SELECT" ++ commas(
      TC.name.prefix("t").f,
      fr"count(" ++ RC.itemId.prefix("r").f ++ fr")"
    ) ++
      fr"FROM" ++ RTagItem.table ++ fr"r" ++
      fr"INNER JOIN" ++ RTag.table ++ fr"t ON" ++ RC.tagId.prefix("r").is(TC.tid.prefix("t")) ++
      fr"WHERE" ++ TC.cid.prefix("t").is(coll) ++
      fr"GROUP BY" ++ TC.name.prefix("t").f

    for {
      n0 <- q0
      n1 <- q1
      n2 <- q2.query[Option[Long]].unique
      n3 <- q3.query[(String, Int)].to[Vector]
    } yield InsightData(n0, n1, n2.getOrElse(0), Map.from(n3))
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
        Seq(or(RC.Columns.orgId.isIn(orgCond), RC.Columns.personId.isIn(persCond))) ++ queryCond ++ kindCond
      )
    ) ++ orderBy(RC.Columns.value.f)

    q.query[RContact].stream
  }
}
