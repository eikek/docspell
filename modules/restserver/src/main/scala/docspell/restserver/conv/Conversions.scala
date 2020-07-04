package docspell.restserver.conv

import java.time.{LocalDate, ZoneId}

import cats.effect.{Effect, Sync}
import cats.implicits._
import fs2.Stream

import docspell.backend.ops.OCollective.{InsightData, PassChangeResult}
import docspell.backend.ops.OJob.JobCancelResult
import docspell.backend.ops.OUpload.{UploadData, UploadMeta, UploadResult}
import docspell.backend.ops._
import docspell.common._
import docspell.common.syntax.all._
import docspell.ftsclient.FtsResult
import docspell.restapi.model._
import docspell.restserver.conv.Conversions._
import docspell.store.AddResult
import docspell.store.records._

import bitpeace.FileMeta
import org.http4s.headers.`Content-Type`
import org.http4s.multipart.Multipart
import org.log4s.Logger

trait Conversions {

  // insights
  def mkItemInsights(d: InsightData): ItemInsights =
    ItemInsights(
      d.incoming,
      d.outgoing,
      d.bytes,
      TagCloud(d.tags.toList.map(p => NameCount(p._1, p._2)))
    )

  // attachment meta
  def mkAttachmentMeta(rm: RAttachmentMeta): AttachmentMeta =
    AttachmentMeta(
      rm.content.getOrElse(""),
      rm.nerlabels.map(nl => Label(nl.tag, nl.label, nl.startPosition, nl.endPosition)),
      mkItemProposals(rm.proposals)
    )

  // item proposal
  def mkItemProposals(ml: MetaProposalList): ItemProposals = {
    def get(mpt: MetaProposalType) =
      ml.find(mpt).map(mp => mp.values.toList.map(_.ref).map(mkIdName)).getOrElse(Nil)
    def getDates(mpt: MetaProposalType): List[Timestamp] =
      ml.find(mpt)
        .map(mp =>
          mp.values.toList
            .map(cand => cand.ref.id.id)
            .flatMap(str => Either.catchNonFatal(LocalDate.parse(str)).toOption)
            .map(_.atTime(12, 0).atZone(ZoneId.of("GMT")))
            .map(zdt => Timestamp(zdt.toInstant))
        )
        .getOrElse(Nil)
        .distinct
        .take(5)

    ItemProposals(
      corrOrg = get(MetaProposalType.CorrOrg),
      corrPerson = get(MetaProposalType.CorrPerson),
      concPerson = get(MetaProposalType.ConcPerson),
      concEquipment = get(MetaProposalType.ConcEquip),
      itemDate = getDates(MetaProposalType.DocDate),
      dueDate = getDates(MetaProposalType.DueDate)
    )
  }

  // item detail
  def mkItemDetail(data: OItemSearch.ItemData): ItemDetail =
    ItemDetail(
      data.item.id,
      data.item.direction,
      data.item.name,
      data.item.source,
      data.item.state,
      data.item.created,
      data.item.updated,
      data.item.itemDate,
      data.corrOrg.map(o => IdName(o.oid, o.name)),
      data.corrPerson.map(p => IdName(p.pid, p.name)),
      data.concPerson.map(p => IdName(p.pid, p.name)),
      data.concEquip.map(e => IdName(e.eid, e.name)),
      data.inReplyTo.map(mkIdName),
      data.item.dueDate,
      data.item.notes,
      data.attachments.map((mkAttachment(data) _).tupled).toList,
      data.sources.map((mkAttachmentSource _).tupled).toList,
      data.archives.map((mkAttachmentArchive _).tupled).toList,
      data.tags.map(mkTag).toList
    )

  def mkAttachment(
      item: OItemSearch.ItemData
  )(ra: RAttachment, m: FileMeta): Attachment = {
    val converted =
      item.sources.find(_._1.id == ra.id).exists(_._2.checksum != m.checksum)
    Attachment(ra.id, ra.name, m.length, MimeType.unsafe(m.mimetype.asString), converted)
  }

