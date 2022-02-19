/*
 * Copyright 2020 Eike K. & Contributors
 *
 * SPDX-License-Identifier: AGPL-3.0-or-later
 */

package docspell.logging.impl

import io.circe.syntax._
import scribe._
import scribe.output._
import scribe.output.format.OutputFormat
import scribe.writer._

final case class JsonWriter(writer: Writer, compact: Boolean = true) extends Writer {
  override def write[M](
      record: LogRecord[M],
      output: LogOutput,
      outputFormat: OutputFormat
  ): Unit = {
    val r = Record.fromLogRecord(record)
    val json = r.asJson
    val jsonString = if (compact) json.noSpaces else json.spaces2
    writer.write(record, new TextOutput(jsonString), outputFormat)
  }
}
