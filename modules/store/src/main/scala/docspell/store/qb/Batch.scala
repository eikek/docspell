/*
 * Copyright 2020 Eike K. & Contributors
 *
 * SPDX-License-Identifier: AGPL-3.0-or-later
 */

package docspell.store.qb

case class Batch(offset: Int, limit: Int) {
  def restrictLimitTo(n: Int): Batch =
    Batch(offset, math.min(n, limit))

  def next: Batch =
    Batch(offset + limit, limit)

  def first: Batch =
    Batch(0, limit)
}

object Batch {
  val all: Batch = Batch(0, Int.MaxValue)

  def page(n: Int, size: Int): Batch =
    Batch(n * size, size)

  def limit(c: Int): Batch =
    Batch(0, c)
}