  def mkAttachmentSource(ra: RAttachmentSource, m: FileMeta): AttachmentSource =
    AttachmentSource(ra.id, ra.name, m.length, MimeType.unsafe(m.mimetype.asString))

  def mkAttachmentArchive(ra: RAttachmentArchive, m: FileMeta): AttachmentSource =
    AttachmentSource(ra.id, ra.name, m.length, MimeType.unsafe(m.mimetype.asString))

  // item list

  def mkQuery(m: ItemSearch, coll: Ident): OItemSearch.Query =
    OItemSearch.Query(
      coll,
      m.name,
      if (m.inbox) Seq(ItemState.Created)
      else ItemState.validStates.toList,
      m.direction,
      m.corrPerson,
      m.corrOrg,
      m.concPerson,
      m.concEquip,
      m.tagsInclude.map(Ident.unsafe),
      m.tagsExclude.map(Ident.unsafe),
      m.dateFrom,
      m.dateUntil,
      m.dueDateFrom,
      m.dueDateUntil,
      m.allNames,
      None,
      None
    )

  def mkItemList(v: Vector[OItemSearch.ListItem]): ItemLightList = {
    val groups = v.groupBy(item => item.date.toUtcDate.toString.substring(0, 7))

    def mkGroup(g: (String, Vector[OItemSearch.ListItem])): ItemLightGroup =
      ItemLightGroup(g._1, g._2.map(mkItemLight).toList)

    val gs =
      groups.map(mkGroup _).toList.sortWith((g1, g2) => g1.name.compareTo(g2.name) >= 0)
    ItemLightList(gs)
  }

  def mkItemListFts(v: Vector[OFulltext.FtsItem]): ItemLightList = {
    val groups = v.groupBy(item => item.item.date.toUtcDate.toString.substring(0, 7))

    def mkGroup(g: (String, Vector[OFulltext.FtsItem])): ItemLightGroup =
      ItemLightGroup(g._1, g._2.map(mkItemLight).toList)

    val gs =
      groups.map(mkGroup _).toList.sortWith((g1, g2) => g1.name.compareTo(g2.name) >= 0)
    ItemLightList(gs)
  }

  def mkItemListWithTags(v: Vector[OItemSearch.ListItemWithTags]): ItemLightList = {
    val groups = v.groupBy(ti => ti.item.date.toUtcDate.toString.substring(0, 7))

    def mkGroup(g: (String, Vector[OItemSearch.ListItemWithTags])): ItemLightGroup =
      ItemLightGroup(g._1, g._2.map(mkItemLightWithTags).toList)

    val gs =
      groups.map(mkGroup _).toList.sortWith((g1, g2) => g1.name.compareTo(g2.name) >= 0)
    ItemLightList(gs)
  }

  def mkItemListWithTagsFts(v: Vector[OFulltext.FtsItemWithTags]): ItemLightList = {
    val groups = v.groupBy(ti => ti.item.item.date.toUtcDate.toString.substring(0, 7))

    def mkGroup(g: (String, Vector[OFulltext.FtsItemWithTags])): ItemLightGroup =
      ItemLightGroup(g._1, g._2.map(mkItemLightWithTags).toList)

    val gs =
      groups.map(mkGroup _).toList.sortWith((g1, g2) => g1.name.compareTo(g2.name) >= 0)
    ItemLightList(gs)
  }

  def mkItemListWithTagsFtsPlain(v: Vector[OFulltext.FtsItemWithTags]): ItemLightList =
    if (v.isEmpty) ItemLightList(Nil)
    else ItemLightList(List(ItemLightGroup("Results", v.map(mkItemLightWithTags).toList)))

  def mkItemLight(i: OItemSearch.ListItem): ItemLight =
    ItemLight(
      i.id,
      i.name,
      i.state,
      i.date,
      i.dueDate,
      i.source,
      i.direction.name.some,
      i.corrOrg.map(mkIdName),
      i.corrPerson.map(mkIdName),
      i.concPerson.map(mkIdName),
      i.concEquip.map(mkIdName),
      i.fileCount,
      Nil,
      Nil
    )

