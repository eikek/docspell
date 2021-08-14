/*
 * Copyright 2020 Docspell Contributors
 *
 * SPDX-License-Identifier: GPL-3.0-or-later
 */

package docspell.store.records

import cats.data.NonEmptyList
import cats.effect.Sync
import cats.implicits._
import fs2.Stream

import docspell.common._
import docspell.store.qb.DSL._
import docspell.store.qb._

import doobie._
import doobie.implicits._

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
    notes: Option[String],
    folderId: Option[Ident]
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
      None,
      None
    )

  final case class Table(alias: Option[String]) extends TableDef {
    import docspell.store.qb.Column
    val tableName = "item"

    val id            = Column[Ident]("itemid", this)
    val cid           = Column[Ident]("cid", this)
    val name          = Column[String]("name", this)
    val itemDate      = Column[Timestamp]("itemdate", this)
    val source        = Column[String]("source", this)
    val incoming      = Column[Direction]("incoming", this)
    val state         = Column[ItemState]("state", this)
    val corrOrg       = Column[Ident]("corrorg", this)
    val corrPerson    = Column[Ident]("corrperson", this)
    val concPerson    = Column[Ident]("concperson", this)
    val concEquipment = Column[Ident]("concequipment", this)
    val inReplyTo     = Column[Ident]("inreplyto", this)
    val dueDate       = Column[Timestamp]("duedate", this)
    val created       = Column[Timestamp]("created", this)
    val updated       = Column[Timestamp]("updated", this)
    val notes         = Column[String]("notes", this)
    val folder        = Column[Ident]("folder_id", this)
    val all = NonEmptyList.of[Column[_]](
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
      notes,
      folder
    )
  }
  val T = Table(None)
  def as(alias: String): Table =
    Table(Some(alias))

  private val currentTime =
    Timestamp.current[ConnectionIO]

  def insert(v: RItem): ConnectionIO[Int] =
    DML.insert(
      T,
      T.all,
      fr"${v.id},${v.cid},${v.name},${v.itemDate},${v.source},${v.direction},${v.state}," ++
        fr"${v.corrOrg},${v.corrPerson},${v.concPerson},${v.concEquipment},${v.inReplyTo},${v.dueDate}," ++
        fr"${v.created},${v.updated},${v.notes},${v.folderId}"
    )

  def getCollective(itemId: Ident): ConnectionIO[Option[Ident]] =
    Select(T.cid.s, from(T), T.id === itemId).build.query[Ident].option

  def updateState(
      itemId: Ident,
      itemState: ItemState,
      existing: NonEmptyList[ItemState]
  ): ConnectionIO[Int] =
    for {
      t <- currentTime
      n <- DML.update(
        T,
        T.id === itemId && T.state.in(existing),
        DML.set(T.state.setTo(itemState), T.updated.setTo(t))
      )
    } yield n

  def updateStateForCollective(
      itemIds: NonEmptyList[Ident],
      itemState: ItemState,
      coll: Ident
  ): ConnectionIO[Int] =
    for {
      t <- currentTime
      n <- DML.update(
        T,
        T.id.in(itemIds) && T.cid === coll && T.state.in(ItemState.validStates),
        DML.set(T.state.setTo(itemState), T.updated.setTo(t))
      )
    } yield n

  def restoreStateForCollective(
      itemIds: NonEmptyList[Ident],
      itemState: ItemState,
      coll: Ident
  ): ConnectionIO[Int] =
    for {
      t <- currentTime
      n <- DML.update(
        T,
        T.id.in(itemIds) && T.cid === coll && T.state === ItemState.deleted,
        DML.set(T.state.setTo(itemState), T.updated.setTo(t))
      )
    } yield n

  def updateDirection(
      itemIds: NonEmptyList[Ident],
      coll: Ident,
      dir: Direction
  ): ConnectionIO[Int] =
    for {
      t <- currentTime
      n <- DML.update(
        T,
        T.id.in(itemIds) && T.cid === coll,
        DML.set(T.incoming.setTo(dir), T.updated.setTo(t))
      )
    } yield n

  def updateCorrOrg(
      itemIds: NonEmptyList[Ident],
      coll: Ident,
      org: Option[Ident]
  ): ConnectionIO[Int] =
    for {
      t <- currentTime
      n <- DML.update(
        T,
        T.id.in(itemIds) && T.cid === coll,
        DML.set(T.corrOrg.setTo(org), T.updated.setTo(t))
      )
    } yield n

  def removeCorrOrg(coll: Ident, currentOrg: Ident): ConnectionIO[Int] =
    for {
      t <- currentTime
      n <- DML.update(
        T,
        T.cid === coll && T.corrOrg === currentOrg,
        DML.set(T.corrOrg.setTo(None: Option[Ident]), T.updated.setTo(t))
      )
    } yield n

  def updateCorrPerson(
      itemIds: NonEmptyList[Ident],
      coll: Ident,
      person: Option[Ident]
  ): ConnectionIO[Int] =
    for {
      t <- currentTime
      n <- DML.update(
        T,
        T.id.in(itemIds) && T.cid === coll,
        DML.set(T.corrPerson.setTo(person), T.updated.setTo(t))
      )
    } yield n

  def removeCorrPerson(coll: Ident, currentPerson: Ident): ConnectionIO[Int] =
    for {
      t <- currentTime
      n <- DML.update(
        T,
        T.cid === coll && T.corrPerson === currentPerson,
        DML.set(T.corrPerson.setTo(None: Option[Ident]), T.updated.setTo(t))
      )
    } yield n

  def updateConcPerson(
      itemIds: NonEmptyList[Ident],
      coll: Ident,
      person: Option[Ident]
  ): ConnectionIO[Int] =
    for {
      t <- currentTime
      n <- DML.update(
        T,
        T.id.in(itemIds) && T.cid === coll,
        DML.set(T.concPerson.setTo(person), T.updated.setTo(t))
      )
    } yield n

  def removeConcPerson(coll: Ident, currentPerson: Ident): ConnectionIO[Int] =
    for {
      t <- currentTime
      n <- DML.update(
        T,
        T.cid === coll && T.concPerson === currentPerson,
        DML.set(T.concPerson.setTo(None: Option[Ident]), T.updated.setTo(t))
      )
    } yield n

  def updateConcEquip(
      itemIds: NonEmptyList[Ident],
      coll: Ident,
      equip: Option[Ident]
  ): ConnectionIO[Int] =
    for {
      t <- currentTime
      n <- DML.update(
        T,
        T.id.in(itemIds) && T.cid === coll,
        DML.set(T.concEquipment.setTo(equip), T.updated.setTo(t))
      )
    } yield n

  def removeConcEquip(coll: Ident, currentEquip: Ident): ConnectionIO[Int] =
    for {
      t <- currentTime
      n <- DML.update(
        T,
        T.cid === coll && T.concEquipment === currentEquip,
        DML.set(T.concEquipment.setTo(None: Option[Ident]), T.updated.setTo(t))
      )
    } yield n

  def updateFolder(
      itemId: Ident,
      coll: Ident,
      folderId: Option[Ident]
  ): ConnectionIO[Int] =
    for {
      t <- currentTime
      fid <- folderId match {
        case Some(f) => RFolder.requireIdByIdOrName(f, f.id, coll).map(_.some)
        case None    => None.pure[ConnectionIO]
      }
      n <- DML.update(
        T,
        T.cid === coll && T.id === itemId,
        DML.set(T.folder.setTo(fid), T.updated.setTo(t))
      )
    } yield n

  def updateNotes(itemId: Ident, coll: Ident, text: Option[String]): ConnectionIO[Int] =
    for {
      t <- currentTime
      n <- DML.update(
        T,
        T.id === itemId && T.cid === coll,
        DML.set(T.notes.setTo(text), T.updated.setTo(t))
      )
    } yield n

  def updateName(itemId: Ident, coll: Ident, itemName: String): ConnectionIO[Int] =
    for {
      t <- currentTime
      n <- DML.update(
        T,
        T.id === itemId && T.cid === coll,
        DML.set(T.name.setTo(itemName), T.updated.setTo(t))
      )
    } yield n

  def updateDate(
      itemIds: NonEmptyList[Ident],
      coll: Ident,
      date: Option[Timestamp]
  ): ConnectionIO[Int] =
    for {
      t <- currentTime
      n <- DML.update(
        T,
        T.id.in(itemIds) && T.cid === coll,
        DML.set(T.itemDate.setTo(date), T.updated.setTo(t))
      )
    } yield n

  def updateDueDate(
      itemIds: NonEmptyList[Ident],
      coll: Ident,
      date: Option[Timestamp]
  ): ConnectionIO[Int] =
    for {
      t <- currentTime
      n <- DML.update(
        T,
        T.id.in(itemIds) && T.cid === coll,
        DML.set(T.dueDate.setTo(date), T.updated.setTo(t))
      )
    } yield n

  def deleteByIdAndCollective(itemId: Ident, coll: Ident): ConnectionIO[Int] =
    DML.delete(T, T.id === itemId && T.cid === coll)

  def setState(
      itemIds: NonEmptyList[Ident],
      coll: Ident,
      state: ItemState
  ): ConnectionIO[Int] =
    for {
      t <- currentTime
      n <- DML.update(
        T,
        T.id.in(itemIds) && T.cid === coll,
        DML.set(T.state.setTo(state), T.updated.setTo(t))
      )
    } yield n

  def existsById(itemId: Ident): ConnectionIO[Boolean] =
    Select(count(T.id).s, from(T), T.id === itemId).build.query[Int].unique.map(_ > 0)

  def existsByIdAndCollective(itemId: Ident, coll: Ident): ConnectionIO[Boolean] =
    Select(count(T.id).s, from(T), T.id === itemId && T.cid === coll).build
      .query[Int]
      .unique
      .map(_ > 0)

  def existsByIdsAndCollective(
      itemIds: NonEmptyList[Ident],
      coll: Ident
  ): ConnectionIO[Boolean] =
    Select(count(T.id).s, from(T), T.id.in(itemIds) && T.cid === coll).build
      .query[Int]
      .unique
      .map(_ == itemIds.size)

  def findByIdAndCollective(itemId: Ident, coll: Ident): ConnectionIO[Option[RItem]] =
    run(select(T.all), from(T), T.id === itemId && T.cid === coll).query[RItem].option

  def findById(itemId: Ident): ConnectionIO[Option[RItem]] =
    run(select(T.all), from(T), T.id === itemId).query[RItem].option

  def findDeleted(collective: Ident, chunkSize: Int): Stream[ConnectionIO, RItem] =
    run(select(T.all), from(T), T.cid === collective && T.state === ItemState.deleted)
      .query[RItem]
      .streamWithChunkSize(chunkSize)

  def checkByIdAndCollective(itemId: Ident, coll: Ident): ConnectionIO[Option[Ident]] =
    Select(T.id.s, from(T), T.id === itemId && T.cid === coll).build.query[Ident].option

  def removeFolder(folderId: Ident): ConnectionIO[Int] = {
    val empty: Option[Ident] = None
    DML.update(T, T.folder === folderId, DML.set(T.folder.setTo(empty)))
  }

  def filterItemsFragment(items: NonEmptyList[Ident], coll: Ident): Select =
    Select(select(T.id), from(T), T.cid === coll && T.id.in(items))

  def filterItems(items: NonEmptyList[Ident], coll: Ident): ConnectionIO[Vector[Ident]] =
    filterItemsFragment(items, coll).build.query[Ident].to[Vector]
}
