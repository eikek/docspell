/*
 * Copyright 2020 Eike K. & Contributors
 *
 * SPDX-License-Identifier: AGPL-3.0-or-later
 */

package docspell.addons

import cats.effect._
import cats.syntax.all._

import docspell.common.Glob
import docspell.common.util.{Directory, Zip}
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
        .through(Zip[IO]().unzip(8192, Glob.all, dir.some))
        .evalTap(_ => Directory.unwrapSingle(logger, dir))
        .compile
        .drain
      meta <- AddonMeta.findInDirectory[IO](dir)
      _ = assertEquals(meta, dummyAddonMeta)
    } yield ()
  }

  test("parse yaml with defaults") {
    val yamlStr = """meta:
                    |  name: "test"
                    |  version: "0.1.0"
                    |""".stripMargin
    val meta = AddonMeta.fromYamlString(yamlStr).fold(throw _, identity)
    assert(meta.parseResult)
  }
}
