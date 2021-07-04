/*
 * Copyright 2020 Docspell Contributors
 *
 * SPDX-License-Identifier: GPL-3.0-or-later
 */

package docspell.common

import io.circe._
import io.circe.generic.semiauto._

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
