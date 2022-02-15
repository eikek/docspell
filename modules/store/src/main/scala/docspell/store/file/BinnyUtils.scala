/*
 * Copyright 2020 Eike K. & Contributors
 *
 * SPDX-License-Identifier: AGPL-3.0-or-later
 */

package docspell.store.file

import docspell.common
import docspell.common._
import docspell.files.TikaMimetype

import binny._
import scodec.bits.ByteVector

private[store] object BinnyUtils {

  def fileKeyToBinaryId(fk: FileKey): BinaryId =
    BinaryId(s"${fk.collective.id}/${fk.category.id.id}/${fk.id.id}")

  def binaryIdToFileKey(bid: BinaryId): Either[String, FileKey] =
    bid.id.split('/').toList match {
      case cId :: catId :: fId :: Nil =>
        for {
          coll <- Ident.fromString(cId)
          cat <- FileCategory.fromString(catId)
          file <- Ident.fromString(fId)
        } yield common.FileKey(coll, cat, file)
      case _ =>
        Left(s"Invalid format for file-key: $bid")
    }

  def unsafeBinaryIdToFileKey(bid: BinaryId): FileKey =
    binaryIdToFileKey(bid).fold(
      err => throw new IllegalStateException(err),
      identity
    )

  object LoggerAdapter {
    def apply[F[_]](log: Logger[F]): binny.util.Logger[F] =
      new binny.util.Logger[F] {
        override def trace(msg: => String): F[Unit] = log.trace(msg)
        override def debug(msg: => String): F[Unit] = log.debug(msg)
        override def info(msg: => String): F[Unit] = log.info(msg)
        override def warn(msg: => String): F[Unit] = log.warn(msg)
        override def error(msg: => String): F[Unit] = log.error(msg)
        override def error(ex: Throwable)(msg: => String): F[Unit] = log.error(ex)(msg)
      }
  }

  object TikaContentTypeDetect extends ContentTypeDetect {
    override def detect(data: ByteVector, hint: Hint): SimpleContentType =
      SimpleContentType(
        TikaMimetype
          .detect(data, MimeTypeHint(hint.filename, hint.advertisedType))
          .asString
      )
  }
}
