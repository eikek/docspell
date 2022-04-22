/*
 * Copyright 2020 Eike K. & Contributors
 *
 * SPDX-License-Identifier: AGPL-3.0-or-later
 */

package docspell.addons.out

import cats.kernel.Monoid

import docspell.common.bc.BackendCommand

import io.circe.generic.extras.Configuration
import io.circe.generic.extras.semiauto.{deriveConfiguredDecoder, deriveConfiguredEncoder}
import io.circe.{Decoder, Encoder}

/** Decoded stdout result from executing an addon. */
case class AddonOutput(
    commands: List[BackendCommand] = Nil,
    files: List[ItemFile] = Nil,
    newItems: List[NewItem] = Nil
)

object AddonOutput {
  val empty: AddonOutput = AddonOutput()

  def combine(a: AddonOutput, b: AddonOutput): AddonOutput =
    AddonOutput(a.commands ++ b.commands, a.files ++ b.files)

  implicit val addonResultMonoid: Monoid[AddonOutput] =
    Monoid.instance(empty, combine)

  implicit val jsonConfig: Configuration =
    Configuration.default.withDefaults

  implicit val jsonDecoder: Decoder[AddonOutput] = deriveConfiguredDecoder
  implicit val jsonEncoder: Encoder[AddonOutput] = deriveConfiguredEncoder

  def fromString(str: String): Either[Throwable, AddonOutput] =
    io.circe.parser.decode[AddonOutput](str)

  def unsafeFromString(str: String): AddonOutput =
    fromString(str).fold(throw _, identity)
}
