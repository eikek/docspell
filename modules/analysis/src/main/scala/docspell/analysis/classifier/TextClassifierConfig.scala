/*
 * Copyright 2020 Eike K. & Contributors
 *
 * SPDX-License-Identifier: AGPL-3.0-or-later
 */

package docspell.analysis.classifier

import cats.data.NonEmptyList
import fs2.io.file.Path

case class TextClassifierConfig(
    workingDir: Path,
    classifierConfigs: NonEmptyList[Map[String, String]]
)
