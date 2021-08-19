/*
 * Copyright 2020 Docspell Contributors
 *
 * SPDX-License-Identifier: GPL-3.0-or-later
 */

package docspell.joex.updatecheck

import cats.effect._

import docspell.joex.BuildInfo

import io.circe.Decoder
import io.circe.generic.semiauto._
import org.http4s.circe.CirceEntityDecoder._
import org.http4s.client.Client
import org.http4s.implicits._

trait UpdateCheck[F[_]] {

  def latestRelease: F[UpdateCheck.Release]

}

object UpdateCheck {

  val currentVersion: String =
    BuildInfo.version

  final case class Release(
      html_url: String,
      id: Int,
      tag_name: String,
      name: String,
      created_at: String,
      published_at: String
  ) {

    def version: String = tag_name

    def isCurrent: Boolean = {
      val version = BuildInfo.version
      version.endsWith("SNAPSHOT") || version == tag_name
    }

  }

  object Release {
    implicit val jsonDecoder: Decoder[Release] =
      deriveDecoder[Release]
  }

  def apply[F[_]: Async](client: Client[F]): UpdateCheck[F] =
    new UpdateCheck[F] {
      def latestRelease: F[UpdateCheck.Release] =
        client.expect[Release](latestReleaseUrl)
    }

  def resource[F[_]: Async](client: Client[F]): Resource[F, UpdateCheck[F]] =
    Resource.pure(UpdateCheck[F](client))

  private[this] val latestReleaseUrl =
    uri"https://api.github.com/repos/eikek/docspell/releases/latest"
}
