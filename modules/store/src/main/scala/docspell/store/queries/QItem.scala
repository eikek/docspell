/*
 * Copyright 2020 Docspell Contributors
 *
 * SPDX-License-Identifier: GPL-3.0-or-later
 */

package docspell.store.queries

import java.time.LocalDate

import cats.data.{NonEmptyList => Nel}
import cats.effect.Ref
import cats.effect.Sync
import cats.implicits._
import fs2.Stream

import docspell.common.syntax.all._
import docspell.common.{IdRef, _}
import docspell.query.ItemQuery
import docspell.store.Store
import docspell.store.qb.DSL._
import docspell.store.qb._
import docspell.store.qb.generator.{ItemQueryGenerator, Tables}
import docspell.store.records._

import doobie.implicits._
import doobie.{Query => _, _}
import org.log4s.getLogger

object QItem {
  private[this] val logger = getLogger

  private val equip = REquipment.as("e")
  private val org   = ROrganization.as("o")
  private val pers0 = RPerson.as("pers0")
  private val pers1 = RPerson.as("pers1")
  private val f     = RFolder.as("f")
  private val i     = RItem.as("i")
  private val cf    = RCustomField.as("cf")
  private val cv    = RCustomFieldValue.as("cvf")
  private val a     = RAttachment.as("a")
  private val m     = RAttachmentMeta.as("m")
  private val tag   = RTag.as("t")
  private val ti    = RTagItem.as("ti")

  def countAttachmentsAndItems(items: Nel[Ident]): ConnectionIO[Int] =
    Select(count(a.id).s, from(a), a.itemId.in(items)).build
      .query[Int]
      .unique
      .map(_ + items.size)

  def findItem(id: Ident): ConnectionIO[Option[ItemData]] = {
    val ref = RItem.as("ref")
    val cq =
      Select(
        select(i.all, org.all, pers0.all, pers1.all, equip.all)
          .append(ref.id.s)
          .append(ref.name.s)
          .append(f.id.s)
          .append(f.name.s),
        from(i)
          .leftJoin(org, org.oid === i.corrOrg)
          .leftJoin(pers0, pers0.pid === i.corrPerson)
          .leftJoin(pers1, pers1.pid === i.concPerson)
          .leftJoin(equip, equip.eid === i.concEquipment)
          .leftJoin(ref, ref.id === i.inReplyTo)
          .leftJoin(f, f.id === i.folder),
        i.id === id
      ).build

    val q = cq
      .query[
        (
            RItem,
            Option[ROrganization],
            Option[RPerson],
            Option[RPerson],
            Option[REquipment],
            Option[IdRef],
            Option[IdRef]
        )
      ]
      .option
    logger.trace(s"Find item query: $cq")
    val attachs      = RAttachment.findByItemWithMeta(id)
    val sources      = RAttachmentSource.findByItemWithMeta(id)
    val archives     = RAttachmentArchive.findByItemWithMeta(id)
    val tags         = RTag.findByItem(id)
    val customfields = findCustomFieldValuesForItem(id)

    for {
      data <- q
      att  <- attachs
      srcs <- sources
      arch <- archives
      ts   <- tags
      cfs  <- customfields
    } yield data.map(d =>
      ItemData(d._1, d._2, d._3, d._4, d._5, d._6, d._7, ts, att, srcs, arch, cfs)
    )
  }

  def findCustomFieldValuesForItem(
      itemId: Ident
  ): ConnectionIO[Vector[ItemFieldValue]] =
    Select(
      select(cf.id, cf.name, cf.label, cf.ftype, cv.value),
      from(cv)
        .innerJoin(cf, cf.id === cv.field),
      cv.itemId === itemId
    ).build.query[ItemFieldValue].to[Vector]

