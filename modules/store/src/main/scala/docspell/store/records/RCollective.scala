package docspell.store.records

import fs2.Stream

import docspell.common._
import docspell.store.impl.Column
import docspell.store.impl.Implicits._

import doobie._
import doobie.implicits._

case class RCollective(
    id: Ident,
    state: CollectiveState,
    language: Language,
    integrationEnabled: Boolean,
    created: Timestamp
)

object RCollective {

  val table = fr"collective"

  object Columns {

    val id          = Column("cid")
    val state       = Column("state")
    val language    = Column("doclang")
    val integration = Column("integration_enabled")
    val created     = Column("created")

    val all = List(id, state, language, integration, created)
  }

  import Columns._

  def insert(value: RCollective): ConnectionIO[Int] = {
    val sql = insertRow(
      table,
      Columns.all,
      fr"${value.id},${value.state},${value.language},${value.integrationEnabled},${value.created}"
    )
    sql.update.run
  }

  def update(value: RCollective): ConnectionIO[Int] = {
    val sql = updateRow(
      table,
      id.is(value.id),
      commas(
        state.setTo(value.state)
      )
    )
    sql.update.run
  }

  def findLanguage(cid: Ident): ConnectionIO[Option[Language]] =
    selectSimple(List(language), table, id.is(cid)).query[Option[Language]].unique

  def updateLanguage(cid: Ident, lang: Language): ConnectionIO[Int] =
    updateRow(table, id.is(cid), language.setTo(lang)).update.run

  def updateSettings(cid: Ident, settings: Settings): ConnectionIO[Int] =
    updateRow(
      table,
      id.is(cid),
      commas(
        language.setTo(settings.language),
        integration.setTo(settings.integrationEnabled)
      )
    ).update.run

  def findById(cid: Ident): ConnectionIO[Option[RCollective]] = {
    val sql = selectSimple(all, table, id.is(cid))
    sql.query[RCollective].option
  }

  def findByItem(itemId: Ident): ConnectionIO[Option[RCollective]] = {
    val iColl = RItem.Columns.cid.prefix("i")
    val iId   = RItem.Columns.id.prefix("i")
    val cId   = id.prefix("c")
    val from  = RItem.table ++ fr"i INNER JOIN" ++ table ++ fr"c ON" ++ iColl.is(cId)
    selectSimple(all.map(_.prefix("c")), from, iId.is(itemId)).query[RCollective].option
  }

  def existsById(cid: Ident): ConnectionIO[Boolean] = {
    val sql = selectCount(id, table, id.is(cid))
    sql.query[Int].unique.map(_ > 0)
  }

  def findAll(order: Columns.type => Column): ConnectionIO[Vector[RCollective]] = {
    val sql = selectSimple(all, table, Fragment.empty) ++ orderBy(order(Columns).f)
    sql.query[RCollective].to[Vector]
  }

  def streamAll(order: Columns.type => Column): Stream[ConnectionIO, RCollective] = {
    val sql = selectSimple(all, table, Fragment.empty) ++ orderBy(order(Columns).f)
    sql.query[RCollective].stream
  }

  def findByAttachment(attachId: Ident): ConnectionIO[Option[RCollective]] = {
    val iColl = RItem.Columns.cid.prefix("i")
    val iId   = RItem.Columns.id.prefix("i")
    val aItem = RAttachment.Columns.itemId.prefix("a")
    val aId   = RAttachment.Columns.id.prefix("a")
    val cId   = Columns.id.prefix("c")

    val from = table ++ fr"c INNER JOIN" ++
      RItem.table ++ fr"i ON" ++ cId.is(iColl) ++ fr"INNER JOIN" ++
      RAttachment.table ++ fr"a ON" ++ aItem.is(iId)

    selectSimple(all, from, aId.is(attachId)).query[RCollective].option
  }

  case class Settings(language: Language, integrationEnabled: Boolean)
}
