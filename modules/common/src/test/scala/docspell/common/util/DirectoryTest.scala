/*
 * Copyright 2020 Eike K. & Contributors
 *
 * SPDX-License-Identifier: AGPL-3.0-or-later
 */

package docspell.common.util

import cats.effect._
import cats.syntax.all._
import fs2.io.file.{Files, Path}

import docspell.logging.TestLoggingConfig

import munit.CatsEffectSuite

class DirectoryTest extends CatsEffectSuite with TestLoggingConfig {
  val logger = docspell.logging.getLogger[IO]
  val tempDir = ResourceFunFixture(
    Files[IO].tempDirectory(Path("target").some, "directory-test-", None)
  )

  tempDir.test("unwrap directory when non empty") { dir =>
    for {
      _ <- createDirectoryTree(dir, List("test/file1", "test/file2"))
      r <- Directory.unwrapSingle1(logger, dir)
      files <- Files[IO]
        .list(dir)
        .map(file => dir.relativize(file).toString)
        .compile
        .toVector
      _ = {
        assert(r)
        assertEquals(files.sorted, Vector("file1", "file2"))
      }
    } yield ()
  }

  tempDir.test("unwrap directory when not empty repeat") { dir =>
    for {
      _ <- createDirectoryTree(dir, List("test/file1", "test/file2"))
      r <- Directory.unwrapSingle(logger, dir)
      files <- Files[IO]
        .list(dir)
        .map(file => dir.relativize(file).toString)
        .compile
        .toVector
      _ = {
        assert(r)
        assertEquals(files.sorted, Vector("file1", "file2"))
      }
    } yield ()
  }

  tempDir.test("unwrap nested directory") { dir =>
    for {
      _ <- createDirectoryTree(dir, List("test0/test1/file1", "test0/test1/file2"))
      r <- Directory.unwrapSingle(logger, dir)
      files <- Files[IO]
        .list(dir)
        .map(file => dir.relativize(file).toString)
        .compile
        .toVector
      _ = {
        assert(r)
        assertEquals(files.sorted, Vector("file1", "file2"))
      }
    } yield ()
  }

  tempDir.test("do nothing on empty directory") { dir =>
    for {
      r1 <- Directory.unwrapSingle1[IO](logger, dir)
      r2 <- Directory.unwrapSingle[IO](logger, dir)
      _ = {
        assert(!r1)
        assert(!r2)
      }
    } yield ()
  }

  tempDir.test("do nothing when directory contains more than one entry") { dir =>
    for {
      _ <- createDirectoryTree(dir, List("test1/file1", "file2"))
      r1 <- Directory.unwrapSingle1[IO](logger, dir)
      r2 <- Directory.unwrapSingle[IO](logger, dir)
      _ = {
        assert(!r1)
        assert(!r2)
      }
    } yield ()
  }

  tempDir.test("do nothing when directory contains more than one entry (2)") { dir =>
    for {
      _ <- createDirectoryTree(dir, List("file1", "file2"))
      r1 <- Directory.unwrapSingle1[IO](logger, dir)
      r2 <- Directory.unwrapSingle[IO](logger, dir)
      _ = {
        assert(!r1)
        assert(!r2)
      }
    } yield ()
  }

  def createDirectoryTree(dir: Path, entries: List[String]): IO[Unit] =
    entries.traverse_ { name =>
      val out = dir / name
      out.parent
        .map(p => Files[IO].createDirectories(p))
        .getOrElse(IO.unit) *>
        Files[IO].createFile(out)
    }
}
