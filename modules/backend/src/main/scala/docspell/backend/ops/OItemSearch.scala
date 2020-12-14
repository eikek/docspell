package docspell.backend.ops

import cats.data.OptionT
import cats.effect.{Effect, Resource}
import cats.implicits._
import fs2.Stream

import docspell.backend.ops.OItemSearch._
import docspell.common._
import docspell.store.queries.{QAttachment, QItem}
import docspell.store.records._
import docspell.store._

import bitpeace.{FileMeta, RangeDef}
import doobie.implicits._

trait OItemSearch[F[_]] {
  def findItem(id: Ident, collective: Ident): F[Option[ItemData]]

  def findItems(maxNoteLen: Int)(q: Query, batch: Batch): F[Vector[ListItem]]

  /** Same as `findItems` but does more queries per item to find all tags. */
  def findItemsWithTags(
      maxNoteLen: Int
  )(q: Query, batch: Batch): F[Vector[ListItemWithTags]]

  def findAttachment(id: Ident, collective: Ident): F[Option[AttachmentData[F]]]

  def findAttachmentSource(
      id: Ident,
      collective: Ident
  ): F[Option[AttachmentSourceData[F]]]

  def findAttachmentArchive(
      id: Ident,
      collective: Ident
  ): F[Option[AttachmentArchiveData[F]]]

  def findAttachmentPreview(
      id: Ident,
      collective: Ident
  ): F[Option[AttachmentPreviewData[F]]]

  def findItemPreview(item: Ident, collective: Ident): F[Option[AttachmentPreviewData[F]]]

  def findAttachmentMeta(id: Ident, collective: Ident): F[Option[RAttachmentMeta]]

  def findByFileCollective(checksum: String, collective: Ident): F[Vector[RItem]]

  def findByFileSource(checksum: String, sourceId: Ident): F[Vector[RItem]]

}

object OItemSearch {

  type CustomValue = queries.CustomValue
  val CustomValue = queries.CustomValue

  type Query = queries.Query
  val Query = queries.Query

  type Batch = qb.Batch
  val Batch = docspell.store.qb.Batch

  type ListItem = queries.ListItem
  val ListItem = queries.ListItem

  type ListItemWithTags = queries.ListItemWithTags
  val ListItemWithTags = queries.ListItemWithTags

  type ItemFieldValue = queries.ItemFieldValue
  val ItemFieldValue = queries.ItemFieldValue

  type ItemData = queries.ItemData
  val ItemData = queries.ItemData

  trait BinaryData[F[_]] {
    def data: Stream[F, Byte]
    def name: Option[String]
    def meta: FileMeta
    def fileId: Ident
  }
  case class AttachmentData[F[_]](ra: RAttachment, meta: FileMeta, data: Stream[F, Byte])
      extends BinaryData[F] {
    val name   = ra.name
    val fileId = ra.fileId
  }

  case class AttachmentSourceData[F[_]](
      rs: RAttachmentSource,
      meta: FileMeta,
      data: Stream[F, Byte]
  ) extends BinaryData[F] {
    val name   = rs.name
    val fileId = rs.fileId
  }

  case class AttachmentPreviewData[F[_]](
      rs: RAttachmentPreview,
      meta: FileMeta,
      data: Stream[F, Byte]
  ) extends BinaryData[F] {
    val name   = rs.name
    val fileId = rs.fileId
  }

  case class AttachmentArchiveData[F[_]](
      rs: RAttachmentArchive,
      meta: FileMeta,
      data: Stream[F, Byte]
  ) extends BinaryData[F] {
    val name   = rs.name
    val fileId = rs.fileId
  }

