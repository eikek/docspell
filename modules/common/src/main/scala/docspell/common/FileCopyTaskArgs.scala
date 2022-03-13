/*
 * Copyright 2020 Eike K. & Contributors
 *
 * SPDX-License-Identifier: AGPL-3.0-or-later
 */

package docspell.common

import cats.data.NonEmptyList

import docspell.common.FileCopyTaskArgs.Selection

import io.circe.generic.semiauto.{deriveDecoder, deriveEncoder}
import io.circe.syntax._
import io.circe.{Decoder, Encoder}

/** This is the input to the `FileCopyTask`. The task copies all files from on
  * FileRepository to one ore more target repositories.
  *
  * If no `from` is given, the default file repository is used. For targets, a list of ids
  * can be specified that must match a configured file store in the config file. When
  * selecting "all", it means all enabled stores.
  */
final case class FileCopyTaskArgs(from: Option[Ident], to: Selection)

object FileCopyTaskArgs {
  val taskName = Ident.unsafe("copy-file-repositories")

  sealed trait Selection

  object Selection {

    case object All extends Selection
    case class Stores(ids: NonEmptyList[Ident]) extends Selection

    implicit val jsonEncoder: Encoder[Selection] =
      Encoder.instance {
        case All         => "!all".asJson
        case Stores(ids) => ids.toList.asJson
      }

    implicit val jsonDecoder: Decoder[Selection] =
      Decoder.instance { cursor =>
        cursor.value.asString match {
          case Some(s) if s.equalsIgnoreCase("!all") => Right(All)
          case _ => cursor.value.as[NonEmptyList[Ident]].map(Stores.apply)
        }
      }
  }

  implicit val jsonDecoder: Decoder[FileCopyTaskArgs] =
    deriveDecoder

  implicit val jsonEncoder: Encoder[FileCopyTaskArgs] =
    deriveEncoder
}
