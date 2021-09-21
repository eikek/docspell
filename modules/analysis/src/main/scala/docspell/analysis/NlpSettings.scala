/*
 * Copyright 2020 Eike K. & Contributors
 *
 * SPDX-License-Identifier: AGPL-3.0-or-later
 */

package docspell.analysis

import fs2.io.file.Path

import docspell.common._

case class NlpSettings(lang: Language, highRecall: Boolean, regexNer: Option[Path])
