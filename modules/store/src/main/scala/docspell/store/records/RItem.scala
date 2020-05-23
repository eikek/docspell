package docspell.store.records

import cats.data.NonEmptyList
import cats.effect.Sync
import cats.implicits._
import doobie._
import doobie.implicits._
import docspell.common._
import docspell.store.impl._
import docspell.store.impl.Implicits._

case class RItem(
    id: Ident,
    cid: Ident,
    name: String,
    itemDate: Option[Timestamp],
    source: String,
    direction: Direction,
    state: ItemState,
    corrOrg: Option[Ident],
    corrPerson: Option[Ident],
    concPerson: Option[Ident],
    concEquipment: Option[Ident],
    inReplyTo: Option[Ident],
    dueDate: Option[Timestamp],
    created: Timestamp,
    updated: Timestamp,
    notes: Option[String]
) {}

object RItem {

  def newItem[F[_]: Sync](
      cid: Ident,
      name: String,
      source: String,
      direction: Direction,
      state: ItemState
  ): F[RItem] =
    for {
      now <- Timestamp.current[F]
      id  <- Ident.randomId[F]
    } yield RItem(
      id,
      cid,
      name,
      None,
      source,
      direction,
      state,
      None,
      None,
      None,
      None,
      None,
      None,
      now,
      now,
      None
    )

  val table = fr"item"

  object Columns {
    val id            = Column("itemid")
    val cid           = Column("cid")
    val name          = Column("name")
    val itemDate      = Column("itemdate")
    val source        = Column("source")
    val incoming      = Column("incoming")
    val state         = Column("state")
    val corrOrg       = Column("corrorg")
    val corrPerson    = Column("corrperson")
    val concPerson    = Column("concperson")
    val concEquipment = Column("concequipment")
    val inReplyTo     = Column("inreplyto")
    val dueDate       = Column("duedate")
    val created       = Column("created")
    val updated       = Column("updated")
    val notes         = Column("notes")
    val all = List(
      id,
      cid,
      name,
      itemDate,
      source,
      incoming,
      state,
      corrOrg,
      corrPerson,
      concPerson,
      concEquipment,
      inReplyTo,
      dueDate,
      created,
      updated,
      notes
    )
  }
  import Columns._

  def insert(v: RItem): ConnectionIO[Int] =
    insertRow(
      table,
      all,
      fr"${v.id},${v.cid},${v.name},${v.itemDate},${v.source},${v.direction},${v.state}," ++
        fr"${v.corrOrg},${v.corrPerson},${v.concPerson},${v.concEquipment},${v.inReplyTo},${v.dueDate}," ++
        fr"${v.created},${v.updated},${v.notes}"
    ).update.run

  def getCollective(itemId: Ident): ConnectionIO[Option[Ident]] =
    selectSimple(List(cid), table, id.is(itemId)).query[Ident].option

  def updateState(
      itemId: Ident,
      itemState: ItemState,
      existing: NonEmptyList[ItemState]
  ): ConnectionIO[Int] =
    for {
      t <- currentTime
      n <- updateRow(
        table,
        and(id.is(itemId), state.isIn(existing)),
        commas(state.setTo(itemState), updated.setTo(t))
      ).update.run
    } yield n

  def updateStateForCollective(
      itemId: Ident,
      itemState: ItemState,
      coll: Ident
  ): ConnectionIO[Int] =
    for {
      t <- currentTime
      n <- updateRow(
        table,
        and(id.is(itemId), cid.is(coll)),
        commas(state.setTo(itemState), updated.setTo(t))
      ).update.run
    } yield n

  def updateDirection(itemId: Ident, coll: Ident, dir: Direction): ConnectionIO[Int] =
    for {
      t <- currentTime
      n <- updateRow(
        table,
        and(id.is(itemId), cid.is(coll)),
        commas(incoming.setTo(dir), updated.setTo(t))
      ).update.run
    } yield n

  def updateCorrOrg(itemId: Ident, coll: Ident, org: Option[Ident]): ConnectionIO[Int] =
    for {
      t <- currentTime
      n <- updateRow(
        table,
        and(id.is(itemId), cid.is(coll)),
        commas(corrOrg.setTo(org), updated.setTo(t))
      ).update.run
    } yield n