  private def findItemsBase(q: Query.Fix, today: LocalDate, noteMaxLen: Int): Select = {
    val coll = q.account.collective

    Select(
      select(
        i.id.s,
        i.name.s,
        i.state.s,
        coalesce(i.itemDate.s, i.created.s).s,
        i.dueDate.s,
        i.source.s,
        i.incoming.s,
        i.created.s,
        org.oid.s,
        org.name.s,
        pers0.pid.s,
        pers0.name.s,
        pers1.pid.s,
        pers1.name.s,
        equip.eid.s,
        equip.name.s,
        f.id.s,
        f.name.s,
        substring(i.notes.s, 1, noteMaxLen).s,
        q.orderAsc
          .map(of => coalesce(of(i).s, i.created.s).s)
          .getOrElse(i.created.s)
      ),
      from(i)
        .leftJoin(f, f.id === i.folder && f.collective === coll)
        .leftJoin(pers0, pers0.pid === i.corrPerson && pers0.cid === coll)
        .leftJoin(org, org.oid === i.corrOrg && org.cid === coll)
        .leftJoin(pers1, pers1.pid === i.concPerson && pers1.cid === coll)
        .leftJoin(equip, equip.eid === i.concEquipment && equip.cid === coll),
      where(
        i.cid === coll &&? q.query.map(qs => queryCondFromExpr(today, coll, qs))
          && or(
            i.folder.isNull,
            i.folder.in(QFolder.findMemberFolderIds(q.account))
          )
      )
    ).orderBy(
      q.orderAsc
        .map(of => OrderBy.asc(coalesce(of(i).s, i.created.s).s))
        .getOrElse(OrderBy.desc(coalesce(i.itemDate.s, i.created.s).s))
    )
  }

  def queryCondFromExpr(today: LocalDate, coll: Ident, q: ItemQuery.Expr): Condition = {
    val tables = Tables(i, org, pers0, pers1, equip, f, a, m, AttachCountTable("cta"))
    ItemQueryGenerator.fromExpr(today, tables, coll)(q)
  }

  def queryCondition(today: LocalDate, coll: Ident, cond: Query.QueryCond): Condition =
    cond match {
      case Query.QueryExpr(Some(expr)) =>
        queryCondFromExpr(today, coll, expr)
      case Query.QueryExpr(None) =>
        Condition.unit
    }

  def findItems(
      q: Query,
      today: LocalDate,
      maxNoteLen: Int,
      batch: Batch
  ): Stream[ConnectionIO, ListItem] = {
    val sql = findItemsBase(q.fix, today, maxNoteLen)
      .changeWhere(c => c && queryCondition(today, q.fix.account.collective, q.cond))
      .limit(batch)
      .build
    logger.trace(s"List $batch items: $sql")
    sql.query[ListItem].stream
  }

  def searchStats(today: LocalDate)(q: Query): ConnectionIO[SearchSummary] =
    for {
      count   <- searchCountSummary(today)(q)
      tags    <- searchTagSummary(today)(q)
      cats    <- searchTagCategorySummary(today)(q)
      fields  <- searchFieldSummary(today)(q)
      folders <- searchFolderSummary(today)(q)
    } yield SearchSummary(count, tags, cats, fields, folders)

  def searchTagCategorySummary(
      today: LocalDate
  )(q: Query): ConnectionIO[List[CategoryCount]] = {
    val tagFrom =
      from(ti)
        .innerJoin(tag, tag.tid === ti.tagId)
        .innerJoin(i, i.id === ti.itemId)

    val catCloud =
      findItemsBase(q.fix, today, 0).unwrap
        .withSelect(select(tag.category).append(countDistinct(i.id).as("num")))
        .changeFrom(_.prepend(tagFrom))
        .changeWhere(c => c && queryCondition(today, q.fix.account.collective, q.cond))
        .groupBy(tag.category)
        .build
        .query[CategoryCount]
        .to[List]

    for {
      existing <- catCloud
      allCats  <- RTag.listCategories(q.fix.account.collective)
      other = allCats.diff(existing.flatMap(_.category))
    } yield existing ++ other.map(n => CategoryCount(n.some, 0))
  }

