/*
 * Copyright 2020 Docspell Contributors
 *
 * SPDX-License-Identifier: GPL-3.0-or-later
 */

package docspell.analysis.classifier

import cats.data.NonEmptyList
import fs2.io.file.Path

case class TextClassifierConfig(
    workingDir: Path,
    classifierConfigs: NonEmptyList[Map[String, String]]
)
