/*
 * Copyright 2020 Eike K. & Contributors
 *
 * SPDX-License-Identifier: AGPL-3.0-or-later
 */

package docspell.addons

import docspell.logging.Logger

trait AddonLoggerExtension {

  implicit final class LoggerAddonOps[F[_]](self: Logger[F]) {
    private val addonName = "addon-name"
    private val addonVersion = "addon-version"

    def withAddon(r: AddonArchive): Logger[F] =
      self.capture(addonName, r.name).capture(addonVersion, r.version)

    def withAddon(r: Context): Logger[F] =
      withAddon(r.addon.archive)

    def withAddon(m: AddonMeta): Logger[F] =
      self.capture(addonName, m.meta.name).capture(addonVersion, m.meta.version)
  }
}

object AddonLoggerExtension extends AddonLoggerExtension