  def searchTagSummary(today: LocalDate)(q: Query): ConnectionIO[List[TagCount]] = {
    val tagFrom =
      from(ti)
        .innerJoin(tag, tag.tid === ti.tagId)
        .innerJoin(i, i.id === ti.itemId)

    val tagCloud =
      findItemsBase(q.fix, today, 0).unwrap
        .withSelect(select(tag.all).append(countDistinct(i.id).as("num")))
        .changeFrom(_.prepend(tagFrom))
        .changeWhere(c => c && queryCondition(today, q.fix.account.collective, q.cond))
        .groupBy(tag.tid)
        .build
        .query[TagCount]
        .to[List]

    // the previous query starts from tags, so items with tag-count=0
    // are not included they are fetched separately
    for {
      existing <- tagCloud
      other    <- RTag.findOthers(q.fix.account.collective, existing.map(_.tag.tagId))
    } yield existing ++ other.map(TagCount(_, 0))
  }

  def searchCountSummary(today: LocalDate)(q: Query): ConnectionIO[Int] =
    findItemsBase(q.fix, today, 0).unwrap
      .withSelect(Nel.of(count(i.id).as("num")))
      .changeWhere(c => c && queryCondition(today, q.fix.account.collective, q.cond))
      .build
      .query[Int]
      .unique

  def searchFolderSummary(today: LocalDate)(q: Query): ConnectionIO[List[FolderCount]] = {
    val fu = RUser.as("fu")
    findItemsBase(q.fix, today, 0).unwrap
      .withSelect(select(f.id, f.name, f.owner, fu.login).append(count(i.id).as("num")))
      .changeFrom(_.innerJoin(fu, fu.uid === f.owner))
      .changeWhere(c => c && queryCondition(today, q.fix.account.collective, q.cond))
      .groupBy(f.id, f.name, f.owner, fu.login)
      .build
      .query[FolderCount]
      .to[List]
  }

  def searchFieldSummary(today: LocalDate)(q: Query): ConnectionIO[List[FieldStats]] = {
    val fieldJoin =
      from(cv)
        .innerJoin(cf, cf.id === cv.field)
        .innerJoin(i, i.id === cv.itemId)

    val base =
      findItemsBase(q.fix, today, 0).unwrap
        .changeFrom(_.prepend(fieldJoin))
        .changeWhere(c => c && queryCondition(today, q.fix.account.collective, q.cond))
        .groupBy(GroupBy(cf.all))

    val basicFields = Nel.of(
      count(i.id).as("fc"),
      const(0).as("favg"),
      const(0).as("fsum"),
      const(0).as("fmax"),
      const(0).as("fmin")
    )
    val valueNum = cast(cv.value.s, "decimal").s
    val numericFields = Nel.of(
      count(i.id).as("fc"),
      avg(valueNum).as("favg"),
      sum(valueNum).as("fsum"),
      max(valueNum).as("fmax"),
      min(valueNum).as("fmin")
    )

    val numTypes = Nel.of(CustomFieldType.money, CustomFieldType.numeric)
    val query =
      union(
        base
          .withSelect(select(cf.all).concatNel(basicFields))
          .changeWhere(c => c && cf.ftype.notIn(numTypes)),
        base
          .withSelect(select(cf.all).concatNel(numericFields))
          .changeWhere(c => c && cf.ftype.in(numTypes))
      ).build.query[FieldStats].to[List]

    val fallback = base
      .withSelect(select(cf.all).concatNel(basicFields))
      .build
      .query[FieldStats]
      .to[List]

    query.attemptSql.flatMap {
      case Right(res) => res.pure[ConnectionIO]
      case Left(ex) =>
        Logger
          .log4s[ConnectionIO](logger)
          .error(ex)(
            s"Calculating custom field summary failed. You may have invalid custom field values according to their type."
          ) *>
          fallback
    }
  }

