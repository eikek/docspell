/*
 * Copyright 2020 Docspell Contributors
 *
 * SPDX-License-Identifier: GPL-3.0-or-later
 */

package docspell.convert.extern

import java.nio.file.Path

import docspell.common.SystemCommand

case class OcrMyPdfConfig(
    enabled: Boolean,
    command: SystemCommand.Config,
    workingDir: Path
)
