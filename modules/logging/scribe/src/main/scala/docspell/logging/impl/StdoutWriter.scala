/*
 * Copyright 2020 Eike K. & Contributors
 *
 * SPDX-License-Identifier: AGPL-3.0-or-later
 */

package docspell.logging.impl

import scribe._
import scribe.output.LogOutput
import scribe.output.format.OutputFormat
import scribe.writer.Writer

// From: https://github.com/outr/scribe/blob/8e99521e1ee1f0c421629764dd96e4eb193d84bd/core/shared/src/main/scala/scribe/writer/SystemOutputWriter.scala
// Modified to always log to stdout. The original code was logging to stdout and stderr
// depending on the log level.
// Original code licensed under MIT

private[impl] object StdoutWriter extends Writer {

  /** If true, will always synchronize writing to the console to avoid interleaved text.
    * Most native consoles will handle this automatically, but IntelliJ and Eclipse are
    * notorious about not properly handling this. Defaults to true.
    */
  val synchronizeWriting: Boolean = true

  /** Workaround for some consoles that don't play nicely with asynchronous calls */
  val alwaysFlush: Boolean = false

  private val stringBuilders = new ThreadLocal[StringBuilder] {
    override def initialValue(): StringBuilder = new StringBuilder(512)
  }

  @annotation.nowarn
  override def write[M](
      record: LogRecord[M],
      output: LogOutput,
      outputFormat: OutputFormat
  ): Unit = {
    val stream = Logger.system.out
    val sb = stringBuilders.get()
    outputFormat.begin(sb.append(_))
    outputFormat(output, s => sb.append(s))
    outputFormat.end(sb.append(_))
    if (synchronizeWriting) {
      synchronized {
        stream.println(sb.toString())
        if (alwaysFlush) stream.flush()
      }
    } else {
      stream.println(sb.toString())
      if (alwaysFlush) stream.flush()
    }
    sb.clear()
  }
}
