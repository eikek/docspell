/*
 * Copyright 2020 Eike K. & Contributors
 *
 * SPDX-License-Identifier: AGPL-3.0-or-later
 */

package docspell.backend

import cats.effect._
import cats.implicits._

import docspell.backend.MailAddressCodec
import docspell.backend.task.DownloadZipArgs
import docspell.common._
import docspell.notification.api.PeriodicQueryArgs
import docspell.scheduler.Job
import docspell.scheduler.usertask.UserTaskScope

object JobFactory extends MailAddressCodec {
  def existingItemAddon[F[_]: Sync](
      args: ItemAddonTaskArgs,
      submitter: UserTaskScope
  ): F[Job[ItemAddonTaskArgs]] =
    Job.createNew(
      ItemAddonTaskArgs.taskName,
      submitter,
      args,
      "Run addons on item",
      Priority.High,
      args.addonRunConfigs
        .map(_.take(23))
        .toList
        .sorted
        .foldLeft(args.itemId)(_ / _)
        .take(250)
        .some
    )

  def downloadZip[F[_]: Sync](
      args: DownloadZipArgs,
      summaryId: Ident,
      submitter: UserTaskScope
  ): F[Job[DownloadZipArgs]] =
    Job.createNew(
      DownloadZipArgs.taskName,
      submitter,
      args,
      s"Prepare zip file for query",
      Priority.High,
      Some(summaryId)
    )

  def integrityCheck[F[_]: Sync](
      args: FileIntegrityCheckArgs,
      submitter: UserTaskScope = UserTaskScope.system
  ): F[Job[FileIntegrityCheckArgs]] =
    Job.createNew(
      FileIntegrityCheckArgs.taskName,
      submitter,
      args,
      s"Check integrity of files",
      Priority.Low,
      Some(FileIntegrityCheckArgs.taskName)
    )

  def fileCopy[F[_]: Sync](
      args: FileCopyTaskArgs,
      submitter: UserTaskScope = UserTaskScope.system
  ): F[Job[FileCopyTaskArgs]] =
    Job.createNew(
      FileCopyTaskArgs.taskName,
      submitter,
      args,
      "Copying all files",
      Priority.High,
      Some(FileCopyTaskArgs.taskName)
    )

  def periodicQuery[F[_]: Sync](
      args: PeriodicQueryArgs,
      submitter: UserTaskScope
  ): F[Job[PeriodicQueryArgs]] =
    Job.createNew(
      PeriodicQueryArgs.taskName,
      submitter,
      args,
      s"Running periodic query, notify via ${args.channels.map(_.channelType)}",
      Priority.Low,
      None
    )

  def makePageCount[F[_]: Sync](
      args: MakePageCountArgs,
      submitter: UserTaskScope
  ): F[Job[MakePageCountArgs]] =
    Job.createNew(
      MakePageCountArgs.taskName,
      submitter,
      args,
      s"Find page-count metadata for ${args.attachment.id}",
      Priority.Low,
      Some(MakePageCountArgs.taskName / args.attachment)
    )

  def makePreview[F[_]: Sync](
      args: MakePreviewArgs,
      submitter: UserTaskScope
  ): F[Job[MakePreviewArgs]] =
    Job.createNew(
      MakePreviewArgs.taskName,
      submitter,
      args,
      s"Generate preview image",
      Priority.Low,
      Some(MakePreviewArgs.taskName / args.attachment)
    )

  def allPreviews[F[_]: Sync](
      args: AllPreviewsArgs,
      submitter: UserTaskScope
  ): F[Job[AllPreviewsArgs]] =
    Job.createNew(
      AllPreviewsArgs.taskName,
      submitter,
      args,
      "Create preview images",
      Priority.Low,
      Some(DocspellSystem.allPreviewTaskTracker)
    )

  def convertAllPdfs[F[_]: Sync](
      args: ConvertAllPdfArgs,
      submitter: UserTaskScope,
      prio: Priority
  ): F[Job[ConvertAllPdfArgs]] =
    Job.createNew(
      ConvertAllPdfArgs.taskName,
      submitter,
      args,
      s"Convert all pdfs not yet converted",
      prio,
      args.collective
        .map(c => c.valueAsIdent / ConvertAllPdfArgs.taskName)
        .orElse(ConvertAllPdfArgs.taskName.some)
    )

  def reprocessItem[F[_]: Sync](
      args: ReProcessItemArgs,
      submitter: UserTaskScope,
      prio: Priority
  ): F[Job[ReProcessItemArgs]] =
    Job.createNew(
      ReProcessItemArgs.taskName,
      submitter,
      args,
      s"Re-process files of item ${args.itemId.id}",
      prio,
      Some(ReProcessItemArgs.taskName / args.itemId)
    )

  def multiUpload[F[_]: Sync](
      args: ProcessItemArgs,
      submitter: UserTaskScope,
      prio: Priority,
      tracker: Option[Ident]
  ): F[Job[ProcessItemArgs]] =
    Job.createNew(
      ProcessItemArgs.multiUploadTaskName,
      submitter,
      args,
      args.makeSubject,
      prio,
      tracker
    )

  def processItem[F[_]: Sync](
      args: ProcessItemArgs,
      submitter: UserTaskScope,
      prio: Priority,
      tracker: Option[Ident]
  ): F[Job[ProcessItemArgs]] =
    Job.createNew(
      ProcessItemArgs.taskName,
      submitter,
      args,
      args.makeSubject,
      prio,
      tracker
    )

  def processItems[F[_]: Sync](
      args: List[ProcessItemArgs],
      submitter: UserTaskScope,
      prio: Priority,
      tracker: Option[Ident]
  ): F[List[Job[ProcessItemArgs]]] = {
    def create(arg: ProcessItemArgs): F[Job[ProcessItemArgs]] =
      Job.createNew(
        ProcessItemArgs.taskName,
        submitter,
        arg,
        arg.makeSubject,
        prio,
        tracker
      )

    args.traverse(create)
  }

  def reIndexAll[F[_]: Sync]: F[Job[ReIndexTaskArgs]] =
    Job.createNew(
      ReIndexTaskArgs.taskName,
      UserTaskScope.system,
      ReIndexTaskArgs(None),
      "Recreate full-text index",
      Priority.Low,
      Some(DocspellSystem.migrationTaskTracker)
    )

  def reIndex[F[_]: Sync](
      cid: CollectiveId,
      submitterUserId: Option[Ident]
  ): F[Job[ReIndexTaskArgs]] = {
    val args = ReIndexTaskArgs(Some(cid))
    Job.createNew(
      ReIndexTaskArgs.taskName,
      UserTaskScope(cid, submitterUserId),
      args,
      "Recreate full-text index",
      Priority.Low,
      Some(ReIndexTaskArgs.tracker(args))
    )
  }
}
