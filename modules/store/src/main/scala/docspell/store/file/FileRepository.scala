/*
 * Copyright 2020 Eike K. & Contributors
 *
 * SPDX-License-Identifier: AGPL-3.0-or-later
 */

package docspell.store.file

import javax.sql.DataSource

import cats.effect._
import fs2._

import docspell.common._

import binny.BinaryId
import binny.jdbc.{GenericJdbcStore, JdbcStoreConfig}
import doobie.Transactor

trait FileRepository[F[_]] {
  def getBytes(key: FileKey): Stream[F, Byte]

  def findMeta(key: FileKey): F[Option[FileMetadata]]

  def delete(key: FileKey): F[Unit]

  def save(
      collective: Ident,
      category: FileCategory,
      hint: MimeTypeHint
  ): Pipe[F, Byte, FileKey]
}

object FileRepository {
  private[this] val logger = org.log4s.getLogger

  def genericJDBC[F[_]: Sync](
      xa: Transactor[F],
      ds: DataSource,
      chunkSize: Int
  ): FileRepository[F] = {
    val attrStore = new AttributeStore[F](xa)
    val cfg = JdbcStoreConfig("filechunk", chunkSize, BinnyUtils.TikaContentTypeDetect)
    val log = Logger.log4s[F](logger)
    val binStore = GenericJdbcStore[F](ds, BinnyUtils.LoggerAdapter(log), cfg, attrStore)
    val keyFun: FileKey => BinaryId = BinnyUtils.fileKeyToBinaryId

    new FileRepositoryImpl[F](binStore, attrStore, keyFun)
  }
}
