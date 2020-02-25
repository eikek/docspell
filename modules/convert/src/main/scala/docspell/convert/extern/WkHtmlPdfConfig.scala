package docspell.convert.extern

import java.nio.file.Path

import docspell.common.SystemCommand

case class WkHtmlPdfConfig(command: SystemCommand.Config, workingDir: Path)