  def mkItemLight(i: OFulltext.FtsItem): ItemLight = {
    val il        = mkItemLight(i.item)
    val highlight = mkHighlight(i.ftsData)
    il.copy(highlighting = highlight)
  }

  def mkItemLightWithTags(i: OItemSearch.ListItemWithTags): ItemLight =
    mkItemLight(i.item).copy(tags = i.tags.map(mkTag))

  def mkItemLightWithTags(i: OFulltext.FtsItemWithTags): ItemLight = {
    val il        = mkItemLightWithTags(i.item)
    val highlight = mkHighlight(i.ftsData)
    il.copy(highlighting = highlight)
  }

  private def mkHighlight(ftsData: OFulltext.FtsData): List[HighlightEntry] =
    ftsData.items.filter(_.context.nonEmpty).sortBy(-_.score).map { fdi =>
      fdi.matchData match {
        case FtsResult.AttachmentData(_, aName) =>
          HighlightEntry(aName, fdi.context)
        case FtsResult.ItemData =>
          HighlightEntry("Item", fdi.context)
      }
    }

  // job
  def mkJobQueueState(state: OJob.CollectiveQueueState): JobQueueState = {
    def desc(f: JobDetail => Option[Timestamp])(j1: JobDetail, j2: JobDetail): Boolean = {
      val t1 = f(j1).getOrElse(Timestamp.Epoch)
      val t2 = f(j2).getOrElse(Timestamp.Epoch)
      t1.value.isAfter(t2.value)
    }
    def asc(f: JobDetail => Option[Timestamp])(j1: JobDetail, j2: JobDetail): Boolean = {
      val t1 = f(j1).getOrElse(Timestamp.Epoch)
      val t2 = f(j2).getOrElse(Timestamp.Epoch)
      t1.value.isBefore(t2.value)
    }
    JobQueueState(
      state.running.map(mkJobDetail).toList.sortWith(asc(_.started)),
      state.done.map(mkJobDetail).toList.sortWith(desc(_.finished)),
      state.queued.map(mkJobDetail).toList.sortWith(asc(_.submitted.some))
    )
  }

  def mkJobDetail(jd: OJob.JobDetail): JobDetail =
    JobDetail(
      jd.job.id,
      jd.job.subject,
      jd.job.submitted,
      jd.job.priority,
      jd.job.state,
      jd.job.retries,
      jd.logs.map(mkJobLog).toList,
      jd.job.progress,
      jd.job.worker,
      jd.job.started,
      jd.job.finished
    )

  def mkJobLog(jl: RJobLog): JobLogEvent =
    JobLogEvent(jl.created, jl.level, jl.message)

  // upload
  def readMultipart[F[_]: Effect](
      mp: Multipart[F],
      logger: Logger,
      prio: Priority,
      validFileTypes: Seq[MimeType]
  ): F[UploadData[F]] = {
    def parseMeta(body: Stream[F, Byte]): F[ItemUploadMeta] =
      body
        .through(fs2.text.utf8Decode)
        .parseJsonAs[ItemUploadMeta]
        .map(
          _.fold(
            ex => {
              logger.error(ex)("Reading upload metadata failed.")
              throw ex
            },
            identity
          )
        )

    val meta: F[(Boolean, UploadMeta)] = mp.parts
      .find(_.name.exists(_.equalsIgnoreCase("meta")))
      .map(p => parseMeta(p.body))
      .map(fm =>
        fm.map(m => (m.multiple, UploadMeta(m.direction, "webapp", validFileTypes)))
      )
      .getOrElse((true, UploadMeta(None, "webapp", validFileTypes)).pure[F])

    val files = mp.parts
      .filter(p => p.name.forall(s => !s.equalsIgnoreCase("meta")))
      .map(p =>
        OUpload
          .File(p.filename, p.headers.get(`Content-Type`).map(fromContentType), p.body)
      )
    for {
      metaData <- meta
      _        <- Effect[F].delay(logger.debug(s"Parsed upload meta data: $metaData"))
      tracker  <- Ident.randomId[F]
    } yield UploadData(metaData._1, metaData._2, files, prio, Some(tracker))
  }

