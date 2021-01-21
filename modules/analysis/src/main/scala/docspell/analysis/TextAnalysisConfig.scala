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