  def apply[F[_]: Effect](store: Store[F]): Resource[F, OItemSearch[F]] =
    Resource.pure[F, OItemSearch[F]](new OItemSearch[F] {

      def findItem(id: Ident, collective: Ident): F[Option[ItemData]] =
        store
          .transact(QItem.findItem(id))
          .map(opt => opt.flatMap(_.filterCollective(collective)))

      def findItems(maxNoteLen: Int)(q: Query, batch: Batch): F[Vector[ListItem]] =
        store
          .transact(QItem.findItems(q, maxNoteLen, batch).take(batch.limit.toLong))
          .compile
          .toVector

      def findItemsWithTags(
          maxNoteLen: Int
      )(q: Query, batch: Batch): F[Vector[ListItemWithTags]] = {
        val search = QItem.findItems(q, maxNoteLen: Int, batch)
        store
          .transact(
            QItem.findItemsWithTags(q.account.collective, search).take(batch.limit.toLong)
          )
          .compile
          .toVector
      }

      def findAttachment(id: Ident, collective: Ident): F[Option[AttachmentData[F]]] =
        store
          .transact(RAttachment.findByIdAndCollective(id, collective))
          .flatMap({
            case Some(ra) =>
              makeBinaryData(ra.fileId) { m =>
                AttachmentData[F](
                  ra,
                  m,
                  store.bitpeace.fetchData2(RangeDef.all)(Stream.emit(m))
                )
              }

            case None =>
              (None: Option[AttachmentData[F]]).pure[F]
          })

      def findAttachmentSource(
          id: Ident,
          collective: Ident
      ): F[Option[AttachmentSourceData[F]]] =
        store
          .transact(RAttachmentSource.findByIdAndCollective(id, collective))
          .flatMap({
            case Some(ra) =>
              makeBinaryData(ra.fileId) { m =>
                AttachmentSourceData[F](
                  ra,
                  m,
                  store.bitpeace.fetchData2(RangeDef.all)(Stream.emit(m))
                )
              }

            case None =>
              (None: Option[AttachmentSourceData[F]]).pure[F]
          })

      def findAttachmentPreview(
          id: Ident,
          collective: Ident
      ): F[Option[AttachmentPreviewData[F]]] =
        store
          .transact(RAttachmentPreview.findByIdAndCollective(id, collective))
          .flatMap({
            case Some(ra) =>
              makeBinaryData(ra.fileId) { m =>
                AttachmentPreviewData[F](
                  ra,
                  m,
                  store.bitpeace.fetchData2(RangeDef.all)(Stream.emit(m))
                )
              }

            case None =>
              (None: Option[AttachmentPreviewData[F]]).pure[F]
          })

      def findItemPreview(
          item: Ident,
          collective: Ident
      ): F[Option[AttachmentPreviewData[F]]] =
        store
          .transact(RAttachmentPreview.findByItemAndCollective(item, collective))
          .flatMap({
            case Some(ra) =>
              makeBinaryData(ra.fileId) { m =>
                AttachmentPreviewData[F](
                  ra,
                  m,
                  store.bitpeace.fetchData2(RangeDef.all)(Stream.emit(m))
                )
              }

            case None =>
              (None: Option[AttachmentPreviewData[F]]).pure[F]
          })

      def findAttachmentArchive(
          id: Ident,
          collective: Ident
      ): F[Option[AttachmentArchiveData[F]]] =
        store
          .transact(RAttachmentArchive.findByIdAndCollective(id, collective))
          .flatMap({
            case Some(ra) =>
              makeBinaryData(ra.fileId) { m =>
                AttachmentArchiveData[F](
                  ra,
                  m,
                  store.bitpeace.fetchData2(RangeDef.all)(Stream.emit(m))
                )
              }

            case None =>
              (None: Option[AttachmentArchiveData[F]]).pure[F]
          })

      private def makeBinaryData[A](fileId: Ident)(f: FileMeta => A): F[Option[A]] =
        store.bitpeace
          .get(fileId.id)
          .unNoneTerminate
          .compile
          .last
          .map(
            _.map(m => f(m))
          )

      def findAttachmentMeta(id: Ident, collective: Ident): F[Option[RAttachmentMeta]] =
        store.transact(QAttachment.getAttachmentMeta(id, collective))

      def findByFileCollective(checksum: String, collective: Ident): F[Vector[RItem]] =
        store.transact(QItem.findByChecksum(checksum, collective))

      def findByFileSource(checksum: String, sourceId: Ident): F[Vector[RItem]] =
        store.transact((for {
          coll  <- OptionT(RSource.findCollective(sourceId))
          items <- OptionT.liftF(QItem.findByChecksum(checksum, coll))
        } yield items).getOrElse(Vector.empty))

    })
}
