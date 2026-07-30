/*
 * Copyright 2020 Eike K. & Contributors
 *
 * SPDX-License-Identifier: AGPL-3.0-or-later
 */

package docspell.backend.ops

import cats.effect._
import fs2.Stream

import docspell.common._
import docspell.store.{DatabaseTest, Store}

class OItemSearchFileTest extends DatabaseTest {

  override def munitFixtures = h2Memory

  test("findFile returns bytes for matching collective") {
    val store = h2Store()
    val content = "original-bytes".getBytes("UTF-8")

    OItemSearch[IO](store).use { search =>
      for {
        cid <- IO.pure(CollectiveId(42))
        key <- saveFile(store, cid, content)
        found <- search.findFile(key, cid)
        bytes <- found match {
          case Some(bin) => bin.data.compile.to(Array)
          case None      => IO.raiseError(new Exception("expected Some"))
        }
      } yield {
        assertEquals(bytes.toSeq, content.toSeq)
        assertEquals(found.get.fileId, key)
      }
    }
  }

  test("findFile returns None when collective does not match") {
    val store = h2Store()
    val content = "secret".getBytes("UTF-8")

    OItemSearch[IO](store).use { search =>
      for {
        cid <- IO.pure(CollectiveId(7))
        other = CollectiveId(8)
        key <- saveFile(store, cid, content)
        found <- search.findFile(key, other)
      } yield assertEquals(found, None)
    }
  }

  private def saveFile(
      store: Store[IO],
      cid: CollectiveId,
      content: Array[Byte]
  ): IO[FileKey] =
    Stream
      .emits(content)
      .covary[IO]
      .through(
        store.fileRepo.save(
          cid,
          FileCategory.AttachmentSource,
          MimeTypeHint.filename("a.txt")
        )
      )
      .compile
      .lastOrError
}
