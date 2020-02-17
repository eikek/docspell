package docspell.convert.extern

import java.nio.file.Path

import docspell.common.SystemCommand

case class WkHtmlPdfConfig (cmd: SystemCommand.Config, workingDir: Path)
