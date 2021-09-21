/*
 * Copyright 2020 Eike K. & Contributors
 *
 * SPDX-License-Identifier: AGPL-3.0-or-later
 */

package docspell.analysis.split

import fs2.Stream

/** Splits text into words.
  */
object TextSplitter {
  private[this] val trimChars =
    ".,…_[]^!<>=&ſ/{}*?()-:#$|~`+%\\\"'; \t\r\n".toSet

  def split[F[_]](str: String, sep: Set[Char], start: Int = 0): Stream[F, Word] = {
    val indexes = sep.map(c => str.indexOf(c.toInt)).filter(_ >= 0)
    val index   = if (indexes.isEmpty) -1 else indexes.min

    if (index < 0) Stream.emit(Word(str, start, start + str.length))
    else if (index == 0) split(str.substring(1), sep, start + 1)
    else
      Stream.emit(Word(str.substring(0, index), start, start + index)) ++
        Stream.suspend(split(str.substring(index + 1), sep, start + index + 1))
  }

  def splitToken[F[_]](str: String, sep: Set[Char], start: Int = 0): Stream[F, Word] =
    split(str, sep, start).map(w => w.trim(trimChars)).filter(_.nonEmpty).map(_.toLower)

}
