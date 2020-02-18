package docspell.convert.extern

import java.nio.file.Path

import docspell.common.SystemCommand

case class UnoconvConfig (cmd: SystemCommand.Config, workingDir: Path)
