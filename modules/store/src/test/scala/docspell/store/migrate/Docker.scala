/*
 * Copyright 2020 Docspell Contributors
 *
 * SPDX-License-Identifier: GPL-3.0-or-later
 */

package docspell.store.migrate
import cats.effect._
import cats.effect.unsafe.implicits._

object Docker {

  def exists: IO[Boolean] =
    IO(Runtime.getRuntime.exec(Array("docker", "--version")).waitFor() == 0).attempt
      .map(_.fold(_ => false, identity))

  def existsUnsafe: Boolean =
    exists.unsafeRunSync()
}
