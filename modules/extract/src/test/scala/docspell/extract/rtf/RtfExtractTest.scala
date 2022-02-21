/*
 * Copyright 2020 Eike K. & Contributors
 *
 * SPDX-License-Identifier: AGPL-3.0-or-later
 */

package docspell.extract.rtf

import docspell.files.ExampleFiles
import docspell.logging.TestLoggingConfig

import munit._

class RtfExtractTest extends FunSuite with TestLoggingConfig {

  test("extract text from rtf using java input-stream") {
    val file = ExampleFiles.examples_sample_rtf
    val is = file.toJavaUrl.map(_.openStream()).fold(sys.error, identity)
    val str = RtfExtract.get(is).fold(throw _, identity)
    assertEquals(str.length, 7342)
  }
}
