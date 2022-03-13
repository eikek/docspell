/*
 * Copyright 2020 Eike K. & Contributors
 *
 * SPDX-License-Identifier: AGPL-3.0-or-later
 */

package docspell.scheduler.usertask

import com.github.eikek.calev.CalEvent
import docspell.common._
import io.circe.Encoder

final case class UserTask[A](
    id: Ident,
    name: Ident,
    enabled: Boolean,
    timer: CalEvent,
    summary: Option[String],
    args: A
) {

  def encode(implicit E: Encoder[A]): UserTask[String] =
    copy(args = E(args).noSpaces)

  def withArgs[B](newArgs: B): UserTask[B] =
    copy(args = newArgs)

  def mapArgs[B](f: A => B): UserTask[B] =
    withArgs(f(args))
}
