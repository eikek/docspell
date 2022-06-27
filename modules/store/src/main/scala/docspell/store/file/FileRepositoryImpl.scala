/*
 * Copyright 2020 Eike K. & Contributors
 *
 * SPDX-License-Identifier: AGPL-3.0-or-later
 */

package docspell.store.file

import cats.data.OptionT
import cats.effect.Sync
import cats.implicits._
import fs2.{Pipe, Stream}

import docspell.common._

import binny._

final class FileRepositoryImpl[F[_]: Sync](
    val config: FileRepositoryConfig,
    val bs: BinaryStore[F],
    val attrStore: AttributeStore[F],
    keyFun: FileKey => BinaryId
) extends FileRepository[F] {

  def find(key: FileKey): OptionT[F, Stream[F, Byte]] =
    bs.findBinary(keyFun(key), ByteRange.All)

  def getBytes(key: FileKey): Stream[F, Byte] =
    Stream.eval(find(key).value).unNoneTerminate.flatMap(identity)

  def findMeta(key: FileKey): F[Option[FileMetadata]] =
    attrStore
      .findMeta(key)
      .map(rfm =>
        FileMetadata(rfm.id, rfm.created, rfm.mimetype, rfm.length, rfm.checksum)
      )
      .value

  def delete(key: FileKey): F[Unit] =
    bs.delete(keyFun(key)) *> attrStore.deleteAttr(key).void

  def save(
      collective: Ident,
      category: FileCategory,
      hint: MimeTypeHint
  ): Pipe[F, Byte, FileKey] = {
    val fhint = Hint(hint.filename, hint.advertised)
    in =>
      Stream
        .eval(randomKey(collective, category))
        .flatMap(fkey => in.through(bs.insertWith(keyFun(fkey))) ++ Stream.emit(fkey))
        .evalTap { key =>
          val bid = keyFun(key)
          bs.computeAttr(bid, fhint)
            .run(AttributeName.all)
            .semiflatMap(attr => attrStore.saveAttr(key, attr))
            .value
            .void
        }
  }

  def randomKey(
      collective: Ident,
      category: FileCategory
  ): F[FileKey] =
    BinaryId.random[F].map(bid => FileKey(collective, category, Ident.unsafe(bid.id)))
}