  def removeCorrOrg(coll: Ident, currentOrg: Ident): ConnectionIO[Int] =
    for {
      t <- currentTime
      n <- updateRow(
        table,
        and(cid.is(coll), corrOrg.is(Some(currentOrg))),
        commas(corrOrg.setTo(None: Option[Ident]), updated.setTo(t))
      ).update.run
    } yield n

  def updateCorrPerson(
      itemId: Ident,
      coll: Ident,
      person: Option[Ident]
  ): ConnectionIO[Int] =
    for {
      t <- currentTime
      n <- updateRow(
        table,
        and(id.is(itemId), cid.is(coll)),
        commas(corrPerson.setTo(person), updated.setTo(t))
      ).update.run
    } yield n

  def removeCorrPerson(coll: Ident, currentPerson: Ident): ConnectionIO[Int] =
    for {
      t <- currentTime
      n <- updateRow(
        table,
        and(cid.is(coll), corrPerson.is(Some(currentPerson))),
        commas(corrPerson.setTo(None: Option[Ident]), updated.setTo(t))
      ).update.run
    } yield n

  def updateConcPerson(
      itemId: Ident,
      coll: Ident,
      person: Option[Ident]
  ): ConnectionIO[Int] =
    for {
      t <- currentTime
      n <- updateRow(
        table,
        and(id.is(itemId), cid.is(coll)),
        commas(concPerson.setTo(person), updated.setTo(t))
      ).update.run
    } yield n

  def removeConcPerson(coll: Ident, currentPerson: Ident): ConnectionIO[Int] =
    for {
      t <- currentTime
      n <- updateRow(
        table,
        and(cid.is(coll), concPerson.is(Some(currentPerson))),
        commas(concPerson.setTo(None: Option[Ident]), updated.setTo(t))
      ).update.run
    } yield n

  def updateConcEquip(
      itemId: Ident,
      coll: Ident,
      equip: Option[Ident]
  ): ConnectionIO[Int] =
    for {
      t <- currentTime
      n <- updateRow(
        table,
        and(id.is(itemId), cid.is(coll)),
        commas(concEquipment.setTo(equip), updated.setTo(t))
      ).update.run
    } yield n

  def removeConcEquip(coll: Ident, currentEquip: Ident): ConnectionIO[Int] =
    for {
      t <- currentTime
      n <- updateRow(
        table,
        and(cid.is(coll), concEquipment.is(Some(currentEquip))),
        commas(concPerson.setTo(None: Option[Ident]), updated.setTo(t))
      ).update.run
    } yield n

  def updateNotes(itemId: Ident, coll: Ident, text: Option[String]): ConnectionIO[Int] =
    for {
      t <- currentTime
      n <- updateRow(
        table,
        and(id.is(itemId), cid.is(coll)),
        commas(notes.setTo(text), updated.setTo(t))
      ).update.run
    } yield n

  def updateName(itemId: Ident, coll: Ident, itemName: String): ConnectionIO[Int] =
    for {
      t <- currentTime
      n <- updateRow(
        table,
        and(id.is(itemId), cid.is(coll)),
        commas(name.setTo(itemName), updated.setTo(t))
      ).update.run
    } yield n

  def updateDate(itemId: Ident, coll: Ident, date: Option[Timestamp]): ConnectionIO[Int] =
    for {
      t <- currentTime
      n <- updateRow(
        table,
        and(id.is(itemId), cid.is(coll)),
        commas(itemDate.setTo(date), updated.setTo(t))
      ).update.run
    } yield n

  def updateDueDate(
      itemId: Ident,
      coll: Ident,
      date: Option[Timestamp]
  ): ConnectionIO[Int] =
    for {
      t <- currentTime
      n <- updateRow(
        table,
        and(id.is(itemId), cid.is(coll)),
        commas(dueDate.setTo(date), updated.setTo(t))
      ).update.run
    } yield n

  def deleteByIdAndCollective(itemId: Ident, coll: Ident): ConnectionIO[Int] =
    deleteFrom(table, and(id.is(itemId), cid.is(coll))).update.run

  def existsById(itemId: Ident): ConnectionIO[Boolean] =
    selectCount(id, table, id.is(itemId)).query[Int].unique.map(_ > 0)
}
