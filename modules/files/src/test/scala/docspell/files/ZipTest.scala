/*
 * Copyright 2020 Eike K. & Contributors
 *
 * SPDX-License-Identifier: AGPL-3.0-or-later
 */

package docspell.files

import cats.effect._
import cats.syntax.option._
import fs2.Stream
import fs2.io.file.{Files, Path}

import docspell.common.syntax.file._
import docspell.common.util.Zip
import docspell.logging.TestLoggingConfig

import munit._

class ZipTest extends CatsEffectSuite with TestLoggingConfig {
  val logger = docspell.logging.getLogger[IO]
  val tempDir = ResourceFunFixture(
    Files[IO].tempDirectory(Path("target").some, "zip-test-", None)
  )

  tempDir.test("unzip") { dir =>
    val zipFile = ExampleFiles.letters_zip.readURL[IO](8192)
    val unzip: Stream[IO, Path] = zipFile
      .through(Zip[IO](logger.some, dir.some).unzip(8192))

    (for {
      file <- unzip
      length <- Stream.eval(Files[IO].size(file))
      sha <- Stream.eval(file.sha256Hex[IO])
      _ = {
        if (file.name == "letter-de.pdf") {
          assertEquals(length, 34815L)
          assertEquals(
            sha,
            "299c15429ce327099c322b36caaec56e7a6034106531c5d1b3fd085467a8d495"
          )
        } else {
          assertEquals(file.name, "letter-en.txt")
          assertEquals(length, 1131L)
          assertEquals(
            sha,
            "55eca47c65084126d7c3bbce941cadff0f642a7287ff8e0f3fc9c2c33a4bb7f0"
          )
        }
      }
    } yield ()).compile.drain
  }

  tempDir.test("unzip directories and files") { dir =>
    val zipFile = ExampleFiles.zip_dirs_zip.readURL[IO](8192)
    val unzip: Stream[IO, Path] = zipFile
      .through(Zip[IO](logger.some, dir.some).unzip(8192))

    val entries =
      for {
        file <- unzip
        sha <- Stream.eval(file.sha256Hex[IO])
      } yield (file.name, file, sha)

    val expectedSha =
      "5891b5b522d5df086d0ff0b110fbd9d21bb4fc7163af34d08286a2e846f6be03"

    entries
      .map {
        case ("file1.txt", file, realSha) =>
          assertEquals(realSha, expectedSha)
          val relFile = dir.relativize(file).dropLeft(1)
          assertEquals(relFile.toString, "file1.txt")

        case ("file2.txt", file, realSha) =>
          assertEquals(realSha, expectedSha)
          val relFile = dir.relativize(file).dropLeft(1)
          assertEquals(relFile.toString, "dir1/file2.txt")

        case ("file3.txt", file, realSha) =>
          assertEquals(realSha, expectedSha)
          val relFile = dir.relativize(file).dropLeft(1)
          assertEquals(relFile.toString, "dir1/dir11/file3.txt")

        case ("file4.txt", file, realSha) =>
          assertEquals(realSha, expectedSha)
          val relFile = dir.relativize(file).dropLeft(1)
          assertEquals(relFile.toString, "dir2/file4.txt")

        case (name, _, _) =>
          fail(s"Unexpected file: $name")
      }
      .compile
      .drain
  }

//  tempDir.test("test runtime") { _ =>
//    val archive = Path("./local/large-archive.zip")
//
//    for {
//
//      timer1 <- Duration.stopTime[IO]
//      es1 <- Files[IO]
//        .readAll(archive)
//        .through(Zip[IO]().unzip(64 * 1024))
//        .compile
//        .toVector
//      duration1 <- timer1
//
//      timer2 <- Duration.stopTime[IO]
//      es2 <- fs2.Stream
//        .emit(archive)
//        .covary[IO]
//        .through(Zip[IO]().unzipFiles(64 * 1024))
//        .compile
//        .toVector
//      duration2 <- timer2
//
//      _ <- IO.println(s">>>>1. ${duration1.formatExact}, entries: $es1")
//      _ <- IO.println(s">>>>2. ${duration2.formatExact}, entries: $es2")
//    } yield ()
//  }
}
