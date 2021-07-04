/*
 * Copyright 2020 Docspell Contributors
 *
 * SPDX-License-Identifier: GPL-3.0-or-later
 */

package docspell.analysis

import docspell.analysis.TextAnalysisConfig.NlpConfig
import docspell.analysis.classifier.TextClassifierConfig
import docspell.common._

case class TextAnalysisConfig(
    maxLength: Int,
    nlpConfig: NlpConfig,
    classifier: TextClassifierConfig
)

object TextAnalysisConfig {

  case class NlpConfig(clearInterval: Duration, mode: NlpMode)
}
