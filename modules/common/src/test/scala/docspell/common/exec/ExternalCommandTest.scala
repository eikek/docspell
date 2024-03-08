/*
 * Copyright 2020 Eike K. & Contributors
 *
 * SPDX-License-Identifier: AGPL-3.0-or-later
 */

package docspell.common.exec

import docspell.common.Duration
import docspell.common.Ident
import docspell.common.exec.Args
import docspell.common.exec.Env
import docspell.common.exec.ExternalCommand._
import docspell.common.exec.SysCmd

import munit.FunSuite

class ExternalCommandTest extends FunSuite {

  test("resolve") {
    val cmd = ExternalCommand(
      program = "tesseract",
      args = "{{infile}}" :: "{{lang-spec}}" :: "out" :: "pdf" :: "txt" :: Nil,
      timeout = Duration.minutes(5),
      env = Map.empty,
      argMappings = Map(
        Ident.unsafe("lang-spec") -> ArgMapping(
          value = "{{lang}}",
          mappings = List(
            ArgMatch(
              matches = "jpn_vert",
              args = List("-l", "jpn_vert", "-c", "preserve_interword_spaces=1")
            ),
            ArgMatch(
              matches = ".*",
              args = List("-l", "{{lang}}")
            )
          )
        )
      )
    )

    val varsDe = Map("lang" -> "de", "encoding" -> "UTF_8", "infile" -> "text.jpg")
    assertEquals(
      cmd.resolve(varsDe),
      SysCmd(
        "tesseract",
        Args.of("text.jpg", "-l", "de", "out", "pdf", "txt"),
        Env.empty,
        Duration.minutes(5)
      )
    )

    val varsJpnVert = varsDe.updated("lang", "jpn_vert")
    assertEquals(
      cmd.resolve(varsJpnVert),
      SysCmd(
        "tesseract",
        Args.of(
          "text.jpg",
          "-l",
          "jpn_vert",
          "-c",
          "preserve_interword_spaces=1",
          "out",
          "pdf",
          "txt"
        ),
        Env.empty,
        Duration.minutes(5)
      )
    )
  }
}
