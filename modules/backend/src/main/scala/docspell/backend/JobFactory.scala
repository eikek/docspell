/*
 * Copyright 2020 Eike K. & Contributors
 *
 * SPDX-License-Identifier: AGPL-3.0-or-later
 */

package docspell.backend

import cats.effect._
import cats.implicits._

import docspell.backend.MailAddressCodec
import docspell.common._
import docspell.notification.api.PeriodicQueryArgs
import docspell.scheduler.Job

object JobFactory extends MailAddressCodec {
  def integrityCheck[F[_]: Sync](
      args: FileIntegrityCheckArgs,
      submitter: AccountId = DocspellSystem.account
  ): F[Job[FileIntegrityCheckArgs]] =
    Job.createNew(
      FileIntegrityCheckArgs.taskName,
      submitter.collective,
      args,
      s"Check integrity of files",
      submitter.user,
      Priority.High,
      Some(FileIntegrityCheckArgs.taskName)
    )

  def fileCopy[F[_]: Sync](
      args: FileCopyTaskArgs,
      submitter: AccountId = DocspellSystem.account
  ): F[Job[FileCopyTaskArgs]] =
    Job.createNew(
      FileCopyTaskArgs.taskName,
      submitter.collective,
      args,
      "Copying all files",
      submitter.user,
      Priority.High,
      Some(FileCopyTaskArgs.taskName)
    )

  def periodicQuery[F[_]: Sync](
      args: PeriodicQueryArgs,
      submitter: AccountId
  ): F[Job[PeriodicQueryArgs]] =
    Job.createNew(
      PeriodicQueryArgs.taskName,
      submitter.collective,
      args,
      s"Running periodic query, notify via ${args.channels.map(_.channelType)}",
      submitter.user,
      Priority.Low,
      None
    )

  def makePageCount[F[_]: Sync](
      args: MakePageCountArgs,
      account: Option[AccountId]
  ): F[Job[MakePageCountArgs]] =
    Job.createNew(
      MakePageCountArgs.taskName,
      account.map(_.collective).getOrElse(DocspellSystem.taskGroup),
      args,
      s"Find page-count metadata for ${args.attachment.id}",
      account.map(_.user).getOrElse(DocspellSystem.user),
      Priority.Low,
      Some(MakePageCountArgs.taskName / args.attachment)
    )

  def makePreview[F[_]: Sync](
      args: MakePreviewArgs,
      account: Option[AccountId]
  ): F[Job[MakePreviewArgs]] =
    Job.createNew(
      MakePreviewArgs.taskName,
      account.map(_.collective).getOrElse(DocspellSystem.taskGroup),
      args,
      s"Generate preview image",
      account.map(_.user).getOrElse(DocspellSystem.user),
      Priority.Low,
      Some(MakePreviewArgs.taskName / args.attachment)
    )

  def allPreviews[F[_]: Sync](
      args: AllPreviewsArgs,
      submitter: Option[Ident]
  ): F[Job[AllPreviewsArgs]] =
    Job.createNew(
      AllPreviewsArgs.taskName,
      args.collective.getOrElse(DocspellSystem.taskGroup),
      args,
      "Create preview images",
      submitter.getOrElse(DocspellSystem.user),
      Priority.Low,
      Some(DocspellSystem.allPreviewTaskTracker)
    )

  def convertAllPdfs[F[_]: Sync](
      collective: Option[Ident],
      submitter: Option[Ident],
      prio: Priority
  ): F[Job[ConvertAllPdfArgs]] =
    Job.createNew(
      ConvertAllPdfArgs.taskName,
      collective.getOrElse(DocspellSystem.taskGroup),
      ConvertAllPdfArgs(collective),
      s"Convert all pdfs not yet converted",
      submitter.getOrElse(DocspellSystem.user),
      prio,
      collective
        .map(c => c / ConvertAllPdfArgs.taskName)
        .orElse(ConvertAllPdfArgs.taskName.some)
    )

  def reprocessItem[F[_]: Sync](
      args: ReProcessItemArgs,
      account: AccountId,
      prio: Priority
  ): F[Job[ReProcessItemArgs]] =
    Job.createNew(
      ReProcessItemArgs.taskName,
      account.collective,
      args,
      s"Re-process files of item ${args.itemId.id}",
      account.user,
      prio,
      Some(ReProcessItemArgs.taskName / args.itemId)
    )

  def processItem[F[_]: Sync](
      args: ProcessItemArgs,
      account: AccountId,
      prio: Priority,
      tracker: Option[Ident]
  ): F[Job[ProcessItemArgs]] =
    Job.createNew(
      ProcessItemArgs.taskName,
      account.collective,
      args,
      args.makeSubject,
      account.user,
      prio,
      tracker
    )

  def processItems[F[_]: Sync](
      args: Vector[ProcessItemArgs],
      account: AccountId,
      prio: Priority,
      tracker: Option[Ident]
  ): F[Vector[Job[ProcessItemArgs]]] = {
    def create(arg: ProcessItemArgs): F[Job[ProcessItemArgs]] =
      Job.createNew(
        ProcessItemArgs.taskName,
        account.collective,
        arg,
        arg.makeSubject,
        account.user,
        prio,
        tracker
      )

    args.traverse(create)
  }

  def reIndexAll[F[_]: Sync]: F[Job[ReIndexTaskArgs]] =
    Job.createNew(
      ReIndexTaskArgs.taskName,
      DocspellSystem.taskGroup,
      ReIndexTaskArgs(None),
      "Recreate full-text index",
      DocspellSystem.taskGroup,
      Priority.Low,
      Some(DocspellSystem.migrationTaskTracker)
    )

  def reIndex[F[_]: Sync](account: AccountId): F[Job[ReIndexTaskArgs]] = {
    val args = ReIndexTaskArgs(Some(account.collective))
    Job.createNew(
      ReIndexTaskArgs.taskName,
      account.collective,
      args,
      "Recreate full-text index",
      account.user,
      Priority.Low,
      Some(ReIndexTaskArgs.tracker(args))
    )
  }
}
