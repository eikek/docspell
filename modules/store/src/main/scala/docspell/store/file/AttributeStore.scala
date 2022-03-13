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

private[file] trait AttributeStore[F[_]] extends BinaryAttributeStore[F] {
  def findMeta(id: BinaryId): OptionT[F, RFileMeta]
}

private[file] object AttributeStore {
  def empty[F[_]: Applicative]: AttributeStore[F] =
    new AttributeStore[F] {
      val delegate = BinaryAttributeStore.empty[F]

      def findMeta(id: BinaryId) =
        OptionT.none

      def saveAttr(id: BinaryId, attrs: F[BinaryAttributes]) =
        delegate.saveAttr(id, attrs)

      def deleteAttr(id: BinaryId) =
        delegate.deleteAttr(id)

      def findAttr(id: BinaryId) =
        delegate.findAttr(id)
    }

  def apply[F[_]: Sync](xa: Transactor[F]): AttributeStore[F] =
    new Impl[F](xa)

  final private class Impl[F[_]: Sync](xa: Transactor[F]) extends AttributeStore[F] {
    def saveAttr(id: BinaryId, attrs: F[BinaryAttributes]): F[Unit] =
      for {
        now <- Timestamp.current[F]
        a <- attrs
        fileKey <- makeFileKey(id)
        fm = RFileMeta(
          fileKey,
          now,
          MimeType.parse(a.contentType.contentType).getOrElse(MimeType.octetStream),
          ByteSize(a.length),
          a.sha256
        )
        _ <- RFileMeta.insert(fm).transact(xa)
      } yield ()

    def deleteAttr(id: BinaryId): F[Boolean] =
      makeFileKey(id).flatMap(fileKey =>
        RFileMeta.delete(fileKey).transact(xa).map(_ > 0)
      )

    def findAttr(id: BinaryId): OptionT[F, BinaryAttributes] =
      findMeta(id).map(fm =>
        BinaryAttributes(
          fm.checksum,
          SimpleContentType(fm.mimetype.asString),
          fm.length.bytes
        )
      )

    def findMeta(id: BinaryId): OptionT[F, RFileMeta] =
      OptionT(
        makeFileKey(id).flatMap(fileKey => RFileMeta.findById(fileKey).transact(xa))
      )

    private def makeFileKey(binaryId: BinaryId): F[FileKey] =
      Sync[F]
        .pure(
          BinnyUtils.binaryIdToFileKey(binaryId).left.map(new IllegalStateException(_))
        )
        .rethrow
  }
}
