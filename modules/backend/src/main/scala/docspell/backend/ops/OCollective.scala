/*
 * Copyright 2020 Eike K. & Contributors
 *
 * SPDX-License-Identifier: AGPL-3.0-or-later
 */

package docspell.backend.ops

import cats.data.OptionT
import cats.effect.{Async, Resource}
import cats.implicits._
import fs2.Stream

import docspell.backend.JobFactory
import docspell.backend.PasswordCrypt
import docspell.backend.ops.OCollective._
import docspell.common._
import docspell.scheduler.JobStore
import docspell.scheduler.usertask.{UserTask, UserTaskScope, UserTaskStore}
import docspell.store.UpdateResult
import docspell.store.queries.{QCollective, QUser}
import docspell.store.records._
import docspell.store.{AddResult, Store}

import com.github.eikek.calev._

trait OCollective[F[_]] {

  def find(name: Ident): F[Option[RCollective]]

  def updateSettings(
      collective: CollectiveId,
      settings: OCollective.Settings
  ): F[AddResult]

  def findSettings(collective: CollectiveId): F[Option[OCollective.Settings]]

  def listUser(collective: CollectiveId): F[Vector[RUser]]

  def add(s: RUser): F[AddResult]

  def update(s: RUser): F[AddResult]

  /** Deletes the user and all its data. */
  def deleteUser(userId: Ident): F[UpdateResult]

  /** Return an excerpt of what would be deleted, when the user is deleted. */
  def getDeleteUserData(cid: CollectiveId, userId: Ident): F[DeleteUserData]

  def insights(collective: CollectiveId): F[InsightData]

  def tagCloud(collective: CollectiveId): F[List[TagCount]]

  def changePassword(
      collectiveId: CollectiveId,
      userId: Ident,
      current: Password,
      newPass: Password,
      expectedSources: Set[AccountSource]
  ): F[PassChangeResult]

  def resetPassword(
      accountId: AccountId,
      expectedSources: Set[AccountSource]
  ): F[PassResetResult]

  def getContacts(
      collective: CollectiveId,
      query: Option[String],
      kind: Option[ContactKind]
  ): Stream[F, RContact]

  def findEnabledSource(sourceId: Ident): F[Option[RSource]]

  def addPassword(collective: CollectiveId, pw: Password): F[Unit]

  def getPasswords(collective: CollectiveId): F[List[RCollectivePassword]]

  /** Removes a password from the list given the id of `RCollectivePassword` */
  def removePassword(id: Ident): F[Unit]

  def startLearnClassifier(collective: CollectiveId): F[Unit]

  def startEmptyTrash(args: EmptyTrashArgs): F[Unit]

  /** Submits a task that (re)generates the preview images for all attachments of the
    * given collective.
    */
  def generatePreviews(
      storeMode: MakePreviewArgs.StoreMode,
      collectiveId: CollectiveId,
      submitter: UserTaskScope
  ): F[UpdateResult]
}

object OCollective {

  type TagCount = docspell.store.queries.TagCount
  val TagCount = docspell.store.queries.TagCount

  type CategoryCount = docspell.store.queries.CategoryCount
  val CategoryCount = docspell.store.queries.CategoryCount

  type InsightData = QCollective.InsightData
  val insightData = QCollective.InsightData

  type Settings = RCollective.Settings
  val Settings = RCollective.Settings
  type Classifier = RClassifierSetting.Classifier
  val Classifier = RClassifierSetting.Classifier
  type EmptyTrash = REmptyTrashSetting.EmptyTrash
  val EmptyTrash = REmptyTrashSetting.EmptyTrash

  type DeleteUserData = QUser.UserData
  val DeleteUserData = QUser.UserData

  sealed trait PassResetResult
  object PassResetResult {
    case class Success(newPw: Password) extends PassResetResult
    case object NotFound extends PassResetResult
    case class InvalidSource(source: AccountSource) extends PassResetResult

    def success(np: Password): PassResetResult = Success(np)
    def notFound: PassResetResult = NotFound
    def invalidSource(source: AccountSource): PassResetResult = InvalidSource(source)
  }

