/*
 * Copyright 2020 Eike K. & Contributors
 *
 * SPDX-License-Identifier: AGPL-3.0-or-later
 */

package docspell.addons

import cats.effect._
import cats.syntax.option._

import docspell.common._
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

  test("Read archive from zip") {
    for {
      aa <- AddonArchive.read[IO](dummyAddonUrl, UrlReader.defaultReader[IO], None)
      _ = {
        assertEquals(aa.name, "dummy-addon")
        assertEquals(aa.version, "2.9")
        assertEquals(aa.url, dummyAddonUrl)
      }
    } yield ()
  }

  tempDir.test("read archive from zip with yaml only") { dir =>
    for {
      aa <- AddonArchive.read[IO](singleFileAddonUrl, UrlReader.defaultReader[IO], None)
      _ = assertEquals(aa.version, "0.7.0")
      path <- aa.extractTo(UrlReader.defaultReader[IO], dir)
      read <- AddonArchive.read[IO](aa.url, UrlReader.defaultReader[IO], path.some)
      _ = assertEquals(aa, read)
    } yield ()
  }

  tempDir.test("Read generated addon from path") { dir =>
    AddonGenerator.successAddon("mini-addon").use { addon =>
      for {
        archive <- IO(AddonArchive(addon.url, "test-addon", "0.1.0"))
        path <- archive.extractTo[IO](UrlReader.defaultReader[IO], dir)

        read <- AddonArchive.read[IO](addon.url, UrlReader.defaultReader[IO], path.some)
        _ = assertEquals(addon, read)
      } yield ()
    }
  }

  test("Read generated addon from zip") {
    AddonGenerator.successAddon("mini-addon").use { addon =>
      for {
        read <- AddonArchive.read[IO](addon.url, UrlReader.defaultReader[IO], None)
        _ = assertEquals(addon, read)
      } yield ()
    }
  }

  tempDir.test("Read minimal addon from path") { dir =>
    for {
      archive <- IO(AddonArchive(miniAddonUrl, "", ""))
      path <- archive.extractTo(UrlReader.defaultReader[IO], dir)
      aa <- AddonArchive.read(miniAddonUrl, UrlReader.defaultReader[IO], path.some)
      _ = assertEquals(aa, AddonArchive(miniAddonUrl, "minimal-addon", "0.1.0"))
    } yield ()
  }

  test("Read minimal addon from zip") {
    for {
      aa <- AddonArchive.read(miniAddonUrl, UrlReader.defaultReader[IO], None)
      _ = assertEquals(aa, AddonArchive(miniAddonUrl, "minimal-addon", "0.1.0"))
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
