package docspell.store.queries

import cats.data.OptionT
import cats.data.{NonEmptyList => Nel}
import cats.effect.Sync
import cats.effect.concurrent.Ref
import cats.implicits._
import fs2.Stream

import docspell.common.syntax.all._
import docspell.common.{IdRef, _}
import docspell.store.Store
import docspell.store.qb.DSL._
import docspell.store.qb._
import docspell.store.records._

import bitpeace.FileMeta
import doobie._
import doobie.implicits._
import org.log4s._

object QItem {
  private[this] val logger = getLogger

  def moveAttachmentBefore(
      itemId: Ident,
      source: Ident,
      target: Ident
  ): ConnectionIO[Int] = {

    // rs < rt
    def moveBack(rs: RAttachment, rt: RAttachment): ConnectionIO[Int] =
      for {
        n <- RAttachment.decPositions(itemId, rs.position, rt.position)
        k <- RAttachment.updatePosition(rs.id, rt.position)
      } yield n + k

    // rs > rt
    def moveForward(rs: RAttachment, rt: RAttachment): ConnectionIO[Int] =
      for {
        n <- RAttachment.incPositions(itemId, rt.position, rs.position)
        k <- RAttachment.updatePosition(rs.id, rt.position)
      } yield n + k

    (for {
      _ <- OptionT.liftF(
        if (source == target)
          Sync[ConnectionIO].raiseError(new Exception("Attachments are the same!"))
        else ().pure[ConnectionIO]
      )
      rs <- OptionT(RAttachment.findById(source)).filter(_.itemId == itemId)
      rt <- OptionT(RAttachment.findById(target)).filter(_.itemId == itemId)
      n <- OptionT.liftF(
        if (rs.position == rt.position || rs.position + 1 == rt.position)
          0.pure[ConnectionIO]
        else if (rs.position < rt.position) moveBack(rs, rt)
        else moveForward(rs, rt)
      )
    } yield n).getOrElse(0)

  }

  case class ItemFieldValue(
      fieldId: Ident,
      fieldName: Ident,
      fieldLabel: Option[String],
      fieldType: CustomFieldType,
      value: String
  )
  case class ItemData(
      item: RItem,
      corrOrg: Option[ROrganization],
      corrPerson: Option[RPerson],
      concPerson: Option[RPerson],
      concEquip: Option[REquipment],
      inReplyTo: Option[IdRef],
      folder: Option[IdRef],
      tags: Vector[RTag],
      attachments: Vector[(RAttachment, FileMeta)],
      sources: Vector[(RAttachmentSource, FileMeta)],
      archives: Vector[(RAttachmentArchive, FileMeta)],
      customFields: Vector[ItemFieldValue]
  ) {

    def filterCollective(coll: Ident): Option[ItemData] =
      if (item.cid == coll) Some(this) else None
  }

  def findItem(id: Ident): ConnectionIO[Option[ItemData]] = {
    val equip = REquipment.as("e")
    val org   = ROrganization.as("o")
    val pers0 = RPerson.as("p0")
    val pers1 = RPerson.as("p1")
    val f     = RFolder.as("f")
    val i     = RItem.as("i")
    val ref   = RItem.as("ref")

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
  ): ConnectionIO[Vector[ItemFieldValue]] = {
    val cf = RCustomField.as("cf")
    val cv = RCustomFieldValue.as("cvf")

    Select(
      select(cf.id, cf.name, cf.label, cf.ftype, cv.value),
      from(cv)
        .innerJoin(cf, cf.id === cv.field),
      cv.itemId === itemId
    ).build.query[ItemFieldValue].to[Vector]
  }

  case class ListItem(
      id: Ident,
      name: String,
      state: ItemState,
      date: Timestamp,
      dueDate: Option[Timestamp],
      source: String,
      direction: Direction,
      created: Timestamp,
      fileCount: Int,
      corrOrg: Option[IdRef],
      corrPerson: Option[IdRef],
      concPerson: Option[IdRef],
      concEquip: Option[IdRef],
      folder: Option[IdRef],
      notes: Option[String]
  )

  case class CustomValue(field: Ident, value: String)

