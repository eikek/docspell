/*
 * Copyright 2020 Eike K. & Contributors
 *
 * SPDX-License-Identifier: AGPL-3.0-or-later
 */

package db.migration.data

import docspell.common._
import io.circe._
import io.circe.generic.semiauto._

/** @deprecated
  *   This structure has been replaced with one using a `CollectiveId`
  */
final case class ReIndexTaskArgs(collective: Option[Ident])

object ReIndexTaskArgs {
  val taskName = Ident.unsafe("full-text-reindex")

  def tracker(args: ReIndexTaskArgs): Ident =
    args.collective match {
      case Some(cid) =>
        cid / DocspellSystem.migrationTaskTracker
      case None =>
        DocspellSystem.migrationTaskTracker
    }

  implicit val jsonEncoder: Encoder[ReIndexTaskArgs] =
    deriveEncoder[ReIndexTaskArgs]

  implicit val jsonDecoder: Decoder[ReIndexTaskArgs] =
    deriveDecoder[ReIndexTaskArgs]
}
