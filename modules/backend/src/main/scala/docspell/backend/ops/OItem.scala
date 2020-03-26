package docspell.backend.ops

import fs2.Stream
import cats.data.OptionT
import cats.implicits._
import cats.effect.{Effect, Resource}
import doobie._
import doobie.implicits._
import docspell.store.{AddResult, Store}
import docspell.store.queries.{QAttachment, QItem}
import OItem.{
  AttachmentArchiveData,
  AttachmentData,
  AttachmentSourceData,
  ItemData,
  ListItem,
  Query
}
import bitpeace.{FileMeta, RangeDef}
import docspell.common.{Direction, Ident, ItemState, MetaProposalList, Timestamp}
import docspell.store.records._

trait OItem[F[_]] {

  def findItem(id: Ident, collective: Ident): F[Option[ItemData]]

  def findItems(q: Query, maxResults: Int): F[Vector[ListItem]]

  def findAttachment(id: Ident, collective: Ident): F[Option[AttachmentData[F]]]

  def findAttachmentSource(
      id: Ident,
      collective: Ident
  ): F[Option[AttachmentSourceData[F]]]

  def findAttachmentArchive(
      id: Ident,
      collective: Ident
  ): F[Option[AttachmentArchiveData[F]]]

  def setTags(item: Ident, tagIds: List[Ident], collective: Ident): F[AddResult]

  def setDirection(item: Ident, direction: Direction, collective: Ident): F[AddResult]

  def setCorrOrg(item: Ident, org: Option[Ident], collective: Ident): F[AddResult]

  def setCorrPerson(item: Ident, person: Option[Ident], collective: Ident): F[AddResult]

  def setConcPerson(item: Ident, person: Option[Ident], collective: Ident): F[AddResult]

  def setConcEquip(item: Ident, equip: Option[Ident], collective: Ident): F[AddResult]

  def setNotes(item: Ident, notes: Option[String], collective: Ident): F[AddResult]

  def setName(item: Ident, notes: String, collective: Ident): F[AddResult]

  def setState(item: Ident, state: ItemState, collective: Ident): F[AddResult]

  def setItemDate(item: Ident, date: Option[Timestamp], collective: Ident): F[AddResult]

  def setItemDueDate(
      item: Ident,
      date: Option[Timestamp],
      collective: Ident
  ): F[AddResult]

  def getProposals(item: Ident, collective: Ident): F[MetaProposalList]

  def delete(itemId: Ident, collective: Ident): F[Int]

  def findAttachmentMeta(id: Ident, collective: Ident): F[Option[RAttachmentMeta]]

  def findByFileCollective(checksum: String, collective: Ident): F[Vector[RItem]]

  def findByFileSource(checksum: String, sourceId: Ident): F[Vector[RItem]]

}

object OItem {

  type Query = QItem.Query
  val Query = QItem.Query

  type ListItem = QItem.ListItem
  val ListItem = QItem.ListItem

  type ItemData = QItem.ItemData
  val ItemData = QItem.ItemData

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

  case class AttachmentArchiveData[F[_]](
      rs: RAttachmentArchive,
      meta: FileMeta,
      data: Stream[F, Byte]
  ) extends BinaryData[F] {
    val name   = rs.name
    val fileId = rs.fileId
  }

  def apply[F[_]: Effect](store: Store[F]): Resource[F, OItem[F]] =
    Resource.pure[F, OItem[F]](new OItem[F] {

      def findItem(id: Ident, collective: Ident): F[Option[ItemData]] =
        store
          .transact(QItem.findItem(id))
          .map(opt => opt.flatMap(_.filterCollective(collective)))

      def findItems(q: Query, maxResults: Int): F[Vector[ListItem]] =
        store.transact(QItem.findItems(q).take(maxResults.toLong)).compile.toVector

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

      def setTags(item: Ident, tagIds: List[Ident], collective: Ident): F[AddResult] = {
        val db = for {
          cid <- RItem.getCollective(item)
          nd <- if (cid.contains(collective)) RTagItem.deleteItemTags(item)
          else 0.pure[ConnectionIO]
          ni <- if (tagIds.nonEmpty && cid.contains(collective))
            RTagItem.insertItemTags(item, tagIds)
          else 0.pure[ConnectionIO]
        } yield nd + ni

        store.transact(db).attempt.map(AddResult.fromUpdate)
      }

      def setDirection(
          item: Ident,
          direction: Direction,
          collective: Ident
      ): F[AddResult] =
        store
          .transact(RItem.updateDirection(item, collective, direction))
          .attempt
          .map(AddResult.fromUpdate)

      def setCorrOrg(item: Ident, org: Option[Ident], collective: Ident): F[AddResult] =
        store
          .transact(RItem.updateCorrOrg(item, collective, org))
          .attempt
          .map(AddResult.fromUpdate)

      def setCorrPerson(
          item: Ident,
          person: Option[Ident],
          collective: Ident
      ): F[AddResult] =
        store
          .transact(RItem.updateCorrPerson(item, collective, person))
          .attempt
          .map(AddResult.fromUpdate)

      def setConcPerson(
          item: Ident,
          person: Option[Ident],
          collective: Ident
      ): F[AddResult] =
        store
          .transact(RItem.updateConcPerson(item, collective, person))
          .attempt
          .map(AddResult.fromUpdate)

      def setConcEquip(
          item: Ident,
          equip: Option[Ident],
          collective: Ident
      ): F[AddResult] =
        store
          .transact(RItem.updateConcEquip(item, collective, equip))
          .attempt
          .map(AddResult.fromUpdate)

      def setNotes(item: Ident, notes: Option[String], collective: Ident): F[AddResult] =
        store
          .transact(RItem.updateNotes(item, collective, notes))
          .attempt
          .map(AddResult.fromUpdate)

      def setName(item: Ident, name: String, collective: Ident): F[AddResult] =
        store
          .transact(RItem.updateName(item, collective, name))
          .attempt
          .map(AddResult.fromUpdate)

      def setState(item: Ident, state: ItemState, collective: Ident): F[AddResult] =
        store
          .transact(RItem.updateStateForCollective(item, state, collective))
          .attempt
          .map(AddResult.fromUpdate)

      def setItemDate(
          item: Ident,
          date: Option[Timestamp],
          collective: Ident
      ): F[AddResult] =
        store
          .transact(RItem.updateDate(item, collective, date))
          .attempt
          .map(AddResult.fromUpdate)

      def setItemDueDate(
          item: Ident,
          date: Option[Timestamp],
          collective: Ident
      ): F[AddResult] =
        store
          .transact(RItem.updateDueDate(item, collective, date))
          .attempt
          .map(AddResult.fromUpdate)

      def delete(itemId: Ident, collective: Ident): F[Int] =
        QItem.delete(store)(itemId, collective)

      def getProposals(item: Ident, collective: Ident): F[MetaProposalList] =
        store.transact(QAttachment.getMetaProposals(item, collective))

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
