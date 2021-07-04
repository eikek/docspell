/*
 * Copyright 2020 Docspell Contributors
 *
 * SPDX-License-Identifier: GPL-3.0-or-later
 */

package docspell.analysis.classifier

import java.nio.file.Path

import cats.data.NonEmptyList

case class TextClassifierConfig(
    workingDir: Path,
    classifierConfigs: NonEmptyList[Map[String, String]]
)
