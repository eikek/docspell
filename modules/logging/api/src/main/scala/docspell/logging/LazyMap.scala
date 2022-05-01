/*
 * Copyright 2020 Eike K. & Contributors
 *
 * SPDX-License-Identifier: AGPL-3.0-or-later
 */

package docspell.logging

import docspell.logging.LazyMap.Val

final class LazyMap[A, B](
    private val values: Map[A, Val[B]]
) {
  lazy val toMap: Map[A, B] = values.view.mapValues(_.value).toMap

  def updated(key: A, value: => B): LazyMap[A, B] =
    new LazyMap(values.updated(key, Val(value)))

  def get(key: A): Option[() => B] =
    values.get(key).map(e => () => e.value)

  def ++(lm: LazyMap[A, B]): LazyMap[A, B] =
    new LazyMap(values ++ lm.values)

  def addMap(m: Map[A, B]): LazyMap[A, B] =
    this ++ LazyMap.fromMap(m)

  def toDeferred: Map[A, () => B] =
    values.view.mapValues(e => () => e.value).toMap
}

object LazyMap {
  private[this] val emptyMap = new LazyMap[Any, Any](Map.empty)

  def empty[A, B]: LazyMap[A, B] = emptyMap.asInstanceOf[LazyMap[A, B]]

  def fromMap[A, B](m: Map[A, B]): LazyMap[A, B] =
    new LazyMap(m.view.mapValues(a => Val(a)).toMap)

  final private class Val[B](v: => B) {
    lazy val value = v
  }
  private object Val {
    def apply[B](v: => B): Val[B] = new Val(v)
  }
}