  def findSelectedItems(
      q: Query,
      today: LocalDate,
      maxNoteLen: Int,
      items: Set[SelectedItem]
  ): Stream[ConnectionIO, ListItem] =
    if (items.isEmpty) Stream.empty
    else {
      val i = RItem.as("i")

      object Tids extends TableDef {
        val tableName = "tids"
        val alias     = Some("tw")
        val itemId    = Column[Ident]("item_id", this)
        val weight    = Column[Double]("weight", this)
        val all       = Vector[Column[_]](itemId, weight)
      }

      val cte =
        CteBind(
          Tids,
          Tids.all,
          Select.RawSelect(
            fr"VALUES" ++
              items
                .map(it => fr"(${it.itemId}, ${it.weight})")
                .reduce((r, e) => r ++ fr"," ++ e)
          )
        )

      val from = findItemsBase(q.fix, today, maxNoteLen)
        .appendCte(cte)
        .appendSelect(Tids.weight.s)
        .changeFrom(_.innerJoin(Tids, Tids.itemId === i.id))
        .orderBy(Tids.weight.desc)
        .build

      logger.trace(s"fts query: $from")
      from.query[ListItem].stream
    }

  /** Same as `findItems` but resolves the tags for each item. Note that this is
    * implemented by running an additional query per item.
    */
  def findItemsWithTags(
      collective: Ident,
      search: Stream[ConnectionIO, ListItem]
  ): Stream[ConnectionIO, ListItemWithTags] = {
    def findTag(
        cache: Ref[ConnectionIO, Map[Ident, RTag]],
        tagItem: RTagItem
    ): ConnectionIO[Option[RTag]] =
      for {
        cc <- cache.get
        fromCache = cc.get(tagItem.tagId)
        orFromDB <-
          if (fromCache.isDefined) fromCache.pure[ConnectionIO]
          else RTag.findById(tagItem.tagId)
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
      item         <- search
      tagItems     <- Stream.eval(RTagItem.findByItem(item.id))
      tags         <- Stream.eval(tagItems.traverse(ti => findTag(resolvedTags, ti)))
      attachs      <- Stream.eval(findAttachmentLight(item.id))
      ftags = tags.flatten.filter(t => t.collective == collective)
      cfields <- Stream.eval(findCustomFieldValuesForItem(item.id))
    } yield ListItemWithTags(
      item,
      ftags.toList.sortBy(_.name),
      attachs.sortBy(_.position),
      cfields.toList
    )
  }

  private def findAttachmentLight(item: Ident): ConnectionIO[List[AttachmentLight]] =
    Select(
      select(a.id, a.position, a.name, m.pages),
      from(a)
        .leftJoin(m, m.id === a.id),
      a.itemId === item
    ).build.query[AttachmentLight].to[List]

  def delete[F[_]: Sync](store: Store[F])(itemId: Ident, collective: Ident): F[Int] =
    for {
      rn <- QAttachment.deleteItemAttachments(store)(itemId, collective)
      tn <- store.transact(RTagItem.deleteItemTags(itemId))
      mn <- store.transact(RSentMail.deleteByItem(itemId))
      cf <- store.transact(RCustomFieldValue.deleteByItem(itemId))
      im <- store.transact(RItemProposal.deleteByItem(itemId))
      n  <- store.transact(RItem.deleteByIdAndCollective(itemId, collective))
    } yield tn + rn + n + mn + cf + im

  private def findByFileIdsQuery(
      fileMetaIds: Nel[Ident],
      states: Option[Nel[ItemState]]
  ): Select.SimpleSelect = {
    val i = RItem.as("i")
    val a = RAttachment.as("a")
    val s = RAttachmentSource.as("s")
    val r = RAttachmentArchive.as("r")

    Select(
      select(i.all),
      from(i)
        .innerJoin(a, a.itemId === i.id)
        .innerJoin(s, s.id === a.id)
        .leftJoin(r, r.id === a.id),
      (a.fileId.in(fileMetaIds) ||
        s.fileId.in(fileMetaIds) ||
        r.fileId.in(fileMetaIds)) &&? states.map(nel => i.state.in(nel))
    ).distinct
  }

