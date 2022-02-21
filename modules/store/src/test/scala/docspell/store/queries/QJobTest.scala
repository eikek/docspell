/*
 * Copyright 2020 Eike K. & Contributors
 *
 * SPDX-License-Identifier: AGPL-3.0-or-later
 */

package docspell.store.queries

import java.time.Instant
import java.util.concurrent.atomic.AtomicLong

import cats.implicits._

import docspell.common._
import docspell.logging.TestLoggingConfig
import docspell.store.StoreFixture
import docspell.store.records.RJob
import docspell.store.records.RJobGroupUse

import doobie.implicits._
import munit._

class QJobTest extends CatsEffectSuite with StoreFixture with TestLoggingConfig {
  private[this] val c = new AtomicLong(0)

  private val worker = Ident.unsafe("joex1")
  private val initialPause = Duration.seconds(5)
  private val nowTs = Timestamp(Instant.parse("2021-06-26T14:54:00Z"))
  private val group1 = Ident.unsafe("group1")
  private val group2 = Ident.unsafe("group2")

  def createJob(group: Ident): RJob =
    RJob.newJob[Unit](
      Ident.unsafe(s"job-${c.incrementAndGet()}"),
      Ident.unsafe("task"),
      group,
      (),
      "some subject",
      nowTs - Duration.days(3),
      Ident.unsafe("user1"),
      Priority.Low,
      None
    )

  xa.test("set group must insert or update") { tx =>
    val res =
      for {
        _ <- RJobGroupUse.setGroup(RJobGroupUse(group1, worker)).transact(tx)
        res <- RJobGroupUse.findGroup(worker).transact(tx)
      } yield res

    res.assertEquals(Some(group1))
  }

  xa.test("selectNextGroup should return first group on initial state") { tx =>
    val nextGroup = for {
      _ <- List(group1, group2, group1, group2, group2)
        .map(createJob)
        .map(RJob.insert)
        .traverse(_.transact(tx))
      _ <- RJobGroupUse.deleteAll.transact(tx)
      next <- QJob.selectNextGroup(worker, nowTs, initialPause).transact(tx)
    } yield next

    nextGroup.assertEquals(Some(group1))
  }

  xa.test("selectNextGroup should return second group on subsequent call (1)") { tx =>
    val nextGroup = for {
      _ <- List(group1, group2, group1, group2)
        .map(createJob)
        .map(RJob.insert)
        .traverse(_.transact(tx))
      _ <- RJobGroupUse.deleteAll.transact(tx)
      _ <- RJobGroupUse.setGroup(RJobGroupUse(group1, worker)).transact(tx)
      next <- QJob.selectNextGroup(worker, nowTs, initialPause).transact(tx)
    } yield next

    nextGroup.assertEquals(Some(group2))
  }

  xa.test("selectNextGroup should return second group on subsequent call (2)") { tx =>
    val nextGroup = for {
      _ <- List(group1, group2, group1, group2)
        .map(createJob)
        .map(RJob.insert)
        .traverse(_.transact(tx))
      _ <- RJobGroupUse.deleteAll.transact(tx)
      _ <- RJobGroupUse.setGroup(RJobGroupUse(group2, worker)).transact(tx)
      next <- QJob.selectNextGroup(worker, nowTs, initialPause).transact(tx)
    } yield next

    nextGroup.assertEquals(Some(group1))
  }
}
