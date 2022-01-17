/*
 * Copyright 2020 Eike K. & Contributors
 *
 * SPDX-License-Identifier: AGPL-3.0-or-later
 */

package docspell.restserver.conv

import cats.data.NonEmptyList
import cats.effect._

trait NonEmptyListSupport {

  def requireNonEmpty[F[_]: Sync, A](list: List[A]): F[NonEmptyList[A]] =
    NonEmptyList.fromList(list) match {
      case Some(nel) => Sync[F].pure(nel)
      case None =>
        Sync[F].raiseError(new IllegalArgumentException("Empty list not allowed"))
    }
}
