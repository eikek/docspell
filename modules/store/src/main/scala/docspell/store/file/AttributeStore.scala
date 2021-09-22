/*
 * Copyright 2020 Eike K. & Contributors
 *
 * SPDX-License-Identifier: AGPL-3.0-or-later
 */

package docspell.store.file

import cats.data.OptionT
import cats.effect._
import cats.implicits._

import docspell.common._
import docspell.store.records.RFileMeta

import binny._
import doobie._
import doobie.implicits._

final private[file] class AttributeStore[F[_]: Sync](xa: Transactor[F])
    extends BinaryAttributeStore[F] {
  def saveAttr(id: BinaryId, attrs: F[BinaryAttributes]): F[Unit] =
    for {
      now <- Timestamp.current[F]
      a   <- attrs
      fm = RFileMeta(
        Ident.unsafe(id.id),
        now,
        MimeType.parse(a.contentType.contentType).getOrElse(MimeType.octetStream),
        ByteSize(a.length),
        a.sha256
      )
      _ <- RFileMeta.insert(fm).transact(xa)
    } yield ()

  def deleteAttr(id: BinaryId): F[Boolean] =
    RFileMeta.delete(Ident.unsafe(id.id)).transact(xa).map(_ > 0)

  def findAttr(id: BinaryId): OptionT[F, BinaryAttributes] =
    findMeta(id).map(fm =>
      BinaryAttributes(
        fm.checksum,
        SimpleContentType(fm.mimetype.asString),
        fm.length.bytes
      )
    )

  def findMeta(id: BinaryId): OptionT[F, RFileMeta] =
    OptionT(RFileMeta.findById(Ident.unsafe(id.id)).transact(xa))
}
