/*
 * Copyright 2020 Eike K. & Contributors
 *
 * SPDX-License-Identifier: AGPL-3.0-or-later
 */

package docspell.logging.impl

import io.circe.syntax._
import scribe.LogRecord
import scribe.output.format.OutputFormat
import scribe.output.{LogOutput, TextOutput}
import scribe.writer.Writer

// https://brandur.org/logfmt
final case class LogfmtWriter(writer: Writer) extends Writer {
  override def write[M](
      record: LogRecord[M],
      output: LogOutput,
      outputFormat: OutputFormat
  ): Unit = {
    val r = Record.fromLogRecord(record)
    val data = r.data
      .map { case (k, v) =>
        s"$k=${v.noSpaces}"
      }
      .mkString(" ")
    val logfmtStr =
      s"""level=${r.level.asJson.noSpaces} levelValue=${r.levelValue} message=${r.message.asJson.noSpaces} fileName=${r.fileName.asJson.noSpaces} className=${r.className.asJson.noSpaces} methodName=${r.methodName.asJson.noSpaces} line=${r.line.asJson.noSpaces} column=${r.column.asJson.noSpaces} $data timestamp=${r.timeStamp} date=${r.date} time=${r.time}"""
    writer.write(record, new TextOutput(logfmtStr), outputFormat)
  }
}
