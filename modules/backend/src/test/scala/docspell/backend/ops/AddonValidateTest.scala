/*
 * Copyright 2020 Eike K. & Contributors
 *
 * SPDX-License-Identifier: AGPL-3.0-or-later
 */

package docspell.backend.ops

import cats.effect._
import fs2.Stream

import docspell.backend.Config
import docspell.backend.ops.AddonValidationError._
import docspell.common._
import docspell.joexapi.model.AddonSupport
import docspell.store.Store

import munit.CatsEffectSuite

class AddonValidateTest extends CatsEffectSuite {

  test("checkTrusted rejects denied urls without side effects") {
    val url = LenientUri.unsafe("http://127.0.0.1:1/internal/metadata/secret.zip")
    val validate = new AddonValidate[IO](restrictedAddons, unusedStore, unusedJoex)
    validate.checkTrusted(url).map { res =>
      assertEquals(res, Left(UrlUntrusted(url)))
    }
  }

  test("checkTrusted accepts allowed urls") {
    val url = LenientUri.unsafe("https://github.com/eikek/docspell-addons/archive/main.zip")
    val validate = new AddonValidate[IO](restrictedAddons, unusedStore, unusedJoex)
    validate.checkTrusted(url).map { res =>
      assertEquals(res, Right(()))
    }
  }

  test("fromUrl does not read a denied url") {
    val url = LenientUri.unsafe("http://127.0.0.1:1/internal/metadata/secret.zip")
    Ref.of[IO, Int](0).flatMap { reads =>
      val reader = UrlReader.instance[IO] { u =>
        Stream.eval(reads.update(_ + 1)) >>
          Stream.raiseError[IO](new Exception(s"should not read ${u.asString}"))
      }
      val validate = new AddonValidate[IO](restrictedAddons, unusedStore, unusedJoex)
      for {
        res <- validate.fromUrl(CollectiveId(1), url, reader)
        n <- reads.get
      } yield {
        assertEquals(res, Left(UrlUntrusted(url)))
        assertEquals(n, 0)
      }
    }
  }

  test("checkTrusted rejects when addons are disabled") {
    val url = LenientUri.unsafe("https://github.com/eikek/docspell-addons/archive/main.zip")
    val cfg = restrictedAddons.copy(enabled = false)
    val validate = new AddonValidate[IO](cfg, unusedStore, unusedJoex)
    validate.checkTrusted(url).map { res =>
      assertEquals(res, Left(AddonsDisabled))
    }
  }

  private val restrictedAddons: Config.Addons =
    Config.Addons(
      enabled = true,
      allowImpure = false,
      allowedUrls = UrlMatcher.unsafeFromString("https://github.com/*"),
      deniedUrls = UrlMatcher.False
    )

  private val unusedStore: Store[IO] =
    new Store[IO] {
      def transform = fail("store must not be used")
      def transact[A](prg: doobie.ConnectionIO[A]) = fail("store must not be used")
      def transact[A](prg: Stream[doobie.ConnectionIO, A]) = fail("store must not be used")
      def fileRepo = fail("store must not be used")
      def createFileRepository(
          cfg: docspell.store.file.FileRepositoryConfig,
          withAttributeStore: Boolean
      ) = fail("store must not be used")
      def add(insert: doobie.ConnectionIO[Int], exists: doobie.ConnectionIO[Boolean]) =
        fail("store must not be used")
      def transactor = fail("store must not be used")
      def dbms = fail("store must not be used")
    }

  private val unusedJoex: OJoex[IO] =
    new OJoex[IO] {
      def notifyAllNodes = fail("joex must not be used")
      def notifyPeriodicTasks = fail("joex must not be used")
      def cancelJob(job: Ident, worker: Ident) = fail("joex must not be used")
      def getAddonSupport: IO[List[AddonSupport]] = fail("joex must not be used")
    }
}
