/*
 * Copyright 2020 Eike K. & Contributors
 *
 * SPDX-License-Identifier: AGPL-3.0-or-later
 */

package docspell.extract.rtf

import java.io.{ByteArrayInputStream, InputStream}
import javax.swing.text.rtf.RTFEditorKit

import scala.util.Try

import cats.effect.Sync
import cats.implicits._
import fs2.Stream

import docspell.common.MimeType
import docspell.extract.internal.Text

object RtfExtract {

  val rtfType = MimeType.application("rtf")

  def get(is: InputStream): Either[Throwable, Text] =
    Try {
      val kit = new RTFEditorKit
      val doc = kit.createDefaultDocument()
      kit.read(is, doc, 0)
      Text(doc.getText(0, doc.getLength))
    }.toEither

  def get[F[_]: Sync](data: Stream[F, Byte]): F[Either[Throwable, Text]] =
    data.compile.to(Array).map(new ByteArrayInputStream(_)).map(get)
}
