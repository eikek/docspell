package docspell.convert.extern

import java.nio.file.Path

import docspell.common.SystemCommand

case class TesseractConfig(command: SystemCommand.Config, workingDir: Path)
