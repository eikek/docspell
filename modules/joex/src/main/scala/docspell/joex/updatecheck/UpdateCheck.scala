/*
 * Copyright 2020 Eike K. & Contributors
 *
 * SPDX-License-Identifier: AGPL-3.0-or-later
 */

package docspell.joex.updatecheck

import cats.effect._

import io.circe.Decoder
import io.circe.generic.semiauto._
import org.http4s.circe.CirceEntityDecoder._
import org.http4s.client.Client
import org.http4s.implicits._

trait UpdateCheck[F[_]] {

  def latestRelease: F[UpdateCheck.Release]

}

object UpdateCheck {

  final case class Release(
      html_url: String,
      id: Int,
      tag_name: String,
      name: String,
      created_at: String,
      published_at: String
  ) {

    def version: String = tag_name.replaceFirst("v", "")

    /** Checks if `thisVersion` is either a SNAPSHOT version or the same as this release.
      */
    def matchesVersion(tv: ThisVersion): Boolean = {
      val myVersion = tv.get
      myVersion.endsWith("SNAPSHOT") || myVersion == version
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
