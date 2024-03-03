/*
 * Copyright 2020 Eike K. & Contributors
 *
 * SPDX-License-Identifier: AGPL-3.0-or-later
 */

package docspell.store.file

import cats.data.{NonEmptyList => Nel}
import cats.effect.Sync
import cats.syntax.all._
import fs2.Stream

import docspell.common.{FileKey, LenientUri, UrlReader}

import binny.BinaryId

object FileUrlReader {

  private val scheme: String = "docspell-file"

  def url(key: FileKey): LenientUri =
    LenientUri(
      scheme = Nel.of(scheme),
      authority = Some(""),
      path = LenientUri.NonEmptyPath(
        Nel.of(key.collective.valueAsString, key.category.id.id, key.id.id),
        trailingSlash = false
      ),
      query = None,
      fragment = None
    )

  def apply[F[_]: Sync](repo: FileRepository[F]): UrlReader[F] =
    UrlReader.instance { url =>
      url.scheme.head match {
        case `scheme` =>
          Stream
            .emit(urlToFileKey(url))
            .covary[F]
            .rethrow
            .evalMap(key => repo.findMeta(key).map(m => (key, m)))
            .flatMap {
              case _ -> Some(m) => repo.getBytes(m.id)
              case key -> None =>
                Stream.raiseError(
                  new NoSuchElementException(
                    s"File not found for url '${url.asString}' (key=$key)"
                  )
                )
            }

        case _ =>
          UrlReader.defaultReader[F].apply(url)
      }
    }

  private[file] def urlToFileKey(url: LenientUri): Either[Throwable, FileKey] =
    BinnyUtils
      .binaryIdToFileKey(BinaryId(url.host match {
        case Some(h) if h.nonEmpty => s"$h${url.path.asString}"
        case _                     => url.path.segments.mkString("/")
      }))
      .leftMap(new IllegalArgumentException(_))
}
