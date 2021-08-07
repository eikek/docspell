/*
 * Copyright 2020 Docspell Contributors
 *
 * SPDX-License-Identifier: GPL-3.0-or-later
 */

package docspell.convert.extern

import fs2.io.file.Path

import docspell.common.SystemCommand

case class TesseractConfig(command: SystemCommand.Config, workingDir: Path)
