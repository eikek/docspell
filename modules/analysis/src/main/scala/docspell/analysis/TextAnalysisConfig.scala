package docspell.analysis

import docspell.analysis.nlp.TextClassifierConfig

case class TextAnalysisConfig(
    maxLength: Int,
    classifier: TextClassifierConfig
)
