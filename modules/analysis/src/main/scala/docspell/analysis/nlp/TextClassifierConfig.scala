package docspell.analysis.nlp

import java.nio.file.Path

import cats.data.NonEmptyList

case class TextClassifierConfig(
    workingDir: Path,
    classifierConfigs: NonEmptyList[Map[String, String]]
)
