/*
 * Copyright 2020 Docspell Contributors
 *
 * SPDX-License-Identifier: GPL-3.0-or-later
 */

package docspell.analysis

import java.nio.file.Path

import docspell.common._

case class NlpSettings(lang: Language, highRecall: Boolean, regexNer: Option[Path])