  def findOneByFileIds(fileMetaIds: Seq[Ident]): ConnectionIO[Option[RItem]] =
    Nel.fromList(fileMetaIds.toList) match {
      case Some(nel) =>
        findByFileIdsQuery(nel, None).limit(1).build.query[RItem].option
      case None =>
        (None: Option[RItem]).pure[ConnectionIO]
    }

  def findByFileIds(
      fileMetaIds: Seq[Ident],
      states: Nel[ItemState]
  ): ConnectionIO[Vector[RItem]] =
    Nel.fromList(fileMetaIds.toList) match {
      case Some(nel) =>
        findByFileIdsQuery(nel, states.some).build.query[RItem].to[Vector]
      case None =>
        Vector.empty[RItem].pure[ConnectionIO]
    }

  def findByChecksum(
      checksum: String,
      collective: Ident,
      excludeFileMeta: Set[Ident]
  ): ConnectionIO[Vector[RItem]] = {
    val qq = findByChecksumQuery(checksum, collective, excludeFileMeta).build
    logger.debug(s"FindByChecksum: $qq")
    qq.query[RItem].to[Vector]
  }

  def findByChecksumQuery(
      checksum: String,
      collective: Ident,
      excludeFileMeta: Set[Ident]
  ): Select = {
    val m1  = RFileMeta.as("m1")
    val m2  = RFileMeta.as("m2")
    val m3  = RFileMeta.as("m3")
    val i   = RItem.as("i")
    val a   = RAttachment.as("a")
    val s   = RAttachmentSource.as("s")
    val r   = RAttachmentArchive.as("r")
    val fms = Nel.of(m1, m2, m3)
    Select(
      select(i.all),
      from(i)
        .innerJoin(a, a.itemId === i.id)
        .innerJoin(s, s.id === a.id)
        .innerJoin(m1, m1.id === a.fileId)
        .innerJoin(m2, m2.id === s.fileId)
        .leftJoin(r, r.id === a.id)
        .leftJoin(m3, m3.id === r.fileId),
      where(
        i.cid === collective &&
          i.state.in(ItemState.validStates) &&
          Condition.Or(fms.map(m => m.checksum === checksum)) &&?
          Nel
            .fromList(excludeFileMeta.toList)
            .map(excl => Condition.And(fms.map(m => m.id.isNull || m.id.notIn(excl))))
      )
    ).distinct
  }

  final case class NameAndNotes(
      id: Ident,
      collective: Ident,
      folder: Option[Ident],
      name: String,
      notes: Option[String]
  )
  def allNameAndNotes(
      coll: Option[Ident],
      itemIds: Option[Nel[Ident]],
      chunkSize: Int
  ): Stream[ConnectionIO, NameAndNotes] = {
    val i = RItem.as("i")

    Select(
      select(i.id, i.cid, i.folder, i.name, i.notes),
      from(i)
    ).where(
      i.state.in(ItemState.validStates) &&?
        itemIds.map(ids => i.id.in(ids)) &&?
        coll.map(cid => i.cid === cid)
    ).build
      .query[NameAndNotes]
      .streamWithChunkSize(chunkSize)
  }

  def findAllNewesFirst(
      collective: Ident,
      chunkSize: Int,
      limit: Batch
  ): Stream[ConnectionIO, Ident] = {
    val i = RItem.as("i")
    Select(i.id.s, from(i), i.cid === collective && i.state === ItemState.confirmed)
      .orderBy(i.created.desc)
      .limit(limit)
      .build
      .query[Ident]
      .streamWithChunkSize(chunkSize)
  }

