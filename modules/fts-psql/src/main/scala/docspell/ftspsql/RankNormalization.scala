/*
 * Copyright 2020 Eike K. & Contributors
 *
 * SPDX-License-Identifier: AGPL-3.0-or-later
 */

package docspell.ftspsql

import cats.Order
import cats.data.NonEmptySet

sealed trait RankNormalization { self =>
  def value: NonEmptySet[Int]

  def &&(other: RankNormalization): RankNormalization =
    new RankNormalization { val value = self.value ++ other.value }
}

object RankNormalization {
// see https://www.postgresql.org/docs/14/textsearch-controls.html#TEXTSEARCH-RANKING

  case object IgnoreDocLength extends RankNormalization { val value = NonEmptySet.one(0) }
  case object LogDocLength extends RankNormalization { val value = NonEmptySet.one(1) }
  case object DocLength extends RankNormalization { val value = NonEmptySet.one(2) }
  case object Mhd extends RankNormalization { val value = NonEmptySet.one(4) }
  case object UniqueWords extends RankNormalization { val value = NonEmptySet.one(8) }
  case object LogUniqueWords extends RankNormalization { val value = NonEmptySet.one(16) }
  case object Scale extends RankNormalization { val value = NonEmptySet.one(32) }

  def byNumber(n: Int): Either[String, RankNormalization] =
    all.find(_.value.contains(n)).toRight(s"Unknown rank normalization number: $n")

  implicit val order: Order[RankNormalization] =
    Order.by(_.value.reduce)

  val all: NonEmptySet[RankNormalization] =
    NonEmptySet.of(
      IgnoreDocLength,
      LogDocLength,
      DocLength,
      Mhd,
      UniqueWords,
      LogUniqueWords,
      Scale
    )
}
