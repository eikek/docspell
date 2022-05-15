/*
 * Copyright 2020 Eike K. & Contributors
 *
 * SPDX-License-Identifier: AGPL-3.0-or-later
 */

package docspell.addons

import cats.effect._
import cats.syntax.option._

import docspell.common.UrlReader
import docspell.logging.TestLoggingConfig

import munit._

class AddonArchiveTest extends CatsEffectSuite with TestLoggingConfig with Fixtures {
  val logger = docspell.logging.getLogger[IO]

  tempDir.test("Read archive from directory") { dir =>
    for {
      archive <- IO(AddonArchive(dummyAddonUrl, "", ""))
      path <- archive.extractTo[IO](UrlReader.defaultReader[IO], dir)

      aa <- AddonArchive.read[IO](dummyAddonUrl, UrlReader.defaultReader[IO], path.some)
      _ = {
        assertEquals(aa.name, "dummy-addon")
        assertEquals(aa.version, "2.9")
        assertEquals(aa.url, dummyAddonUrl)
      }
    } yield ()
  }

  test("Read archive from zip file") {
    for {
      archive <- AddonArchive.read[IO](dummyAddonUrl, UrlReader.defaultReader[IO])
      _ = {
        assertEquals(archive.name, "dummy-addon")
        assertEquals(archive.version, "2.9")
        assertEquals(archive.url, dummyAddonUrl)
      }
    } yield ()
  }
}