  // organization and person
  def mkOrg(v: OOrganization.OrgAndContacts): Organization = {
    val ro = v.org
    Organization(
      ro.oid,
      ro.name,
      Address(ro.street, ro.zip, ro.city, ro.country),
      v.contacts.map(mkContact).toList,
      ro.notes,
      ro.created
    )
  }

  def newOrg[F[_]: Sync](v: Organization, cid: Ident): F[OOrganization.OrgAndContacts] = {
    def contacts(oid: Ident) =
      v.contacts.traverse(c => newContact(c, oid.some, None))
    for {
      now  <- Timestamp.current[F]
      oid  <- Ident.randomId[F]
      cont <- contacts(oid)
      org = ROrganization(
        oid,
        cid,
        v.name,
        v.address.street,
        v.address.zip,
        v.address.city,
        v.address.country,
        v.notes,
        now
      )
    } yield OOrganization.OrgAndContacts(org, cont)
  }

  def changeOrg[F[_]: Sync](
      v: Organization,
      cid: Ident
  ): F[OOrganization.OrgAndContacts] = {
    def contacts(oid: Ident) =
      v.contacts.traverse(c => newContact(c, oid.some, None))
    for {
      cont <- contacts(v.id)
      org = ROrganization(
        v.id,
        cid,
        v.name,
        v.address.street,
        v.address.zip,
        v.address.city,
        v.address.country,
        v.notes,
        v.created
      )
    } yield OOrganization.OrgAndContacts(org, cont)
  }

  def mkPerson(v: OOrganization.PersonAndContacts): Person = {
    val ro = v.person
    Person(
      ro.pid,
      ro.name,
      Address(ro.street, ro.zip, ro.city, ro.country),
      v.contacts.map(mkContact).toList,
      ro.notes,
      ro.concerning,
      ro.created
    )
  }

  def newPerson[F[_]: Sync](v: Person, cid: Ident): F[OOrganization.PersonAndContacts] = {
    def contacts(pid: Ident) =
      v.contacts.traverse(c => newContact(c, None, pid.some))
    for {
      now  <- Timestamp.current[F]
      pid  <- Ident.randomId[F]
      cont <- contacts(pid)
      org = RPerson(
        pid,
        cid,
        v.name,
        v.address.street,
        v.address.zip,
        v.address.city,
        v.address.country,
        v.notes,
        v.concerning,
        now
      )
    } yield OOrganization.PersonAndContacts(org, cont)
  }

  def changePerson[F[_]: Sync](
      v: Person,
      cid: Ident
  ): F[OOrganization.PersonAndContacts] = {
    def contacts(pid: Ident) =
      v.contacts.traverse(c => newContact(c, None, pid.some))
    for {
      cont <- contacts(v.id)
      org = RPerson(
        v.id,
        cid,
        v.name,
        v.address.street,
        v.address.zip,
        v.address.city,
        v.address.country,
        v.notes,
        v.concerning,
        v.created
      )
    } yield OOrganization.PersonAndContacts(org, cont)
  }

  // contact
  def mkContact(rc: RContact): Contact =
    Contact(rc.contactId, rc.value, rc.kind)

  def newContact[F[_]: Sync](
      c: Contact,
      oid: Option[Ident],
      pid: Option[Ident]
  ): F[RContact] =
    timeId.map {
      case (id, now) =>
        RContact(id, c.value, c.kind, pid, oid, now)
    }

  // users
  def mkUser(ru: RUser): User =
    User(
      ru.uid,
      ru.login,
      ru.state,
      None,
      ru.email,
      ru.lastLogin,
      ru.loginCount,
      ru.created
    )

  def newUser[F[_]: Sync](u: User, cid: Ident): F[RUser] =
    timeId.map {
      case (id, now) =>
        RUser(
          id,
          u.login,
          cid,
          u.password.getOrElse(Password.empty),
          u.state,
          u.email,
          0,
          None,
          now
        )
    }

