/*
 * Copyright 2020 Eike K. & Contributors
 *
 * SPDX-License-Identifier: AGPL-3.0-or-later
 */

package docspell.store

import cats.effect._
import cats.effect.unsafe.implicits._

object Docker {

  def exists: IO[Boolean] =
    IO(Runtime.getRuntime.exec(Array("docker", "--version")).waitFor() == 0).attempt
      .map(_.fold(_ => false, identity))

  def existsUnsafe: Boolean =
    exists.unsafeRunSync()
}
