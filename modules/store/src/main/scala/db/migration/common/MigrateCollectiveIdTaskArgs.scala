package db.migration.common

import cats.syntax.all._
import cats.effect._
import docspell.common._
import docspell.store.records.{RCollective, RJob, RPeriodicTask, RUser}
import doobie._
import doobie.implicits._
import db.migration.data.{
  AllPreviewsArgs => AllPreviewArgsLegacy,
  ConvertAllPdfArgs => ConvertAllPdfArgsLegacy,
  DownloadZipArgs => DownloadZipArgsLegacy,
  EmptyTrashArgs => EmptyTrashArgsLegacy,
  FileIntegrityCheckArgs => FileIntegrityCheckArgsLegacy,
  ItemAddonTaskArgs => ItemAddonTaskArgsLegacy,
  LearnClassifierArgs => LearnClassifierArgsLegacy,
  PeriodicDueItemsArgs => PeriodicDueItemsArgsLegacy,
  PeriodicQueryArgs => PeriodicQueryArgsLegacy,
  ProcessItemArgs => ProcessItemArgsLegacy,
  ReIndexTaskArgs => ReIndexTaskArgsLegacy,
  ScanMailboxArgs => ScanMailboxArgsLegacy,
  ScheduledAddonTaskArgs => ScheduledAddonTaskArgsLegacy
}
import docspell.notification.api.{PeriodicDueItemsArgs, PeriodicQueryArgs}
import docspell.store.qb._
import docspell.store.qb.DSL._
import io.circe.{Decoder, Encoder, parser}
import org.flywaydb.core.api.migration.Context

object MigrateCollectiveIdTaskArgs extends TransactorSupport {

  val logger = docspell.logging.getLogger[IO]
  val loggerCIO = docspell.logging.getLogger[ConnectionIO]

  def run(ctx: Context): IO[Unit] = {
    val tx = mkTransactor(ctx)
    migrateAllPreviewsArgs(tx)
  }

  def migrateAllPreviewsArgs(xa: Transactor[IO]) =
    for {
      _ <- logger.info(s"Loading account info mappings")
      idMap <- collectiveIdMapping.transact(xa)
      accMap <- accountInfoMapping.transact(xa)

      _ <- logger.info("Converting job and periodic task arguments")
      _ <- convertJob[ScheduledAddonTaskArgsLegacy, ScheduledAddonTaskArgs](
        ScheduledAddonTaskArgsLegacy.taskName,
        convertScheduledAddonTaskArgs(idMap)
      ).transact(xa)
      _ <- convertPeriodicJob[ScheduledAddonTaskArgsLegacy, ScheduledAddonTaskArgs](
        ScheduledAddonTaskArgsLegacy.taskName,
        convertScheduledAddonTaskArgs(idMap)
      ).transact(xa)

      _ <- convertJob[ReIndexTaskArgsLegacy, ReIndexTaskArgs](
        ReIndexTaskArgsLegacy.taskName,
        convertReIndexTaskArgs(idMap)
      ).transact(xa)

      _ <- convertJob[ProcessItemArgsLegacy, ProcessItemArgs](
        ProcessItemArgsLegacy.taskName,
        convertProcessItemArgs(idMap)
      ).transact(xa)
      _ <- convertJob[ProcessItemArgsLegacy, ProcessItemArgs](
        ProcessItemArgsLegacy.multiUploadTaskName,
        convertProcessItemArgs(idMap)
      ).transact(xa)

      _ <- convertJob[LearnClassifierArgsLegacy, LearnClassifierArgs](
        LearnClassifierArgsLegacy.taskName,
        convertLearnClassifierArgs(idMap)
      ).transact(xa)
      _ <- convertPeriodicJob[LearnClassifierArgsLegacy, LearnClassifierArgs](
        LearnClassifierArgsLegacy.taskName,
        convertLearnClassifierArgs(idMap)
      ).transact(xa)

      _ <- convertJob[ItemAddonTaskArgsLegacy, ItemAddonTaskArgs](
        ItemAddonTaskArgsLegacy.taskName,
        convertItemAddonTaskArgs(idMap)
      ).transact(xa)

      _ <- convertJob[FileIntegrityCheckArgsLegacy, FileIntegrityCheckArgs](
        FileIntegrityCheckArgsLegacy.taskName,
        convertFileIntegrityCheckArgs(idMap)
      ).transact(xa)

      _ <- convertJob[EmptyTrashArgsLegacy, EmptyTrashArgs](
        EmptyTrashArgsLegacy.taskName,
        convertEmptyTrashArgs(idMap)
      ).transact(xa)
      _ <- convertPeriodicJob[EmptyTrashArgsLegacy, EmptyTrashArgs](
        EmptyTrashArgsLegacy.taskName,
        convertEmptyTrashArgs(idMap)
      ).transact(xa)

      _ <- convertJob[AllPreviewArgsLegacy, AllPreviewsArgs](
        AllPreviewArgsLegacy.taskName,
        convertAllPreviewsArgs(idMap)
      ).transact(xa)

      _ <- convertJob[ConvertAllPdfArgsLegacy, ConvertAllPdfArgs](
        ConvertAllPdfArgsLegacy.taskName,
        convertAllPdfArgs(idMap)
      ).transact(xa)

      _ <- convertJob[ScanMailboxArgsLegacy, ScanMailboxArgs](
        ScanMailboxArgsLegacy.taskName,
        convertScanMailboxArgs(accMap)
      ).transact(xa)
      _ <- convertPeriodicJob[ScanMailboxArgsLegacy, ScanMailboxArgs](
        ScanMailboxArgsLegacy.taskName,
        convertScanMailboxArgs(accMap)
      ).transact(xa)

      _ <- convertJob[PeriodicDueItemsArgsLegacy, PeriodicDueItemsArgs](
        PeriodicDueItemsArgsLegacy.taskName,
        convertPeriodicDueItemsArgs(accMap)
      ).transact(xa)
      _ <- convertPeriodicJob[PeriodicDueItemsArgsLegacy, PeriodicDueItemsArgs](
        PeriodicDueItemsArgsLegacy.taskName,
        convertPeriodicDueItemsArgs(accMap)
      ).transact(xa)

      _ <- convertJob[PeriodicQueryArgsLegacy, PeriodicQueryArgs](
        PeriodicQueryArgs.taskName,
        convertPeriodicQueryArgs(accMap)
      ).transact(xa)
      _ <- convertPeriodicJob[PeriodicQueryArgsLegacy, PeriodicQueryArgs](
        PeriodicQueryArgs.taskName,
        convertPeriodicQueryArgs(accMap)
      ).transact(xa)

      // The new DownloadZipArgs are not in scope here. These jobs are deleted, as they are
      // done in 99% probably. If not a user will just click again on the "download all"
      // button
      _ <- RJob.deleteByTask(DownloadZipArgsLegacy.taskName).transact(xa)
      _ <- logger.info("Done converting task arguments.")

      _ <- logger.info("Updating job submitter info")
      _ <- updateJobSubmitter(idMap, accMap).transact(xa)
    } yield ()

