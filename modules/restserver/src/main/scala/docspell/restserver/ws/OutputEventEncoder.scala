/*
 * Copyright 2020 Eike K. & Contributors
 *
 * SPDX-License-Identifier: AGPL-3.0-or-later
 */

package docspell.restserver.ws

trait OutputEventEncoder[A] {
  def encode(a: A): OutputEvent
}

object OutputEventEncoder {
  def apply[A](implicit e: OutputEventEncoder[A]): OutputEventEncoder[A] = e

  def instance[A](f: A => OutputEvent): OutputEventEncoder[A] =
    (a: A) => f(a)
}
