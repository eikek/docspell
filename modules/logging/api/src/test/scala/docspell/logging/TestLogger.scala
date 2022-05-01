/*
 * Copyright 2020 Eike K. & Contributors
 *
 * SPDX-License-Identifier: AGPL-3.0-or-later
 */

package docspell.logging

import java.util.concurrent.atomic.AtomicReference

import cats.Id

class TestLogger extends Logger[Id] {

  private[this] val events: AtomicReference[Vector[LogEvent]] =
    new AtomicReference(Vector.empty)

  def log(ev: => LogEvent): Id[Unit] = {
    events.getAndUpdate(v => v :+ ev)
    ()
  }

  def getEvents: Vector[LogEvent] = events.get()

  def asUnsafe = this
}

object TestLogger {
  def apply(): TestLogger = new TestLogger
}
