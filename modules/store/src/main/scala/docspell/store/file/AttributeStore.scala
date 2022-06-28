/*
 * Copyright 2020 Eike K. & Contributors
 *
 * SPDX-License-Identifier: AGPL-3.0-or-later
 */

package docspell.store.file

import cats.Applicative
import cats.data.OptionT
import cats.effect._
import cats.implicits._

import docspell.common._
import docspell.store.records.RFileMeta

import binny._
import doobie._
import doobie.implicits._

trait AttributeStore[F[_]] {
  def saveAttr(key: FileKey, attrs: BinaryAttributes): F[Unit]

  def deleteAttr(key: FileKey): F[Boolean]

  def findMeta(key: FileKey): OptionT[F, RFileMeta]
}

private[file] object AttributeStore {
  def empty[F[_]: Applicative]: AttributeStore[F] =
    new AttributeStore[F] {
      override def saveAttr(key: FileKey, attrs: BinaryAttributes) = ().pure[F]

      override def deleteAttr(key: FileKey) = false.pure[F]

      override def findMeta(key: FileKey) = OptionT.none[F, RFileMeta]
    }

  def apply[F[_]: Sync](xa: Transactor[F]): AttributeStore[F] =
    new Impl[F](xa)

  final private class Impl[F[_]: Sync](xa: Transactor[F]) extends AttributeStore[F] {
    def saveAttr(key: FileKey, attrs: BinaryAttributes): F[Unit] =
      for {
        now <- Timestamp.current[F]
        fm = RFileMeta(
          key,
          now,
          MimeType.parse(attrs.contentType.contentType).getOrElse(MimeType.octetStream),
          ByteSize(attrs.length),
          attrs.sha256
        )
        _ <- RFileMeta.insert(fm).transact(xa)
      } yield ()

    def deleteAttr(key: FileKey): F[Boolean] =
      RFileMeta.delete(key).transact(xa).map(_ > 0)

    def findMeta(key: FileKey): OptionT[F, RFileMeta] =
      OptionT(RFileMeta.findById(key).transact(xa))

//    private def makeFileKey(binaryId: BinaryId): F[FileKey] =
//      Sync[F]
//        .pure(
//          BinnyUtils.binaryIdToFileKey(binaryId).left.map(new IllegalStateException(_))
//        )
//        .rethrow
  }
}
