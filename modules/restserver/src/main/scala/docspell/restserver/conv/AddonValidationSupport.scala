/*
 * Copyright 2020 Eike K. & Contributors
 *
 * SPDX-License-Identifier: AGPL-3.0-or-later
 */

package docspell.restserver.conv

import cats.syntax.all._

import docspell.addons.AddonMeta
import docspell.backend.ops.AddonValidationError
import docspell.backend.ops.OAddons.AddonValidationResult
import docspell.common.CollectiveId
import docspell.restserver.ws.{OutputEvent, OutputEventEncoder}
import docspell.store.records.RAddonArchive

trait AddonValidationSupport {

  def validationErrorToMessage(e: AddonValidationError): String =
    e match {
      case AddonValidationError.AddonNotFound =>
        "Addon not found."

      case AddonValidationError.AddonExists(msg, _) =>
        msg

      case AddonValidationError.NotAnAddon(ex) =>
        s"The url doesn't seem to be an addon: ${ex.getMessage}"

      case AddonValidationError.InvalidAddon(msg) =>
        s"The addon is not valid: $msg"

      case AddonValidationError.AddonUnsupported(msg, _) =>
        msg

      case AddonValidationError.AddonsDisabled =>
        "Addons are disabled in the config file."

      case AddonValidationError.UrlUntrusted(_) =>
        "This url doesn't belong to te set of trusted urls defined in the config file"

      case AddonValidationError.DownloadFailed(ex) =>
        s"Downloading the addon failed: ${ex.getMessage}"

      case AddonValidationError.ImpureAddonsDisabled =>
        s"Installing impure addons is disabled."

      case AddonValidationError.RefreshLocalAddon =>
        "Refreshing a local addon doesn't work."
    }

  def addonResultOutputEventEncoder(
      collective: CollectiveId
  ): OutputEventEncoder[AddonValidationResult[(RAddonArchive, AddonMeta)]] =
    OutputEventEncoder.instance {
      case Right((archive, _)) =>
        OutputEvent.AddonInstalled(
          collective,
          "Addon installed",
          None,
          archive.id.some,
          archive.originalUrl
        )

      case Left(error) =>
        val msg = validationErrorToMessage(error)
        OutputEvent.AddonInstalled(collective, msg, error.some, None, None)
    }
}
