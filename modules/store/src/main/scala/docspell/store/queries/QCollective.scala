package docspell.store.queries

import doobie._
import doobie.implicits._
import docspell.common.{Direction, Ident}
import docspell.store.impl.Implicits._
import docspell.store.records.{RAttachment, RItem, RTag, RTagItem}

object QCollective {

  case class InsightData( incoming: Int
                          , outgoing: Int
                          , bytes: Long
                          , tags: Map[String, Int])

  def getInsights(coll: Ident): ConnectionIO[InsightData] = {
    val IC = RItem.Columns
    val AC = RAttachment.Columns
    val TC = RTag.Columns
    val RC = RTagItem.Columns
    val q0 = selectCount(IC.id, RItem.table, and(IC.cid is coll, IC.incoming is Direction.incoming)).
      query[Int].unique
    val q1 = selectCount(IC.id, RItem.table, and(IC.cid is coll, IC.incoming is Direction.outgoing)).
      query[Int].unique

    val q2 = fr"SELECT sum(m.length) FROM" ++ RItem.table ++ fr"i" ++
      fr"INNER JOIN" ++ RAttachment.table ++ fr"a ON" ++ AC.itemId.prefix("a").is(IC.id.prefix("i")) ++
      fr"INNER JOIN filemeta m ON m.id =" ++ AC.fileId.prefix("a").f ++
      fr"WHERE" ++ IC.cid.is(coll)

    val q3 = fr"SELECT" ++ commas(TC.name.prefix("t").f,fr"count(" ++ RC.itemId.prefix("r").f ++ fr")") ++
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

}
