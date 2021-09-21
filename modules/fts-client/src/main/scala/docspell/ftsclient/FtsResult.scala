/*
 * Copyright 2020 Eike K. & Contributors
 *
 * SPDX-License-Identifier: AGPL-3.0-or-later
 */

package docspell.ftsclient

import docspell.common._
import docspell.ftsclient.FtsResult.ItemMatch

final case class FtsResult(
    qtime: Duration,
    count: Int,
    maxScore: Double,
    highlight: Map[Ident, List[String]],
    results: List[ItemMatch]
) {}

object FtsResult {

  val empty =
    FtsResult(Duration.millis(0), 0, 0.0, Map.empty, Nil)

  sealed trait MatchData
  case class AttachmentData(attachId: Ident, attachName: String) extends MatchData
  case object ItemData                                           extends MatchData

  case class ItemMatch(
      id: Ident,
      itemId: Ident,
      collectiveId: Ident,
      score: Double,
      data: MatchData
  )
}
