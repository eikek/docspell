/*
 * Copyright 2020 Eike K. & Contributors
 *
 * SPDX-License-Identifier: AGPL-3.0-or-later
 */

package docspell.backend.ops

import cats.data.OptionT
import cats.effect.{Async, Resource}
import cats.implicits._
import fs2.Stream

import docspell.backend.ops.OItemSearch._
import docspell.common._
import docspell.store._
import docspell.store.file.FileMetadata
import docspell.store.queries.{QAttachment, QItem}
import docspell.store.records._

import doobie.implicits._

trait OItemSearch[F[_]] {
  def findItem(id: Ident, collective: CollectiveId): F[Option[ItemData]]

  def findDeleted(
      collective: CollectiveId,
      maxUpdate: Timestamp,
      limit: Int
  ): F[Vector[RItem]]

  def findAttachment(id: Ident, collective: CollectiveId): F[Option[AttachmentData[F]]]

  def findAttachmentSource(
      id: Ident,
      collective: CollectiveId
  ): F[Option[AttachmentSourceData[F]]]

  def findAttachmentArchive(
      id: Ident,
      collective: CollectiveId
  ): F[Option[AttachmentArchiveData[F]]]

  def findAttachmentPreview(
      id: Ident,
      collective: CollectiveId
  ): F[Option[AttachmentPreviewData[F]]]

  def findItemPreview(
      item: Ident,
      collective: CollectiveId
  ): F[Option[AttachmentPreviewData[F]]]

  def findAttachmentMeta(id: Ident, collective: CollectiveId): F[Option[RAttachmentMeta]]

  def findByFileCollective(checksum: String, collective: CollectiveId): F[Vector[RItem]]

  def findByFileSource(checksum: String, sourceId: Ident): F[Option[Vector[RItem]]]

}

object OItemSearch {

  type CustomValue = queries.CustomValue
  val CustomValue = queries.CustomValue

  type Query = queries.Query
  val Query = queries.Query

  type Batch = qb.Batch
  val Batch = docspell.store.qb.Batch

  type ItemFieldValue = queries.ItemFieldValue
  val ItemFieldValue = queries.ItemFieldValue

  type ItemData = queries.ItemData
  val ItemData = queries.ItemData

  trait BinaryData[F[_]] {
    def data: Stream[F, Byte]
    def name: Option[String]
    def meta: FileMetadata
    def fileId: FileKey
  }
  case class AttachmentData[F[_]](
      ra: RAttachment,
      meta: FileMetadata,
      data: Stream[F, Byte]
  ) extends BinaryData[F] {
    val name = ra.name
    val fileId = ra.fileId
  }

  case class AttachmentSourceData[F[_]](
      rs: RAttachmentSource,
      meta: FileMetadata,
      data: Stream[F, Byte]
  ) extends BinaryData[F] {
    val name = rs.name
    val fileId = rs.fileId
  }

  case class AttachmentPreviewData[F[_]](
      rs: RAttachmentPreview,
      meta: FileMetadata,
      data: Stream[F, Byte]
  ) extends BinaryData[F] {
    val name = rs.name
    val fileId = rs.fileId
  }

  case class AttachmentArchiveData[F[_]](
      rs: RAttachmentArchive,
      meta: FileMetadata,
      data: Stream[F, Byte]
  ) extends BinaryData[F] {
    val name = rs.name
    val fileId = rs.fileId
  }

  def apply[F[_]: Async](store: Store[F]): Resource[F, OItemSearch[F]] =
    Resource.pure[F, OItemSearch[F]](new OItemSearch[F] {

      def findItem(id: Ident, collective: CollectiveId): F[Option[ItemData]] =
        store
          .transact(QItem.findItem(id, collective))

      def findDeleted(
          collective: CollectiveId,
          maxUpdate: Timestamp,
          limit: Int
      ): F[Vector[RItem]] =
        store
          .transact(RItem.findDeleted(collective, maxUpdate, limit))
          .take(limit.toLong)
          .compile
          .toVector

      def findAttachment(
          id: Ident,
          collective: CollectiveId
      ): F[Option[AttachmentData[F]]] =
        store
          .transact(RAttachment.findByIdAndCollective(id, collective))
          .flatMap {
            case Some(ra) =>
              makeBinaryData(ra.fileId) { m =>
                AttachmentData[F](
                  ra,
                  m,
                  store.fileRepo.getBytes(m.id)
                )
              }

            case None =>
              (None: Option[AttachmentData[F]]).pure[F]
          }

      def findAttachmentSource(
          id: Ident,
          collective: CollectiveId
      ): F[Option[AttachmentSourceData[F]]] =
        store
          .transact(RAttachmentSource.findByIdAndCollective(id, collective))
          .flatMap {
            case Some(ra) =>
              makeBinaryData(ra.fileId) { m =>
                AttachmentSourceData[F](
                  ra,
                  m,
                  store.fileRepo.getBytes(m.id)
                )
              }

            case None =>
              (None: Option[AttachmentSourceData[F]]).pure[F]
          }

      def findAttachmentPreview(
          id: Ident,
          collective: CollectiveId
      ): F[Option[AttachmentPreviewData[F]]] =
        store
          .transact(RAttachmentPreview.findByIdAndCollective(id, collective))
          .flatMap {
            case Some(ra) =>
              makeBinaryData(ra.fileId) { m =>
                AttachmentPreviewData[F](
                  ra,
                  m,
                  store.fileRepo.getBytes(m.id)
                )
              }

            case None =>
              (None: Option[AttachmentPreviewData[F]]).pure[F]
          }

      def findItemPreview(
          item: Ident,
          collective: CollectiveId
      ): F[Option[AttachmentPreviewData[F]]] =
        store
          .transact(RAttachmentPreview.findByItemAndCollective(item, collective))
          .flatMap {
            case Some(ra) =>
              makeBinaryData(ra.fileId) { m =>
                AttachmentPreviewData[F](
                  ra,
                  m,
                  store.fileRepo.getBytes(m.id)
                )
              }

            case None =>
              (None: Option[AttachmentPreviewData[F]]).pure[F]
          }

      def findAttachmentArchive(
          id: Ident,
          collective: CollectiveId
      ): F[Option[AttachmentArchiveData[F]]] =
        store
          .transact(RAttachmentArchive.findByIdAndCollective(id, collective))
          .flatMap {
            case Some(ra) =>
              makeBinaryData(ra.fileId) { m =>
                AttachmentArchiveData[F](
                  ra,
                  m,
                  store.fileRepo.getBytes(m.id)
                )
              }

            case None =>
              (None: Option[AttachmentArchiveData[F]]).pure[F]
          }

      private def makeBinaryData[A](fileId: FileKey)(f: FileMetadata => A): F[Option[A]] =
        OptionT(
          store.fileRepo
            .findMeta(fileId)
        )
          .map(fm => f(fm))
          .value

      def findAttachmentMeta(
          id: Ident,
          collective: CollectiveId
      ): F[Option[RAttachmentMeta]] =
        store.transact(QAttachment.getAttachmentMeta(id, collective))

      def findByFileCollective(
          checksum: String,
          collective: CollectiveId
      ): F[Vector[RItem]] =
        store.transact(QItem.findByChecksum(checksum, collective, Set.empty))

      def findByFileSource(checksum: String, sourceId: Ident): F[Option[Vector[RItem]]] =
        store.transact((for {
          coll <- OptionT(RSource.findCollectiveId(sourceId))
          items <- OptionT.liftF(QItem.findByChecksum(checksum, coll, Set.empty))
        } yield items).value)
    })
}