  def resolveTextAndTag(
      collective: Ident,
      itemId: Ident,
      tagCategory: String,
      maxLen: Int,
      pageSep: String
  ): ConnectionIO[TextAndTag] = {
    val tags     = TableDef("tags").as("tt")
    val tagsItem = Column[Ident]("itemid", tags)
    val tagsTid  = Column[Ident]("tid", tags)
    val tagsName = Column[String]("tname", tags)

    readTextAndTag(collective, itemId, pageSep) {
      withCte(
        tags -> Select(
          select(ti.itemId.as(tagsItem), tag.tid.as(tagsTid), tag.name.as(tagsName)),
          from(ti)
            .innerJoin(tag, tag.tid === ti.tagId),
          ti.itemId === itemId && tag.category === tagCategory
        )
      )(
        Select(
          select(contentMax(maxLen), tagsTid.s, tagsName.s),
          from(i)
            .innerJoin(a, a.itemId === i.id)
            .innerJoin(m, a.id === m.id)
            .leftJoin(tags, tagsItem === i.id),
          i.id === itemId && i.cid === collective && m.content.isNotNull && m.content <> ""
        )
      )
    }
  }

  def resolveTextAndCorrOrg(
      collective: Ident,
      itemId: Ident,
      maxLen: Int,
      pageSep: String
  ): ConnectionIO[TextAndTag] =
    readTextAndTag(collective, itemId, pageSep) {
      Select(
        select(contentMax(maxLen), org.oid.s, org.name.s),
        from(i)
          .innerJoin(a, a.itemId === i.id)
          .innerJoin(m, m.id === a.id)
          .leftJoin(org, org.oid === i.corrOrg),
        i.id === itemId && m.content.isNotNull && m.content <> ""
      )
    }

  def resolveTextAndCorrPerson(
      collective: Ident,
      itemId: Ident,
      maxLen: Int,
      pageSep: String
  ): ConnectionIO[TextAndTag] =
    readTextAndTag(collective, itemId, pageSep) {
      Select(
        select(contentMax(maxLen), pers0.pid.s, pers0.name.s),
        from(i)
          .innerJoin(a, a.itemId === i.id)
          .innerJoin(m, m.id === a.id)
          .leftJoin(pers0, pers0.pid === i.corrPerson),
        i.id === itemId && m.content.isNotNull && m.content <> ""
      )
    }

  def resolveTextAndConcPerson(
      collective: Ident,
      itemId: Ident,
      maxLen: Int,
      pageSep: String
  ): ConnectionIO[TextAndTag] =
    readTextAndTag(collective, itemId, pageSep) {
      Select(
        select(contentMax(maxLen), pers0.pid.s, pers0.name.s),
        from(i)
          .innerJoin(a, a.itemId === i.id)
          .innerJoin(m, m.id === a.id)
          .leftJoin(pers0, pers0.pid === i.concPerson),
        i.id === itemId && m.content.isNotNull && m.content <> ""
      )
    }

  def resolveTextAndConcEquip(
      collective: Ident,
      itemId: Ident,
      maxLen: Int,
      pageSep: String
  ): ConnectionIO[TextAndTag] =
    readTextAndTag(collective, itemId, pageSep) {
      Select(
        select(contentMax(maxLen), equip.eid.s, equip.name.s),
        from(i)
          .innerJoin(a, a.itemId === i.id)
          .innerJoin(m, m.id === a.id)
          .leftJoin(equip, equip.eid === i.concEquipment),
        i.id === itemId && m.content.isNotNull && m.content <> ""
      )
    }

  private def contentMax(maxLen: Int): SelectExpr =
    if (maxLen <= 0) {
      logger.debug("Max text length limit disabled")
      m.content.s
    } else substring(m.content.s, 0, maxLen).s

  private def readTextAndTag(collective: Ident, itemId: Ident, pageSep: String)(
      q: Select
  ): ConnectionIO[TextAndTag] =
    for {
      _ <- logger.ftrace[ConnectionIO](
        s"query: $q  (${itemId.id}, ${collective.id})"
      )
      texts <- q.build.query[(String, Option[TextAndTag.TagName])].to[List]
      _ <- logger.ftrace[ConnectionIO](
        s"Got ${texts.size} text and tag entries for item ${itemId.id}"
      )
      tag = texts.headOption.flatMap(_._2)
      txt = texts.map(_._1).mkString(pageSep)
    } yield TextAndTag(itemId, txt, tag)

}
