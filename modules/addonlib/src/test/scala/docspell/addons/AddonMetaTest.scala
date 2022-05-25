/*
 * Copyright 2020 Eike K. & Contributors
 *
 * SPDX-License-Identifier: AGPL-3.0-or-later
 */

package docspell.addons

import cats.effect._

import docspell.common.Glob
import docspell.files.Zip
import docspell.logging.TestLoggingConfig

import munit._

class AddonMetaTest extends CatsEffectSuite with TestLoggingConfig with Fixtures {
  val logger = docspell.logging.getLogger[IO]

  test("read meta from zip file") {
    val meta = AddonMeta.findInZip(dummyAddonUrl.readURL[IO](8192))
    assertIO(meta, dummyAddonMeta)
  }

  tempDir.test("read meta from directory") { dir =>
    for {
      _ <- dummyAddonUrl
        .readURL[IO](8192)
        .through(Zip.unzip(8192, Glob.all))
        .through(Zip.saveTo(logger, dir, moveUp = true))
        .compile
        .drain
      meta <- AddonMeta.findInDirectory[IO](dir)
      _ = assertEquals(meta, dummyAddonMeta)
    } yield ()
  }
}
