package docspell.store.records

import cats.effect.Sync
import cats.implicits._

import docspell.common._
import docspell.store.impl.Column
import docspell.store.impl.Implicits._

import doobie._
import doobie.implicits._

case class RNode(
    id: Ident,
    nodeType: NodeType,
    url: LenientUri,
    updated: Timestamp,
    created: Timestamp
) {}

object RNode {

  def apply[F[_]: Sync](id: Ident, nodeType: NodeType, uri: LenientUri): F[RNode] =
    Timestamp.current[F].map(now => RNode(id, nodeType, uri, now, now))

  val table = fr"node"

  object Columns {
    val id       = Column("id")
    val nodeType = Column("type")
    val url      = Column("url")
    val updated  = Column("updated")
    val created  = Column("created")
    val all      = List(id, nodeType, url, updated, created)
  }
  import Columns._

  def insert(v: RNode): ConnectionIO[Int] =
    insertRow(
      table,
      all,
      fr"${v.id},${v.nodeType},${v.url},${v.updated},${v.created}"
    ).update.run

  def update(v: RNode): ConnectionIO[Int] =
    updateRow(
      table,
      id.is(v.id),
      commas(
        nodeType.setTo(v.nodeType),
        url.setTo(v.url),
        updated.setTo(v.updated)
      )
    ).update.run

  def set(v: RNode): ConnectionIO[Int] =
    for {
      n <- update(v)
      k <- if (n == 0) insert(v) else 0.pure[ConnectionIO]
    } yield n + k

  def delete(appId: Ident): ConnectionIO[Int] =
    (fr"DELETE FROM" ++ table ++ where(id.is(appId))).update.run

  def findAll(nt: NodeType): ConnectionIO[Vector[RNode]] =
    selectSimple(all, table, nodeType.is(nt)).query[RNode].to[Vector]

  def findById(nodeId: Ident): ConnectionIO[Option[RNode]] =
    selectSimple(all, table, id.is(nodeId)).query[RNode].option
}
