package docspell.analysis

import java.nio.file.Path

import docspell.common._

case class NlpSettings(lang: Language, highRecall: Boolean, regexNer: Option[Path])
