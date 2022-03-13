/*
 * Copyright 2020 Eike K. & Contributors
 *
 * SPDX-License-Identifier: AGPL-3.0-or-later
 */

package docspell.common.syntax

import io.circe.Decoder
import io.circe.parser

trait StringSyntax {
  implicit class EvenMoreStringOps(s: String) {
    def asNonBlank: Option[String] =
      Option(s).filter(_.trim.nonEmpty)

    def parseJsonAs[A](implicit d: Decoder[A]): Either[Throwable, A] =
      for {
        json <- parser.decode[A](s)
      } yield json
  }
}

object StringSyntax extends StringSyntax
