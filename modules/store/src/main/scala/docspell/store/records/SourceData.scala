package docspell.store.records

import cats.effect.Ref
import cats.implicits._
import fs2.Stream

import docspell.common._
import docspell.store.impl.DoobieMeta._
import docspell.store.qb._

import doobie._
import doobie.implicits._

/** Combines a source record (RSource) and a list of associated tags.
  */
case class SourceData(source: RSource, tags: Vector[RTag])

object SourceData {

  def fromSource(s: RSource): SourceData =
    SourceData(s, Vector.empty)

  def findAll(
      coll: Ident,
      order: RSource.Table => Column[_]
  ): Stream[ConnectionIO, SourceData] =
    findAllWithTags(RSource.findAllSql(coll, order).query[RSource].stream)

  private def findAllWithTags(
      select: Stream[ConnectionIO, RSource]
  ): Stream[ConnectionIO, SourceData] = {
    def findTag(
        cache: Ref[ConnectionIO, Map[Ident, RTag]],
        tagSource: RTagSource
    ): ConnectionIO[Option[RTag]] =
      for {
        cc <- cache.get
        fromCache = cc.get(tagSource.tagId)
        orFromDB <-
          if (fromCache.isDefined) fromCache.pure[ConnectionIO]
          else RTag.findById(tagSource.tagId)
        _ <-
          if (fromCache.isDefined) ().pure[ConnectionIO]
          else
            orFromDB match {
              case Some(t) => cache.update(tmap => tmap.updated(t.tagId, t))
              case None    => ().pure[ConnectionIO]
            }
      } yield orFromDB

    for {
      resolvedTags <- Stream.eval(Ref.of[ConnectionIO, Map[Ident, RTag]](Map.empty))
      source       <- select
      tagSources   <- Stream.eval(RTagSource.findBySource(source.sid))
      tags         <- Stream.eval(tagSources.traverse(ti => findTag(resolvedTags, ti)))
    } yield SourceData(source, tags.flatten)
  }

  def findEnabled(id: Ident): ConnectionIO[Option[SourceData]] =
    findAllWithTags(RSource.findEnabledSql(id).query[RSource].stream).head.compile.last

  def insert(data: RSource, tags: List[String]): ConnectionIO[Int] =
    for {
      n0   <- RSource.insert(data)
      tags <- RTag.findAllByNameOrId(tags, data.cid)
      n1 <- tags.traverse(tag =>
        RTagSource.createNew[ConnectionIO](data.sid, tag.tagId).flatMap(RTagSource.insert)
      )
    } yield n0 + n1.sum

  def update(data: RSource, tags: List[String]): ConnectionIO[Int] =
    for {
      n0   <- RSource.updateNoCounter(data)
      tags <- RTag.findAllByNameOrId(tags, data.cid)
      _    <- RTagSource.deleteSourceTags(data.sid)
      n1 <- tags.traverse(tag =>
        RTagSource.createNew[ConnectionIO](data.sid, tag.tagId).flatMap(RTagSource.insert)
      )
    } yield n0 + n1.sum

  def delete(source: Ident, coll: Ident): ConnectionIO[Int] =
    for {
      n0 <- RTagSource.deleteSourceTags(source)
      n1 <- RSource.delete(source, coll)
    } yield n0 + n1

}