  def updateJobSubmitter(
      idMap: Map[Ident, CollectiveId],
      accMap: Map[AccountId, AccountInfo]
  ) = {
    val job = RJob.as("j")
    val pt = RPeriodicTask.as("pt")

    val updateUser =
      accMap.toList.traverse_ { case (accId, accInfo) =>
        val up1 =
          DML.update(
            job,
            job.group === accId.collective && job.submitter === accId.user,
            DML.set(
              job.group.setTo(accInfo.collectiveId.valueAsIdent),
              job.submitter.setTo(accInfo.userId)
            )
          )

        val up2 =
          DML.update(
            pt,
            pt.group === accId.collective && pt.submitter === accId.user,
            DML.set(
              pt.group.setTo(accInfo.collectiveId.valueAsIdent),
              pt.submitter.setTo(accInfo.userId)
            )
          )

        val up3 =
          DML.update(
            job,
            job.group === accId.collective && job.submitter === accId.collective,
            DML.set(
              job.group.setTo(accInfo.collectiveId.valueAsIdent),
              job.submitter.setTo(accInfo.collectiveId.valueAsIdent)
            )
          )

        val up4 =
          DML.update(
            pt,
            pt.group === accId.collective && pt.submitter === accId.collective,
            DML.set(
              pt.group.setTo(accInfo.collectiveId.valueAsIdent),
              pt.submitter.setTo(accInfo.collectiveId.valueAsIdent)
            )
          )

        up1 *> up2 *> up3 *> up4
      }

    val updateJobGroup =
      idMap.toList.traverse_ { case (cname, cid) =>
        val up1 =
          DML.update(job, job.group === cname, DML.set(job.group.setTo(cid.valueAsIdent)))
        val up2 =
          DML.update(pt, pt.group === cname, DML.set(pt.group.setTo(cid.valueAsIdent)))
        up1 *> up2
      }

    updateUser *> updateJobGroup
  }

