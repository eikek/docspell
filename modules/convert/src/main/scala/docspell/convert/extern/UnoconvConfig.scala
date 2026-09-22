/*
 * Copyright 2020 Eike K. & Contributors
 *
 * SPDX-License-Identifier: AGPL-3.0-or-later
 */

package docspell.convert.extern

import fs2.io.file.Path

import docspell.common.exec.ExternalCommand

/** Config for office→PDF conversion via `unoconvert` (unoserver client).
  *
  * `host` / `port` are optional connection overrides. Leave `host` empty to use
  * unoconvert defaults (`127.0.0.1:2003`, local file paths). Set `host` when talking to a
  * remote or sidecar unoserver (files are transferred over the network). Joex never
  * starts the daemon; run it out of band (systemd, Docker Compose, Helm sidecar, …).
  */
case class UnoconvConfig(
    command: ExternalCommand,
    workingDir: Path,
    host: String,
    port: Int
)
