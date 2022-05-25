/*
 * Copyright 2020 Eike K. & Contributors
 *
 * SPDX-License-Identifier: AGPL-3.0-or-later
 */

package docspell.backend.joex

import fs2.io.file.Path

import docspell.addons.AddonExecutorConfig

final case class AddonEnvConfig(
    workingDir: Path,
    cacheDir: Path,
    executorConfig: AddonExecutorConfig
)