  def changeUser(u: User, cid: Ident): RUser =
    RUser(
      u.id,
      u.login,
      cid,
      u.password.getOrElse(Password.empty),
      u.state,
      u.email,
      u.loginCount,
      u.lastLogin,
      u.created
    )

  // tags

  def mkTag(rt: RTag): Tag =
    Tag(rt.tagId, rt.name, rt.category, rt.created)

  def newTag[F[_]: Sync](t: Tag, cid: Ident): F[RTag] =
    timeId.map {
      case (id, now) =>
        RTag(id, cid, t.name, t.category, now)
    }

  def changeTag(t: Tag, cid: Ident): RTag =
    RTag(t.id, cid, t.name, t.category, t.created)

  // sources

  def mkSource(s: RSource): Source =
    Source(s.sid, s.abbrev, s.description, s.counter, s.enabled, s.priority, s.created)

  def newSource[F[_]: Sync](s: Source, cid: Ident): F[RSource] =
    timeId.map({
      case (id, now) =>
        RSource(id, cid, s.abbrev, s.description, 0, s.enabled, s.priority, now)
    })

  def changeSource[F[_]: Sync](s: Source, coll: Ident): RSource =
    RSource(
      s.id,
      coll,
      s.abbrev,
      s.description,
      s.counter,
      s.enabled,
      s.priority,
      s.created
    )

  // equipment
  def mkEquipment(re: REquipment): Equipment =
    Equipment(re.eid, re.name, re.created)

  def newEquipment[F[_]: Sync](e: Equipment, cid: Ident): F[REquipment] =
    timeId.map({
      case (id, now) =>
        REquipment(id, cid, e.name, now)
    })

  def changeEquipment(e: Equipment, cid: Ident): REquipment =
    REquipment(e.id, cid, e.name, e.created)

  // idref

  def mkIdName(ref: IdRef): IdName =
    IdName(ref.id, ref.name)

  // basic result

  def basicResult(cr: JobCancelResult): BasicResult =
    cr match {
      case JobCancelResult.JobNotFound => BasicResult(false, "Job not found")
      case JobCancelResult.CancelRequested =>
        BasicResult(true, "Cancel was requested at the job executor")
      case JobCancelResult.Removed =>
        BasicResult(true, "The job has been removed from the queue.")
    }

  def basicResult(ar: AddResult, successMsg: String): BasicResult =
    ar match {
      case AddResult.Success           => BasicResult(true, successMsg)
      case AddResult.EntityExists(msg) => BasicResult(false, msg)
      case AddResult.Failure(ex) =>
        BasicResult(false, s"Internal error: ${ex.getMessage}")
    }

  def basicResult(ur: OUpload.UploadResult): BasicResult =
    ur match {
      case UploadResult.Success  => BasicResult(true, "Files submitted.")
      case UploadResult.NoFiles  => BasicResult(false, "There were no files to submit.")
      case UploadResult.NoSource => BasicResult(false, "The source id is not valid.")
      case UploadResult.NoItem   => BasicResult(false, "The item could not be found.")
    }

  def basicResult(cr: PassChangeResult): BasicResult =
    cr match {
      case PassChangeResult.Success => BasicResult(true, "Password changed.")
      case PassChangeResult.UpdateFailed =>
        BasicResult(false, "The database update failed.")
      case PassChangeResult.PasswordMismatch =>
        BasicResult(false, "The current password is incorrect.")
      case PassChangeResult.UserNotFound => BasicResult(false, "User not found.")
    }

  def basicResult(e: Either[Throwable, _], successMsg: String): BasicResult =
    e match {
      case Right(_) => BasicResult(true, successMsg)
      case Left(ex) => BasicResult(false, ex.getMessage)
    }

  // MIME Type

  def fromContentType(header: `Content-Type`): MimeType =
    MimeType(
      header.mediaType.mainType,
      header.mediaType.subType,
      header.mediaType.extensions
    )
}

object Conversions extends Conversions {

  private def timeId[F[_]: Sync]: F[(Ident, Timestamp)] =
    for {
      id  <- Ident.randomId[F]
      now <- Timestamp.current
    } yield (id, now)
}