  case class Query(
      account: AccountId,
      name: Option[String],
      states: Seq[ItemState],
      direction: Option[Direction],
      corrPerson: Option[Ident],
      corrOrg: Option[Ident],
      concPerson: Option[Ident],
      concEquip: Option[Ident],
      folder: Option[Ident],
      tagsInclude: List[Ident],
      tagsExclude: List[Ident],
      tagCategoryIncl: List[String],
      tagCategoryExcl: List[String],
      dateFrom: Option[Timestamp],
      dateTo: Option[Timestamp],
      dueDateFrom: Option[Timestamp],
      dueDateTo: Option[Timestamp],
      allNames: Option[String],
      itemIds: Option[Set[Ident]],
      customValues: Seq[CustomValue],
      source: Option[String],
      orderAsc: Option[RItem.Table => docspell.store.qb.Column[_]]
  )

  object Query {
    def empty(account: AccountId): Query =
      Query(
        account,
        None,
        Seq.empty,
        None,
        None,
        None,
        None,
        None,
        None,
        Nil,
        Nil,
        Nil,
        Nil,
        None,
        None,
        None,
        None,
        None,
        None,
        Seq.empty,
        None,
        None
      )
  }

  private def findCustomFieldValuesForColl(
      coll: Ident,
      values: Seq[CustomValue]
  ): Option[Select] = {
    val cf = RCustomField.as("cf")
    val cv = RCustomFieldValue.as("cv")

    def singleSelect(v: CustomValue) =
      Select(
        cv.itemId.s,
        from(cv).innerJoin(cf, cv.field === cf.id),
        where(
          cf.cid === coll &&
            (cf.name === v.field || cf.id === v.field) &&
            cv.value.like(QueryWildcard(v.value.toLowerCase))
        )
      )

    Nel
      .fromList(values.toList)
      .map(nel => intersect(nel.map(singleSelect)))
  }

