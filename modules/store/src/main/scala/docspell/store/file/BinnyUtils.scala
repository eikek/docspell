/*
 * Copyright 2020 Eike K. & Contributors
 *
 * SPDX-License-Identifier: AGPL-3.0-or-later
 */

package docspell.store.file

import javax.sql.DataSource

import cats.effect._
import fs2.io.file.Path

import docspell.common._
import docspell.files.TikaMimetype
import docspell.logging.Logger

import binny._
import binny.fs.{FsBinaryStore, FsStoreConfig, PathMapping}
import binny.jdbc.{GenericJdbcStore, JdbcStoreConfig}
import binny.minio.{MinioBinaryStore, MinioConfig, S3KeyMapping}
import scodec.bits.ByteVector

object BinnyUtils {

  def fileKeyToBinaryId(fk: FileKey): BinaryId =
    BinaryId(s"${fk.collective.id}/${fk.category.id.id}/${fk.id.id}")

  def fileKeyPartToPrefix(fkp: FileKeyPart): Option[String] =
    fkp match {
      case FileKeyPart.Empty              => None
      case FileKeyPart.Collective(cid)    => Some(s"${cid.id}/%")
      case FileKeyPart.Category(cid, cat) => Some(s"${cid.id}/${cat.id.id}/%")
      case FileKeyPart.Key(key)           => Some(fileKeyToBinaryId(key).id)
    }

  def binaryIdToFileKey(bid: BinaryId): Either[String, FileKey] =
    bid.id.split('/').toList match {
      case cId :: catId :: fId :: Nil =>
        for {
          coll <- Ident.fromString(cId)
          cat <- FileCategory.fromString(catId)
          file <- Ident.fromString(fId)
        } yield FileKey(coll, cat, file)
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

  val pathMapping: PathMapping = {
    import binny.fs.PathMapping.syntax._

    def toPath(base: Path, binaryId: BinaryId): Path = {
      val fkey = unsafeBinaryIdToFileKey(binaryId)
      base / fkey.collective.id / fkey.category.id.id / fkey.id.id / "file"
    }

    def toId(file: Path): Option[BinaryId] =
      for {
        id <- file.parent
        cat <- id.parent
        fcat <- FileCategory.fromString(cat.asId.id).toOption
        coll <- cat.parent
        fkey = FileKey(Ident.unsafe(coll.asId.id), fcat, Ident.unsafe(id.asId.id))
      } yield fileKeyToBinaryId(fkey)

    PathMapping(toPath)(toId)
  }

  def binaryStore[F[_]: Async](
      cfg: FileRepositoryConfig,
      attrStore: AttributeStore[F],
      ds: DataSource,
      logger: Logger[F]
  ): BinaryStore[F] =
    cfg match {
      case FileRepositoryConfig.Database(chunkSize) =>
        val jdbcConfig =
          JdbcStoreConfig("filechunk", chunkSize, BinnyUtils.TikaContentTypeDetect)
        GenericJdbcStore[F](ds, LoggerAdapter(logger), jdbcConfig, attrStore)

      case FileRepositoryConfig.S3(endpoint, accessKey, secretKey, bucket, chunkSize) =>
        val keyMapping = S3KeyMapping.constant(bucket)
        val minioCfg = MinioConfig
          .default(endpoint, accessKey, secretKey, keyMapping)
          .copy(chunkSize = chunkSize, detect = BinnyUtils.TikaContentTypeDetect)

        MinioBinaryStore[F](minioCfg, attrStore, LoggerAdapter(logger))

      case FileRepositoryConfig.Directory(path, chunkSize) =>
        val fsConfig = FsStoreConfig(
          path,
          BinnyUtils.TikaContentTypeDetect,
          FsStoreConfig.OverwriteMode.Fail,
          BinnyUtils.pathMapping,
          chunkSize
        )
        FsBinaryStore[F](fsConfig, LoggerAdapter(logger), attrStore)
    }
}
