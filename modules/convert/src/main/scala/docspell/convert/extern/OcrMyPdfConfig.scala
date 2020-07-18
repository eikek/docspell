package docspell.convert.extern

import java.nio.file.Path

import docspell.common.SystemCommand

case class OcrMyPdfConfig(
    enabled: Boolean,
    command: SystemCommand.Config,
    workingDir: Path
)
