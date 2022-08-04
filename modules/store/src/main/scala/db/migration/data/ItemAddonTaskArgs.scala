/*
 * Copyright 2020 Eike K. & Contributors
 *
 * SPDX-License-Identifier: AGPL-3.0-or-later
 */

package db.migration.data

import docspell.common._
import io.circe.generic.semiauto.{deriveDecoder, deriveEncoder}
import io.circe.{Decoder, Encoder}

/** Arguments to submit a task that runs addons configured for some existing item.
  *
  * If `addonTaskIds` is non empty, only these addon tasks are run. Otherwise all addon
  * tasks that are configured for 'existing-item' are run.
  *
  * @deprecated
  *   replaced with version using a `CollectiveId`
  */
final case class ItemAddonTaskArgs(
    collective: Ident,
    itemId: Ident,
    addonRunConfigs: Set[Ident]
)

object ItemAddonTaskArgs {
  val taskName: Ident = Ident.unsafe("addon-existing-item")

  implicit val jsonDecoder: Decoder[ItemAddonTaskArgs] = deriveDecoder
  implicit val jsonEncoder: Encoder[ItemAddonTaskArgs] = deriveEncoder
}
