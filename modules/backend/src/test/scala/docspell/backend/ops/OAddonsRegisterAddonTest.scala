/*
 * Copyright 2020 Eike K. & Contributors
 *
 * SPDX-License-Identifier: AGPL-3.0-or-later
 */

package docspell.backend.ops

import cats.data.OptionT
import cats.effect._
import fs2.Stream

import docspell.backend.Config
import docspell.backend.ops.AddonValidationError.UrlUntrusted
import docspell.common._
import docspell.joexapi.model.AddonSupport
import docspell.scheduler.JobStore
import docspell.scheduler.usertask.{UserTask, UserTaskScope, UserTaskStore}
import docspell.store.records.RCollective
import docspell.store.{DatabaseTest, Store}

import io.circe.{Decoder, Encoder}

class OAddonsRegisterAddonTest extends DatabaseTest {

  override def munitFixtures = h2Memory

  test("registerAddon rejects untrusted url before downloading") {
    val store = h2Store()
    // Closed port: a download-first bug would surface as DownloadFailed, not UrlUntrusted.
    val url = LenientUri.unsafe("http://127.0.0.1:1/internal/metadata/secret.zip")
    val addons =
      OAddons[IO](restrictedAddons, store, unusedUserTasks, unusedJobStore, unusedJoex)

    for {
      cid <- prepareCollective(store)
      res <- addons.registerAddon(cid, url, None)
    } yield assertEquals(res, Left(UrlUntrusted(url)))
  }

  private val restrictedAddons: Config.Addons =
    Config.Addons(
      enabled = true,
      allowImpure = false,
      allowedUrls = UrlMatcher.unsafeFromString("https://github.com/*"),
      deniedUrls = UrlMatcher.False
    )

  private val unusedJoex: OJoex[IO] =
    new OJoex[IO] {
      def notifyAllNodes = IO.unit
      def notifyPeriodicTasks = IO.unit
      def cancelJob(job: Ident, worker: Ident) = IO.unit
      def getAddonSupport: IO[List[AddonSupport]] = IO.pure(Nil)
    }

  private val unusedJobStore: JobStore[IO] =
    new JobStore[IO] {
      def insert(job: docspell.scheduler.Job[String]) =
        IO.raiseError(new Exception("job store must not be used"))
      def insertIfNew(job: docspell.scheduler.Job[String]) =
        IO.raiseError(new Exception("job store must not be used"))
      def insertAll(jobs: Seq[docspell.scheduler.Job[String]]) =
        IO.raiseError(new Exception("job store must not be used"))
      def insertAllIfNew(jobs: Seq[docspell.scheduler.Job[String]]) =
        IO.raiseError(new Exception("job store must not be used"))
      def findById(jobId: Ident) =
        IO.raiseError(new Exception("job store must not be used"))
    }

  private val unusedUserTasks: UserTaskStore[IO] =
    new UserTaskStore[IO] {
      def getAll(scope: UserTaskScope) =
        Stream.raiseError[IO](new Exception("user tasks must not be used"))
      def getByNameRaw(scope: UserTaskScope, name: Ident) =
        Stream.raiseError[IO](new Exception("user tasks must not be used"))
      def getByName[A](scope: UserTaskScope, name: Ident)(implicit D: Decoder[A]) =
        Stream.raiseError[IO](new Exception("user tasks must not be used"))
      def getByIdRaw(scope: UserTaskScope, id: Ident) =
        OptionT.liftF(IO.raiseError(new Exception("user tasks must not be used")))
      def updateTask[A](scope: UserTaskScope, subject: Option[String], ut: UserTask[A])(
          implicit E: Encoder[A]
      ) = IO.raiseError(new Exception("user tasks must not be used"))
      def deleteTask(scope: UserTaskScope, id: Ident) =
        IO.raiseError(new Exception("user tasks must not be used"))
      def getOneByNameRaw(scope: UserTaskScope, name: Ident) =
        OptionT.liftF(IO.raiseError(new Exception("user tasks must not be used")))
      def getOneByName[A](scope: UserTaskScope, name: Ident)(implicit D: Decoder[A]) =
        OptionT.liftF(IO.raiseError(new Exception("user tasks must not be used")))
      def updateOneTask[A](
          scope: UserTaskScope,
          subject: Option[String],
          ut: UserTask[A]
      )(implicit
          E: Encoder[A]
      ) = IO.raiseError(new Exception("user tasks must not be used"))
      def deleteAll(scope: UserTaskScope, name: Ident) =
        IO.raiseError(new Exception("user tasks must not be used"))
      def executeNow[A](scope: UserTaskScope, subject: Option[String], task: UserTask[A])(
          implicit E: Encoder[A]
      ) = IO.raiseError(new Exception("user tasks must not be used"))
    }

  private def prepareCollective(store: Store[IO]): IO[CollectiveId] =
    Ident
      .randomId[IO]
      .flatMap { name =>
        store.transact(
          RCollective.insert(
            RCollective(
              CollectiveId.unknown,
              name,
              CollectiveState.Active,
              Language.English,
              integrationEnabled = true,
              Timestamp.Epoch
            )
          )
        )
      }
}
