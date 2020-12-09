package docspell.store.records

import cats.effect.Sync
import cats.implicits._

import docspell.common._
import docspell.store.qb.DSL._
import docspell.store.qb._

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

  final case class Table(alias: Option[String]) extends TableDef {
    val tableName = "node"

    val id       = Column[Ident]("id", this)
    val nodeType = Column[NodeType]("type", this)
    val url      = Column[LenientUri]("url", this)
    val updated  = Column[Timestamp]("updated", this)
    val created  = Column[Timestamp]("created", this)
    val all      = List(id, nodeType, url, updated, created)
  }

  def as(alias: String): Table =
    Table(Some(alias))

  def insert(v: RNode): ConnectionIO[Int] = {
    val t = Table(None)
    DML.insert(
      t,
      t.all,
      fr"${v.id},${v.nodeType},${v.url},${v.updated},${v.created}"
    )
  }

  def update(v: RNode): ConnectionIO[Int] = {
    val t = Table(None)
    DML
      .update(
        t,
        t.id === v.id,
        DML.set(
          t.nodeType.setTo(v.nodeType),
          t.url.setTo(v.url),
          t.updated.setTo(v.updated)
        )
      )
  }

  def set(v: RNode): ConnectionIO[Int] =
    for {
      n <- update(v)
      k <- if (n == 0) insert(v) else 0.pure[ConnectionIO]
    } yield n + k

  def delete(appId: Ident): ConnectionIO[Int] = {
    val t = Table(None)
    DML.delete(t, t.id === appId)
  }

  def findAll(nt: NodeType): ConnectionIO[Vector[RNode]] = {
    val t = Table(None)
    run(select(t.all), from(t), t.nodeType === nt).query[RNode].to[Vector]
  }

  def findById(nodeId: Ident): ConnectionIO[Option[RNode]] = {
    val t = Table(None)
    run(select(t.all), from(t), t.id === nodeId).query[RNode].option
  }
}
