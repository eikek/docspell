/*
 * Copyright 2020 Eike K. & Contributors
 *
 * SPDX-License-Identifier: AGPL-3.0-or-later
 */

package docspell.scheduler

/** Special "marker" exception to indicate errors in tasks, that should NOT be retried. */
final class PermanentError(cause: Throwable) extends RuntimeException(cause) {
  override def fillInStackTrace() = this
}

object PermanentError {
  def apply(cause: Throwable): PermanentError =
    new PermanentError(cause)

  def isPermanent(ex: Throwable): Boolean =
    unapply(ex).isDefined

  def unapply(ex: Throwable): Option[Throwable] =
    ex match {
      case p: PermanentError => Some(p.getCause)
      case _                 => None
    }
}
