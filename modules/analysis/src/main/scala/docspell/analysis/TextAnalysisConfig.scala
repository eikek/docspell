package docspell.analysis

import docspell.analysis.classifier.TextClassifierConfig
import docspell.common._

case class TextAnalysisConfig(
    maxLength: Int,
    clearStanfordPipelineInterval: Duration,
    classifier: TextClassifierConfig
)
