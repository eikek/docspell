/*
 * Copyright 2020 Eike K. & Contributors
 *
 * SPDX-License-Identifier: AGPL-3.0-or-later
 */

package docspell.store.records

import cats.data.{NonEmptyList, OptionT}
import fs2.Stream

import docspell.common._
import docspell.store.qb.DSL._
import docspell.store.qb._

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
  final case class Table(alias: Option[String]) extends TableDef {
    val tableName = "collective"

    val id = Column[Ident]("cid", this)
    val state = Column[CollectiveState]("state", this)
    val language = Column[Language]("doclang", this)
    val integration = Column[Boolean]("integration_enabled", this)
    val created = Column[Timestamp]("created", this)

    val all = NonEmptyList.of[Column[_]](id, state, language, integration, created)
  }

  def makeDefault(collName: Ident, created: Timestamp): RCollective =
    RCollective(collName, CollectiveState.Active, Language.German, true, created)

  val T = Table(None)
  def as(alias: String): Table =
    Table(Some(alias))

  def insert(value: RCollective): ConnectionIO[Int] =
    DML.insert(
      T,
      T.all,
      fr"${value.id},${value.state},${value.language},${value.integrationEnabled},${value.created}"
    )

  def update(value: RCollective): ConnectionIO[Int] =
    DML.update(
      T,
      T.id === value.id,
      DML.set(
        T.state.setTo(value.state)
      )
    )

  def findLanguage(cid: Ident): ConnectionIO[Option[Language]] =
    Select(T.language.s, from(T), T.id === cid).build.query[Option[Language]].unique

  def updateLanguage(cid: Ident, lang: Language): ConnectionIO[Int] =
    DML.update(T, T.id === cid, DML.set(T.language.setTo(lang)))

  def updateSettings(cid: Ident, settings: Settings): ConnectionIO[Int] =
    for {
      n1 <- DML.update(
        T,
        T.id === cid,
        DML.set(
          T.language.setTo(settings.language),
          T.integration.setTo(settings.integrationEnabled)
        )
      )
      now <- Timestamp.current[ConnectionIO]
      n2 <- settings.classifier match {
        case Some(cls) =>
          RClassifierSetting.update(cls.toRecord(cid, now))
        case None =>
          RClassifierSetting.delete(cid)
      }
      n3 <- settings.emptyTrash match {
        case Some(trash) =>
          REmptyTrashSetting.update(trash.toRecord(cid, now))
        case None =>
          REmptyTrashSetting.delete(cid)
      }
      n4 <- RCollectivePassword.replaceAll(cid, settings.passwords)
    } yield n1 + n2 + n3 + n4

  // this hides categories that have been deleted in the meantime
  // they are finally removed from the json array once the learn classifier task is run
  def getSettings(coll: Ident): ConnectionIO[Option[Settings]] =
    (for {
      sett <- OptionT(getRawSettings(coll))
      prev <- OptionT.fromOption[ConnectionIO](sett.classifier)
      cats <- OptionT.liftF(RTag.listCategories(coll))
      next = prev.copy(categories = prev.categories.intersect(cats))
      pws <- OptionT.liftF(RCollectivePassword.findAll(coll))
    } yield sett.copy(classifier = Some(next), passwords = pws.map(_.password))).value

  private def getRawSettings(coll: Ident): ConnectionIO[Option[Settings]] = {
    import RClassifierSetting.stringListMeta

    val c = RCollective.as("c")
    val cs = RClassifierSetting.as("cs")
    val es = REmptyTrashSetting.as("es")

    Select(
      select(
        c.language.s,
        c.integration.s,
        cs.schedule.s,
        cs.itemCount.s,
        cs.categories.s,
        cs.listType.s,
        es.schedule.s,
        es.minAge.s,
        const(0) //dummy value to load Nil as list of passwords
      ),
      from(c).leftJoin(cs, cs.cid === c.id).leftJoin(es, es.cid === c.id),
      c.id === coll
    ).build.query[Settings].option
  }

  def findById(cid: Ident): ConnectionIO[Option[RCollective]] = {
    val sql = run(select(T.all), from(T), T.id === cid)
    sql.query[RCollective].option
  }

  def findByItem(itemId: Ident): ConnectionIO[Option[RCollective]] = {
    val i = RItem.as("i")
    val c = RCollective.as("c")
    Select(
      select(c.all),
      from(i).innerJoin(c, i.cid === c.id),
      i.id === itemId
    ).build.query[RCollective].option
  }

  def existsById(cid: Ident): ConnectionIO[Boolean] = {
    val sql = Select(count(T.id).s, from(T), T.id === cid).build
    sql.query[Int].unique.map(_ > 0)
  }

  def findAll(order: Table => Column[_]): ConnectionIO[Vector[RCollective]] = {
    val sql = Select(select(T.all), from(T)).orderBy(order(T))
    sql.build.query[RCollective].to[Vector]
  }

  def streamAll(order: Table => Column[_]): Stream[ConnectionIO, RCollective] = {
    val sql = Select(select(T.all), from(T)).orderBy(order(T))
    sql.build.query[RCollective].stream
  }

  def findByAttachment(attachId: Ident): ConnectionIO[Option[RCollective]] = {
    val i = RItem.as("i")
    val a = RAttachment.as("a")
    val c = RCollective.as("c")
    Select(
      select(c.all),
      from(c)
        .innerJoin(i, c.id === i.cid)
        .innerJoin(a, a.itemId === i.id),
      a.id === attachId
    ).build.query[RCollective].option
  }

  case class Settings(
      language: Language,
      integrationEnabled: Boolean,
      classifier: Option[RClassifierSetting.Classifier],
      emptyTrash: Option[REmptyTrashSetting.EmptyTrash],
      passwords: List[Password]
  )

  implicit val passwordListMeta: Read[List[Password]] =
    Read[Int].map(_ => Nil: List[Password])

}