  private def findItemsBase(q: Query, noteMaxLen: Int): Select = {
    object Attachs extends TableDef {
      val tableName = "attachs"
      val aliasName = "cta"
      val alias     = Some(aliasName)
      val num       = Column[Int]("num", this)
      val itemId    = Column[Ident]("item_id", this)
    }
    val equip = REquipment.as("e1")
    val org   = ROrganization.as("o0")
    val p0    = RPerson.as("p0")
    val p1    = RPerson.as("p1")
    val f     = RFolder.as("f1")
    val i     = RItem.as("i")
    val a     = RAttachment.as("a")

    val coll = q.account.collective

    val baseSelect = Select(
      select(
        i.id.s,
        i.name.s,
        i.state.s,
        coalesce(i.itemDate.s, i.created.s).s,
        i.dueDate.s,
        i.source.s,
        i.incoming.s,
        i.created.s,
        coalesce(Attachs.num.s, lit(0)).s,
        org.oid.s,
        org.name.s,
        p0.pid.s,
        p0.name.s,
        p1.pid.s,
        p1.name.s,
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
        .leftJoin(
          Select(
            select(countAll.as(Attachs.num), a.itemId.as(Attachs.itemId)),
            from(a)
              .innerJoin(i, i.id === a.itemId),
            i.cid === q.account.collective,
            GroupBy(a.itemId)
          ),
          Attachs.aliasName, //alias, todo improve dsl
          Attachs.itemId === i.id
        )
        .leftJoin(p0, p0.pid === i.corrPerson && p0.cid === coll)
        .leftJoin(org, org.oid === i.corrOrg && org.cid === coll)
        .leftJoin(p1, p1.pid === i.concPerson && p1.cid === coll)
        .leftJoin(equip, equip.eid === i.concEquipment && equip.cid === coll),
      where(
        i.cid === coll &&? Nel.fromList(q.states.toList).map(nel => i.state.in(nel)) &&
          or(i.folder.isNull, i.folder.in(QFolder.findMemberFolderIds(q.account)))
      )
    ).distinct.orderBy(
      q.orderAsc
        .map(of => OrderBy.asc(coalesce(of(i).s, i.created.s).s))
        .getOrElse(OrderBy.desc(coalesce(i.itemDate.s, i.created.s).s))
    )

    findCustomFieldValuesForColl(coll, q.customValues) match {
      case Some(itemIds) =>
        baseSelect.changeWhere(c => c && i.id.in(itemIds))
      case None =>
        baseSelect
    }
  }

  def findItems(
      q: Query,
      maxNoteLen: Int,
      batch: Batch
  ): Stream[ConnectionIO, ListItem] = {
    val equip = REquipment.as("e1")
    val org   = ROrganization.as("o0")
    val pers0 = RPerson.as("p0")
    val pers1 = RPerson.as("p1")
    val f     = RFolder.as("f1")
    val i     = RItem.as("i")

    val cond: Condition => Condition =
      c =>
        c &&?
          q.direction.map(d => i.incoming === d) &&?
          q.name.map(n => i.name.like(QueryWildcard.lower(n))) &&?
          q.allNames
            .map(QueryWildcard.lower)
            .map(n =>
              org.name.like(n) ||
                pers0.name.like(n) ||
                pers1.name.like(n) ||
                equip.name.like(n) ||
                i.name.like(n) ||
                i.notes.like(n)
            ) &&?
          q.corrPerson.map(p => pers0.pid === p) &&?
          q.corrOrg.map(o => org.oid === o) &&?
          q.concPerson.map(p => pers1.pid === p) &&?
          q.concEquip.map(e => equip.eid === e) &&?
          q.folder.map(fid => f.id === fid) &&?
          q.dateFrom.map(d => coalesce(i.itemDate.s, i.created.s) >= d) &&?
          q.dateTo.map(d => coalesce(i.itemDate.s, i.created.s) <= d) &&?
          q.dueDateFrom.map(d => i.dueDate > d) &&?
          q.dueDateTo.map(d => i.dueDate < d) &&?
          q.source.map(n => i.source.like(QueryWildcard.lower(n))) &&?
          q.itemIds.flatMap(s => Nel.fromList(s.toList)).map(nel => i.id.in(nel)) &&?
          TagItemName
            .itemsWithAllTagAndCategory(q.tagsInclude, q.tagCategoryIncl)
            .map(subsel => i.id.in(subsel)) &&?
          TagItemName
            .itemsWithEitherTagOrCategory(q.tagsExclude, q.tagCategoryExcl)
            .map(subsel => i.id.notIn(subsel))

    val sql = findItemsBase(q, maxNoteLen)
      .changeWhere(cond)
      .limit(batch)
      .build
    logger.trace(s"List $batch items: $sql")
    sql.query[ListItem].stream
  }

  case class SelectedItem(itemId: Ident, weight: Double)
  def findSelectedItems(
      q: Query,
      maxNoteLen: Int,
      items: Set[SelectedItem]
  ): Stream[ConnectionIO, ListItem] =
    if (items.isEmpty) Stream.empty
    else {
      val i = RItem.as("i")

      object Tids extends TableDef {
        val tableName             = "tids"
        val alias: Option[String] = Some("tw")
        val itemId                = Column[Ident]("item_id", this)
        val weight                = Column[Double]("weight", this)
        val all                   = Vector[Column[_]](itemId, weight)
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

      val from = findItemsBase(q, maxNoteLen)
        .appendCte(cte)
        .appendSelect(Tids.weight.s)
        .changeFrom(_.innerJoin(Tids, Tids.itemId === i.id))
        .orderBy(Tids.weight.desc)
        .build

      logger.trace(s"fts query: $from")
      from.query[ListItem].stream
    }

  case class AttachmentLight(
      id: Ident,
      position: Int,
      name: Option[String],
      pageCount: Option[Int]
  )
  case class ListItemWithTags(
      item: ListItem,
      tags: List[RTag],
      attachments: List[AttachmentLight],
      customfields: List[ItemFieldValue]
  )

  /** Same as `findItems` but resolves the tags for each item. Note that
    * this is implemented by running an additional query per item.
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

  private def findAttachmentLight(item: Ident): ConnectionIO[List[AttachmentLight]] = {
    val a = RAttachment.as("a")
    val m = RAttachmentMeta.as("m")

    Select(
      select(a.id, a.position, a.name, m.pages),
      from(a)
        .leftJoin(m, m.id === a.id),
      a.itemId === item
    ).build.query[AttachmentLight].to[List]
  }

  def delete[F[_]: Sync](store: Store[F])(itemId: Ident, collective: Ident): F[Int] =
    for {
      rn <- QAttachment.deleteItemAttachments(store)(itemId, collective)
      tn <- store.transact(RTagItem.deleteItemTags(itemId))
      mn <- store.transact(RSentMail.deleteByItem(itemId))
      cf <- store.transact(RCustomFieldValue.deleteByItem(itemId))
      n  <- store.transact(RItem.deleteByIdAndCollective(itemId, collective))
    } yield tn + rn + n + mn + cf

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
    )
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

  def findByChecksum(checksum: String, collective: Ident): ConnectionIO[Vector[RItem]] = {
    val m1 = RFileMeta.as("m1")
    val m2 = RFileMeta.as("m2")
    val m3 = RFileMeta.as("m3")
    val i  = RItem.as("i")
    val a  = RAttachment.as("a")
    val s  = RAttachmentSource.as("s")
    val r  = RAttachmentArchive.as("r")

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
          (m1.checksum === checksum || m2.checksum === checksum || m3.checksum === checksum)
      )
    ).build.query[RItem].to[Vector]
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
      chunkSize: Int
  ): Stream[ConnectionIO, NameAndNotes] = {
    val i = RItem.as("i")

    Select(
      select(i.id, i.cid, i.folder, i.name, i.notes),
      from(i)
    ).where(coll.map(cid => i.cid === cid))
      .build
      .query[NameAndNotes]
      .streamWithChunkSize(chunkSize)
  }

  def findAllNewesFirst(
      collective: Ident,
      chunkSize: Int
  ): Stream[ConnectionIO, Ident] = {
    val i = RItem.as("i")
    Select(i.id.s, from(i), i.cid === collective && i.state === ItemState.confirmed)
      .orderBy(i.created.desc)
      .build
      .query[Ident]
      .streamWithChunkSize(chunkSize)
  }

  case class TagName(id: Ident, name: String)
  case class TextAndTag(itemId: Ident, text: String, tag: Option[TagName])

  def resolveTextAndTag(
      collective: Ident,
      itemId: Ident,
      tagCategory: String,
      pageSep: String
  ): ConnectionIO[TextAndTag] = {
    val tag = RTag.as("t")
    val a   = RAttachment.as("a")
    val am  = RAttachmentMeta.as("m")
    val ti  = RTagItem.as("ti")
    val i   = RItem.as("i")

    val tags     = TableDef("tags").as("tt")
    val tagsItem = Column[Ident]("itemid", tags)
    val tagsTid  = Column[Ident]("tid", tags)
    val tagsName = Column[String]("tname", tags)

    val q =
      withCte(
        tags -> Select(
          select(ti.itemId.as(tagsItem), tag.tid.as(tagsTid), tag.name.as(tagsName)),
          from(ti)
            .innerJoin(tag, tag.tid === ti.tagId),
          ti.itemId === itemId && tag.category === tagCategory
        )
      )(
        Select(
          select(am.content, tagsTid, tagsName),
          from(i)
            .innerJoin(a, a.itemId === i.id)
            .innerJoin(am, a.id === am.id)
            .leftJoin(tags, tagsItem === i.id),
          i.id === itemId && i.cid === collective && am.content.isNotNull && am.content <> ""
        )
      ).build

    for {
      _ <- logger.ftrace[ConnectionIO](
        s"query: $q  (${itemId.id}, ${collective.id}, ${tagCategory})"
      )
      texts <- q.query[(String, Option[TagName])].to[List]
      _ <- logger.ftrace[ConnectionIO](
        s"Got ${texts.size} text and tag entries for item ${itemId.id}"
      )
      tag = texts.headOption.flatMap(_._2)
      txt = texts.map(_._1).mkString(pageSep)
    } yield TextAndTag(itemId, txt, tag)
  }

}
