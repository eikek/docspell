/*
 * Copyright 2020 Eike K. & Contributors
 *
 * SPDX-License-Identifier: AGPL-3.0-or-later
 */

package docspell.store.file

import javax.sql.DataSource

import cats.data.OptionT
import cats.effect._
import fs2.{Pipe, Stream}

import docspell.common._
import docspell.files.TikaMimetype
import docspell.store.records.RFileMeta

import binny._
import binny.jdbc.{GenericJdbcStore, JdbcStoreConfig}
import doobie._
import scodec.bits.ByteVector

trait FileStore[F[_]] {

  def find(id: Ident): OptionT[F, Stream[F, Byte]]

  def getBytes(id: Ident): Stream[F, Byte]

  def findMeta(id: Ident): OptionT[F, RFileMeta]

  def delete(id: Ident): F[Unit]

  def save(hint: MimeTypeHint): Pipe[F, Byte, Ident]
}

object FileStore {
  private[this] val logger = org.log4s.getLogger

  def apply[F[_]: Sync](
      xa: Transactor[F],
      ds: DataSource,
      chunkSize: Int
  ): FileStore[F] = {
    val attrStore = new AttributeStore[F](xa)
    val cfg = JdbcStoreConfig("filechunk", chunkSize, TikaContentTypeDetect)
    val log = Logger.log4s[F](logger)
    val binStore = GenericJdbcStore[F](ds, LoggerAdapter(log), cfg, attrStore)
    new Impl[F](binStore, attrStore)
  }

  final private class Impl[F[_]](bs: BinaryStore[F], attrStore: AttributeStore[F])
      extends FileStore[F] {
    def find(id: Ident): OptionT[F, Stream[F, Byte]] =
      bs.findBinary(BinaryId(id.id), ByteRange.All)

    def getBytes(id: Ident): Stream[F, Byte] =
      Stream.eval(find(id).value).unNoneTerminate.flatMap(identity)

    def findMeta(id: Ident): OptionT[F, RFileMeta] =
      attrStore.findMeta(BinaryId(id.id))

    def delete(id: Ident): F[Unit] =
      bs.delete(BinaryId(id.id))

    def save(hint: MimeTypeHint): Pipe[F, Byte, Ident] =
      bs.insert(Hint(hint.filename, hint.advertised))
        .andThen(_.map(bid => Ident.unsafe(bid.id)))
  }

  private object LoggerAdapter {
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

  private object TikaContentTypeDetect extends ContentTypeDetect {
    override def detect(data: ByteVector, hint: Hint): SimpleContentType =
      SimpleContentType(
        TikaMimetype
          .detect(data, MimeTypeHint(hint.filename, hint.advertisedType))
          .asString
      )
  }
}