  sealed trait PassChangeResult
  object PassChangeResult {
    case object UserNotFound extends PassChangeResult
    case object PasswordMismatch extends PassChangeResult
    case object UpdateFailed extends PassChangeResult
    case class InvalidSource(source: AccountSource) extends PassChangeResult
    case object Success extends PassChangeResult

    def userNotFound: PassChangeResult = UserNotFound
    def passwordMismatch: PassChangeResult = PasswordMismatch
    def success: PassChangeResult = Success
    def updateFailed: PassChangeResult = UpdateFailed
    def invalidSource(source: AccountSource): PassChangeResult = InvalidSource(source)
  }

  def apply[F[_]: Async](
      store: Store[F],
      uts: UserTaskStore[F],
      jobStore: JobStore[F],
      joex: OJoex[F]
  ): Resource[F, OCollective[F]] =
    Resource.pure[F, OCollective[F]](new OCollective[F] {
      def find(name: Ident): F[Option[RCollective]] =
        store.transact(RCollective.findByName(name))

      def updateSettings(
          collectiveId: CollectiveId,
          sett: Settings
      ): F[AddResult] =
        store
          .transact(RCollective.updateSettings(collectiveId, sett))
          .attempt
          .map(AddResult.fromUpdate)
          .flatMap(res =>
            updateLearnClassifierTask(collectiveId, sett) *> updateEmptyTrashTask(
              collectiveId,
              sett
            ) *> res.pure[F]
          )

      private def updateLearnClassifierTask(
          cid: CollectiveId,
          sett: Settings
      ): F[Unit] =
        for {
          id <- Ident.randomId[F]
          on = sett.classifier.exists(_.enabled)
          timer = sett.classifier.map(_.schedule).getOrElse(CalEvent.unsafe(""))
          args = LearnClassifierArgs(cid)
          ut = UserTask(
            id,
            LearnClassifierArgs.taskName,
            on,
            timer,
            None,
            args
          )
          _ <- uts.updateOneTask(UserTaskScope.collective(cid), args.makeSubject.some, ut)
          _ <- joex.notifyAllNodes
        } yield ()

      private def updateEmptyTrashTask(
          cid: CollectiveId,
          sett: Settings
      ): F[Unit] =
        for {
          id <- Ident.randomId[F]
          settings = sett.emptyTrash.getOrElse(EmptyTrash.default)
          args = EmptyTrashArgs(cid, settings.minAge)
          ut = UserTask(
            id,
            EmptyTrashArgs.taskName,
            enabled = true,
            settings.schedule,
            None,
            args
          )
          _ <- uts.updateOneTask(UserTaskScope.collective(cid), args.makeSubject.some, ut)
          _ <- joex.notifyAllNodes
        } yield ()

      def addPassword(collective: CollectiveId, pw: Password): F[Unit] =
        for {
          cpass <- RCollectivePassword.createNew[F](collective, pw)
          _ <- store.transact(RCollectivePassword.upsert(cpass))
        } yield ()

      def getPasswords(collective: CollectiveId): F[List[RCollectivePassword]] =
        store.transact(RCollectivePassword.findAll(collective))

      def removePassword(id: Ident): F[Unit] =
        store.transact(RCollectivePassword.deleteById(id)).map(_ => ())

      def startLearnClassifier(
          collectiveId: CollectiveId
      ): F[Unit] =
        for {
          id <- Ident.randomId[F]
          args = LearnClassifierArgs(collectiveId)
          ut = UserTask(
            id,
            LearnClassifierArgs.taskName,
            enabled = true,
            CalEvent(WeekdayComponent.All, DateEvent.All, TimeEvent.All),
            None,
            args
          )
          _ <- uts
            .executeNow(
              UserTaskScope.collective(args.collectiveId),
              args.makeSubject.some,
              ut
            )
        } yield ()

      def startEmptyTrash(args: EmptyTrashArgs): F[Unit] =
        for {
          id <- Ident.randomId[F]
          ut = UserTask(
            id,
            EmptyTrashArgs.taskName,
            enabled = true,
            CalEvent(WeekdayComponent.All, DateEvent.All, TimeEvent.All),
            None,
            args
          )
          _ <- uts
            .executeNow(
              UserTaskScope.collective(args.collective),
              args.makeSubject.some,
              ut
            )
        } yield ()

      def findSettings(collective: CollectiveId): F[Option[OCollective.Settings]] =
        store.transact(RCollective.getSettings(collective))

      def listUser(collective: CollectiveId): F[Vector[RUser]] =
        store.transact(RUser.findAll(collective, _.login))

      def add(s: RUser): F[AddResult] =
        if (s.source != AccountSource.Local)
          AddResult.failure(new Exception("Only local accounts can be created!")).pure[F]
        else
          store.add(
            RUser.insert(s.copy(password = PasswordCrypt.crypt(s.password))),
            RUser.exists(s.login)
          )

      def update(s: RUser): F[AddResult] =
        store.add(RUser.update(s), RUser.exists(s.login))

      def getDeleteUserData(cid: CollectiveId, userId: Ident): F[DeleteUserData] =
        store.transact(QUser.getUserData(cid, userId))

      def deleteUser(userId: Ident): F[UpdateResult] =
        UpdateResult.fromUpdate(
          store.transact(QUser.deleteUserAndData(userId))
        )

      def insights(collective: CollectiveId): F[InsightData] =
        store.transact(QCollective.getInsights(collective))

      def tagCloud(collective: CollectiveId): F[List[TagCount]] =
        store.transact(QCollective.tagCloud(collective))

      def resetPassword(
          accountId: AccountId,
          expectedSources: Set[AccountSource]
      ): F[PassResetResult] =
        (for {
          user <- OptionT(store.transact(RUser.findByAccount(accountId)))
          newPass <- OptionT.liftF(Password.generate[F])

          doUpdate = store.transact(
            RUser.updatePassword(user.cid, user.uid, PasswordCrypt.crypt(newPass))
          )
          res <-
            if (!expectedSources.contains(user.source))
              OptionT.pure[F](PassResetResult.invalidSource(user.source))
            else OptionT.liftF(doUpdate.as(PassResetResult.success(newPass)))
        } yield res).getOrElse(PassResetResult.notFound)

      def changePassword(
          collectiveId: CollectiveId,
          userId: Ident,
          current: Password,
          newPass: Password,
          expectedSources: Set[AccountSource]
      ): F[PassChangeResult] = {
        val q = for {
          user <- OptionT(store.transact(RUser.findById(userId, collectiveId.some)))
          check = user.password.isEmpty || PasswordCrypt.check(current, user.password)
          res <-
            if (check && expectedSources.contains(user.source))
              OptionT.liftF(
                store
                  .transact(
                    RUser
                      .updatePassword(collectiveId, userId, PasswordCrypt.crypt(newPass))
                  )
                  .map {
                    case 0 => PassChangeResult.updateFailed
                    case _ => PassChangeResult.success
                  }
              )
            else if (check && !expectedSources.contains(user.source))
              OptionT.some[F](PassChangeResult.invalidSource(user.source))
            else OptionT.some[F](PassChangeResult.passwordMismatch)
        } yield res

        q.getOrElse(PassChangeResult.userNotFound)
      }

      def getContacts(
          collective: CollectiveId,
          query: Option[String],
          kind: Option[ContactKind]
      ): Stream[F, RContact] =
        store.transact(QCollective.getContacts(collective, query, kind))

      def findEnabledSource(sourceId: Ident): F[Option[RSource]] =
        store.transact(RSource.findEnabled(sourceId))

      def generatePreviews(
          storeMode: MakePreviewArgs.StoreMode,
          collectiveId: CollectiveId,
          submitter: UserTaskScope
      ): F[UpdateResult] =
        for {
          job <- JobFactory.allPreviews[F](
            AllPreviewsArgs(Some(collectiveId), storeMode),
            submitter
          )
          _ <- jobStore.insertIfNew(job.encode)
        } yield UpdateResult.success

    })
}