  def convertJob[S: Decoder, T: Encoder](
      task: Ident,
      conv: S => Option[T]
  ): ConnectionIO[Int] =
    for {
      jobs <- RJob.findByTaskName(task)
      converted =
        jobs.traverse(j =>
          convertJobArgs(j)(conv)
            .map(_.pure[ConnectionIO])
            .recoverWith {
              case ex if JobState.isDone(j.state) =>
                val cause = Option(ex.getCause).getOrElse(ex)
                Either.right(
                  loggerCIO.warn(
                    s"Removing old job '${j.id.id}', because argument parsing failed: ${cause.getMessage}"
                  ) *> RJob.delete(j.id).as(Option.empty[RJob])
                )
            }
        )
      conv <- Sync[ConnectionIO]
        .pure(converted)
        .rethrow
        .flatMap(_.sequence)
        .map(_.flatten)
      _ <- conv.traverse_(j => RJob.setArgs(j.id, j.args))
    } yield conv.size

  def convertPeriodicJob[S: Decoder, T: Encoder](
      task: Ident,
      conv: S => Option[T]
  ): ConnectionIO[Int] =
    for {
      jobs <- RPeriodicTask.findByTask(task)
      converted <- Sync[ConnectionIO]
        .pure(jobs.traverse(j => convertPeriodicJobArgs(j)(conv)))
        .rethrow
        .map(_.flatten)
      _ <- converted.traverse_(j => RPeriodicTask.setArgs(j.id, j.args))
    } yield converted.size

  private def convertPeriodicDueItemsArgs(accMap: Map[AccountId, AccountInfo])(
      oldArgs: PeriodicDueItemsArgsLegacy
  ) =
    accMap
      .get(oldArgs.account)
      .map(acc =>
        PeriodicDueItemsArgs(
          account = acc,
          channels = oldArgs.channels,
          remindDays = oldArgs.remindDays,
          daysBack = oldArgs.daysBack,
          tagsInclude = oldArgs.tagsInclude,
          tagsExclude = oldArgs.tagsExclude,
          baseUrl = oldArgs.baseUrl
        )
      )

  private def convertPeriodicQueryArgs(
      accMap: Map[AccountId, AccountInfo]
  )(oldArgs: PeriodicQueryArgsLegacy) =
    accMap
      .get(oldArgs.account)
      .map(acc =>
        PeriodicQueryArgs(
          account = acc,
          channels = oldArgs.channels,
          query = oldArgs.query,
          bookmark = oldArgs.bookmark,
          baseUrl = oldArgs.baseUrl,
          contentStart = oldArgs.contentStart
        )
      )

  private def convertScanMailboxArgs(
      accMap: Map[AccountId, AccountInfo]
  )(oldArgs: ScanMailboxArgsLegacy) =
    accMap
      .get(oldArgs.account)
      .map(acc =>
        ScanMailboxArgs(
          account = acc,
          imapConnection = oldArgs.imapConnection,
          scanRecursively = oldArgs.scanRecursively,
          folders = oldArgs.folders,
          receivedSince = oldArgs.receivedSince,
          targetFolder = oldArgs.targetFolder,
          deleteMail = oldArgs.deleteMail,
          direction = oldArgs.direction,
          itemFolder = oldArgs.itemFolder,
          fileFilter = oldArgs.fileFilter,
          tags = oldArgs.tags,
          subjectFilter = oldArgs.subjectFilter,
          language = oldArgs.language,
          postHandleAll = oldArgs.postHandleAll,
          attachmentsOnly = oldArgs.attachmentsOnly
        )
      )

  private def convertScheduledAddonTaskArgs(idMap: Map[Ident, CollectiveId])(
      oldArgs: ScheduledAddonTaskArgsLegacy
  ) =
    idMap
      .get(oldArgs.collective)
      .map(cid => ScheduledAddonTaskArgs(cid, oldArgs.addonTaskId))

  private def convertReIndexTaskArgs(
      idMap: Map[Ident, CollectiveId]
  )(oldArgs: ReIndexTaskArgsLegacy) =
    oldArgs.collective.flatMap { cname =>
      idMap
        .get(cname)
        .map(cid => ReIndexTaskArgs(cid.some))
    }

  private def convertProcessItemArgs(idMap: Map[Ident, CollectiveId])(
      oldArgs: ProcessItemArgsLegacy
  ) =
    idMap
      .get(oldArgs.meta.collective)
      .map(cid =>
        ProcessItemArgs(
          ProcessItemArgs.ProcessMeta(
            collective = cid,
            itemId = oldArgs.meta.itemId,
            language = oldArgs.meta.language,
            direction = oldArgs.meta.direction,
            sourceAbbrev = oldArgs.meta.sourceAbbrev,
            folderId = oldArgs.meta.folderId,
            validFileTypes = oldArgs.meta.validFileTypes,
            skipDuplicate = oldArgs.meta.skipDuplicate,
            fileFilter = oldArgs.meta.fileFilter,
            tags = oldArgs.meta.tags,
            reprocess = oldArgs.meta.reprocess,
            attachmentsOnly = oldArgs.meta.attachmentsOnly
          ),
          oldArgs.files.map(f =>
            ProcessItemArgs
              .File(f.name, FileKey(cid, f.fileMetaId.category, f.fileMetaId.id))
          )
        )
      )

