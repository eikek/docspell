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
import docspell.store.records.RJob

object JobFactory extends MailAddressCodec {
  def periodicQuery[F[_]: Sync](args: PeriodicQueryArgs, submitter: AccountId): F[RJob] =
    for {
      id <- Ident.randomId[F]
      now <- Timestamp.current[F]
      job = RJob.newJob(
        id,
        PeriodicQueryArgs.taskName,
        submitter.collective,
        args,
        s"Running periodic query, notify via ${args.channels.map(_.channelType)}",
        now,
        submitter.user,
        Priority.Low,
        None
      )
    } yield job

  def makePageCount[F[_]: Sync](
      args: MakePageCountArgs,
      account: Option[AccountId]
  ): F[RJob] =
    for {
      id <- Ident.randomId[F]
      now <- Timestamp.current[F]
      job = RJob.newJob(
        id,
        MakePageCountArgs.taskName,
        account.map(_.collective).getOrElse(DocspellSystem.taskGroup),
        args,
        s"Find page-count metadata for ${args.attachment.id}",
        now,
        account.map(_.user).getOrElse(DocspellSystem.user),
        Priority.Low,
        Some(MakePageCountArgs.taskName / args.attachment)
      )
    } yield job

  def makePreview[F[_]: Sync](
      args: MakePreviewArgs,
      account: Option[AccountId]
  ): F[RJob] =
    for {
      id <- Ident.randomId[F]
      now <- Timestamp.current[F]
      job = RJob.newJob(
        id,
        MakePreviewArgs.taskName,
        account.map(_.collective).getOrElse(DocspellSystem.taskGroup),
        args,
        s"Generate preview image",
        now,
        account.map(_.user).getOrElse(DocspellSystem.user),
        Priority.Low,
        Some(MakePreviewArgs.taskName / args.attachment)
      )
    } yield job

  def allPreviews[F[_]: Sync](
      args: AllPreviewsArgs,
      submitter: Option[Ident]
  ): F[RJob] =
    for {
      id <- Ident.randomId[F]
      now <- Timestamp.current[F]
    } yield RJob.newJob(
      id,
      AllPreviewsArgs.taskName,
      args.collective.getOrElse(DocspellSystem.taskGroup),
      args,
      "Create preview images",
      now,
      submitter.getOrElse(DocspellSystem.user),
      Priority.Low,
      Some(DocspellSystem.allPreviewTaskTracker)
    )

  def convertAllPdfs[F[_]: Sync](
      collective: Option[Ident],
      submitter: Option[Ident],
      prio: Priority
  ): F[RJob] =
    for {
      id <- Ident.randomId[F]
      now <- Timestamp.current[F]
      job = RJob.newJob(
        id,
        ConvertAllPdfArgs.taskName,
        collective.getOrElse(DocspellSystem.taskGroup),
        ConvertAllPdfArgs(collective),
        s"Convert all pdfs not yet converted",
        now,
        submitter.getOrElse(DocspellSystem.user),
        prio,
        collective
          .map(c => c / ConvertAllPdfArgs.taskName)
          .orElse(ConvertAllPdfArgs.taskName.some)
      )
    } yield job

  def reprocessItem[F[_]: Sync](
      args: ReProcessItemArgs,
      account: AccountId,
      prio: Priority
  ): F[RJob] =
    for {
      id <- Ident.randomId[F]
      now <- Timestamp.current[F]
      job = RJob.newJob(
        id,
        ReProcessItemArgs.taskName,
        account.collective,
        args,
        s"Re-process files of item ${args.itemId.id}",
        now,
        account.user,
        prio,
        Some(ReProcessItemArgs.taskName / args.itemId)
      )
    } yield job

  def processItem[F[_]: Sync](
      args: ProcessItemArgs,
      account: AccountId,
      prio: Priority,
      tracker: Option[Ident]
  ): F[RJob] =
    for {
      id <- Ident.randomId[F]
      now <- Timestamp.current[F]
      job = RJob.newJob(
        id,
        ProcessItemArgs.taskName,
        account.collective,
        args,
        args.makeSubject,
        now,
        account.user,
        prio,
        tracker
      )
    } yield job

  def processItems[F[_]: Sync](
      args: Vector[ProcessItemArgs],
      account: AccountId,
      prio: Priority,
      tracker: Option[Ident]
  ): F[Vector[RJob]] = {
    def create(now: Timestamp, arg: ProcessItemArgs): F[RJob] =
      Ident
        .randomId[F]
        .map(id =>
          RJob.newJob(
            id,
            ProcessItemArgs.taskName,
            account.collective,
            arg,
            arg.makeSubject,
            now,
            account.user,
            prio,
            tracker
          )
        )

    for {
      now <- Timestamp.current[F]
      jobs <- args.traverse(a => create(now, a))
    } yield jobs
  }

  def reIndexAll[F[_]: Sync]: F[RJob] =
    for {
      id <- Ident.randomId[F]
      now <- Timestamp.current[F]
    } yield RJob.newJob(
      id,
      ReIndexTaskArgs.taskName,
      DocspellSystem.taskGroup,
      ReIndexTaskArgs(None),
      s"Recreate full-text index",
      now,
      DocspellSystem.taskGroup,
      Priority.Low,
      Some(DocspellSystem.migrationTaskTracker)
    )

  def reIndex[F[_]: Sync](account: AccountId): F[RJob] =
    for {
      id <- Ident.randomId[F]
      now <- Timestamp.current[F]
      args = ReIndexTaskArgs(Some(account.collective))
    } yield RJob.newJob(
      id,
      ReIndexTaskArgs.taskName,
      account.collective,
      args,
      s"Recreate full-text index",
      now,
      account.user,
      Priority.Low,
      Some(ReIndexTaskArgs.tracker(args))
    )
}