  private def convertLearnClassifierArgs(idMap: Map[Ident, CollectiveId])(
      oldArgs: LearnClassifierArgsLegacy
  ) =
    idMap
      .get(oldArgs.collective)
      .map(cid => LearnClassifierArgs(cid))

  private def convertItemAddonTaskArgs(idMap: Map[Ident, CollectiveId])(
      oldArgs: ItemAddonTaskArgsLegacy
  ) =
    idMap
      .get(oldArgs.collective)
      .map(cid => ItemAddonTaskArgs(cid, oldArgs.itemId, oldArgs.addonRunConfigs))

  private def convertFileIntegrityCheckArgs(idMap: Map[Ident, CollectiveId])(
      oldArgs: FileIntegrityCheckArgsLegacy
  ) =
    oldArgs.pattern match {
      case FileIntegrityCheckArgsLegacy.FileKeyPart.Key(key) =>
        idMap
          .get(key.collective)
          .map(cid =>
            FileIntegrityCheckArgs(FileKeyPart.Key(FileKey(cid, key.category, key.id)))
          )

      case FileIntegrityCheckArgsLegacy.FileKeyPart.Collective(cname) =>
        idMap
          .get(cname)
          .map(cid => FileIntegrityCheckArgs(FileKeyPart.Collective(cid)))

      case FileIntegrityCheckArgsLegacy.FileKeyPart.Category(cname, category) =>
        idMap
          .get(cname)
          .map(cid => FileIntegrityCheckArgs(FileKeyPart.Category(cid, category)))

      case FileIntegrityCheckArgsLegacy.FileKeyPart.Empty =>
        None
    }

  private def convertEmptyTrashArgs(idMap: Map[Ident, CollectiveId])(
      oldArgs: EmptyTrashArgsLegacy
  ) =
    idMap.get(oldArgs.collective).map(cid => EmptyTrashArgs(cid, oldArgs.minAge))

  private def convertAllPreviewsArgs(idMap: Map[Ident, CollectiveId])(
      oldArgs: AllPreviewArgsLegacy
  ) =
    oldArgs.collective.flatMap { cname =>
      idMap
        .get(cname)
        .map(cid => AllPreviewsArgs(cid.some, oldArgs.storeMode))
    }

  private def convertAllPdfArgs(idMap: Map[Ident, CollectiveId])(
      oldArgs: ConvertAllPdfArgsLegacy
  ) =
    oldArgs.collective.flatMap(cname =>
      idMap.get(cname).map(cid => ConvertAllPdfArgs(cid.some))
    )

  def convertJobArgs[S: Decoder, T: Encoder](
      job: RJob
  )(update: S => Option[T]): Either[Throwable, Option[RJob]] =
    for {
      oldArgs <- parser
        .decode[S](job.args)
        .leftMap(err =>
          new IllegalStateException(
            s"Error parsing arguments of job: ${job.id.id}",
            err
          )
        )
      upJob = update(oldArgs).map(j => job.withArgs(j))
    } yield upJob

  def convertPeriodicJobArgs[S: Decoder, T: Encoder](
      job: RPeriodicTask
  )(update: S => Option[T]): Either[Throwable, Option[RPeriodicTask]] =
    for {
      oldArgs <- parser
        .decode[S](job.args)
        .leftMap(err =>
          new IllegalStateException(
            s"Error parsing arguments of periodic task: ${job.id.id}",
            err
          )
        )
      upJob = update(oldArgs).map(j => job.withArgs(j))
    } yield upJob

  private def collectiveIdMapping: ConnectionIO[Map[Ident, CollectiveId]] =
    RCollective.findAll(_.id).map(_.map(coll => coll.name -> coll.id).toMap)

  private def accountInfoMapping: ConnectionIO[Map[AccountId, AccountInfo]] = {
    val u = RUser.as("u")
    val c = RCollective.as("c")

    Select(
      select(c.id, c.name, u.uid, u.login),
      from(u).innerJoin(c, c.id === u.cid)
    ).build
      .query[AccountInfo]
      .to[List]
      .map(_.map(a => a.asAccountId -> a).toMap)
  }
}
