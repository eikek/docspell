package docspell.backend.ops

import cats.data.OptionT
import cats.effect.{Effect, Resource}
import cats.implicits._

import docspell.common._
import docspell.ftsclient.FtsClient
import docspell.store.UpdateResult
import docspell.store.queries.{QAttachment, QItem}
import docspell.store.records._
import docspell.store.{AddResult, Store}

import doobie._
import doobie.implicits._
import org.log4s.getLogger

trait OItem[F[_]] {

  /** Sets the given tags (removing all existing ones). */
  def setTags(item: Ident, tagIds: List[Ident], collective: Ident): F[AddResult]

  /** Create a new tag and add it to the item. */
  def addNewTag(item: Ident, tag: RTag): F[AddResult]

  /** Apply all tags to the given item. Tags must exist, but can be IDs or names. */
  def linkTags(item: Ident, tags: List[String], collective: Ident): F[UpdateResult]

  /** Toggles tags of the given item. Tags must exist, but can be IDs or names. */
  def toggleTags(item: Ident, tags: List[String], collective: Ident): F[UpdateResult]

  def setDirection(item: Ident, direction: Direction, collective: Ident): F[AddResult]

  def setFolder(item: Ident, folder: Option[Ident], collective: Ident): F[AddResult]

  def setCorrOrg(item: Ident, org: Option[Ident], collective: Ident): F[AddResult]

  def addCorrOrg(item: Ident, org: OOrganization.OrgAndContacts): F[AddResult]

  def setCorrPerson(item: Ident, person: Option[Ident], collective: Ident): F[AddResult]

  def addCorrPerson(item: Ident, person: OOrganization.PersonAndContacts): F[AddResult]

  def setConcPerson(item: Ident, person: Option[Ident], collective: Ident): F[AddResult]

  def addConcPerson(item: Ident, person: OOrganization.PersonAndContacts): F[AddResult]

  def setConcEquip(item: Ident, equip: Option[Ident], collective: Ident): F[AddResult]

  def addConcEquip(item: Ident, equip: REquipment): F[AddResult]

  def setNotes(item: Ident, notes: Option[String], collective: Ident): F[AddResult]

  def setName(item: Ident, name: String, collective: Ident): F[AddResult]

  def setState(item: Ident, state: ItemState, collective: Ident): F[AddResult]

  def setItemDate(item: Ident, date: Option[Timestamp], collective: Ident): F[AddResult]

  def setItemDueDate(
      item: Ident,
      date: Option[Timestamp],
      collective: Ident
  ): F[AddResult]

  def getProposals(item: Ident, collective: Ident): F[MetaProposalList]

  def deleteItem(itemId: Ident, collective: Ident): F[Int]

  def deleteAttachment(id: Ident, collective: Ident): F[Int]

  def moveAttachmentBefore(itemId: Ident, source: Ident, target: Ident): F[AddResult]

  def setAttachmentName(
      attachId: Ident,
      name: Option[String],
      collective: Ident
  ): F[AddResult]
}

object OItem {

  def apply[F[_]: Effect](store: Store[F], fts: FtsClient[F]): Resource[F, OItem[F]] =
    for {
      otag   <- OTag(store)
      oorg   <- OOrganization(store)
      oequip <- OEquipment(store)
      logger <- Resource.pure[F, Logger[F]](Logger.log4s(getLogger))
      oitem <- Resource.pure[F, OItem[F]](new OItem[F] {
        def moveAttachmentBefore(
            itemId: Ident,
            source: Ident,
            target: Ident
        ): F[AddResult] =
          store
            .transact(QItem.moveAttachmentBefore(itemId, source, target))
            .attempt
            .map(AddResult.fromUpdate)

        def linkTags(
            item: Ident,
            tags: List[String],
            collective: Ident
        ): F[UpdateResult] =
          tags.distinct match {
            case Nil => UpdateResult.success.pure[F]
            case kws =>
              val db =
                (for {
                  _     <- OptionT(RItem.checkByIdAndCollective(item, collective))
                  given <- OptionT.liftF(RTag.findAllByNameOrId(kws, collective))
                  exist <- OptionT.liftF(RTagItem.findAllIn(item, given.map(_.tagId)))
                  _ <- OptionT.liftF(
                    RTagItem.setAllTags(item, given.map(_.tagId).diff(exist.map(_.tagId)))
                  )
                } yield UpdateResult.success).getOrElse(UpdateResult.notFound)

              store.transact(db)
          }

        def toggleTags(
            item: Ident,
            tags: List[String],
            collective: Ident
        ): F[UpdateResult] =
          tags.distinct match {
            case Nil => UpdateResult.success.pure[F]
            case kws =>
              val db =
                (for {
                  _     <- OptionT(RItem.checkByIdAndCollective(item, collective))
                  given <- OptionT.liftF(RTag.findAllByNameOrId(kws, collective))
                  exist <- OptionT.liftF(RTagItem.findAllIn(item, given.map(_.tagId)))
                  remove = given.map(_.tagId).toSet.intersect(exist.map(_.tagId).toSet)
                  toadd  = given.map(_.tagId).diff(exist.map(_.tagId))
                  _ <- OptionT.liftF(RTagItem.setAllTags(item, toadd))
                  _ <- OptionT.liftF(RTagItem.removeAllTags(item, remove.toSeq))
                } yield UpdateResult.success).getOrElse(UpdateResult.notFound)

              store.transact(db)
          }

        def setTags(item: Ident, tagIds: List[Ident], collective: Ident): F[AddResult] = {
          val db = for {
            cid <- RItem.getCollective(item)
            nd <-
              if (cid.contains(collective)) RTagItem.deleteItemTags(item)
              else 0.pure[ConnectionIO]
            ni <-
              if (tagIds.nonEmpty && cid.contains(collective))
                RTagItem.insertItemTags(item, tagIds)
              else 0.pure[ConnectionIO]
          } yield nd + ni

          store.transact(db).attempt.map(AddResult.fromUpdate)
        }

        def addNewTag(item: Ident, tag: RTag): F[AddResult] =
          (for {
            _ <- OptionT(store.transact(RItem.getCollective(item)))
              .filter(_ == tag.collective)
            addres <- OptionT.liftF(otag.add(tag))
            _ <- addres match {
              case AddResult.Success =>
                OptionT.liftF(
                  store.transact(RTagItem.insertItemTags(item, List(tag.tagId)))
                )
              case AddResult.EntityExists(_) =>
                OptionT.pure[F](0)
              case AddResult.Failure(_) =>
                OptionT.pure[F](0)
            }
          } yield addres)
            .getOrElse(AddResult.Failure(new Exception("Collective mismatch")))

        def setDirection(
            item: Ident,
            direction: Direction,
            collective: Ident
        ): F[AddResult] =
          store
            .transact(RItem.updateDirection(item, collective, direction))
            .attempt
            .map(AddResult.fromUpdate)

        def setFolder(
            item: Ident,
            folder: Option[Ident],
            collective: Ident
        ): F[AddResult] =
          store
            .transact(RItem.updateFolder(item, collective, folder))
            .attempt
            .map(AddResult.fromUpdate)
            .flatTap(
              onSuccessIgnoreError(fts.updateFolder(logger, item, collective, folder))
            )

        def setCorrOrg(item: Ident, org: Option[Ident], collective: Ident): F[AddResult] =
          store
            .transact(RItem.updateCorrOrg(item, collective, org))
            .attempt
            .map(AddResult.fromUpdate)

        def addCorrOrg(item: Ident, org: OOrganization.OrgAndContacts): F[AddResult] =
          (for {
            _ <- OptionT(store.transact(RItem.getCollective(item)))
              .filter(_ == org.org.cid)
            addres <- OptionT.liftF(oorg.addOrg(org))
            _ <- addres match {
              case AddResult.Success =>
                OptionT.liftF(
                  store.transact(
                    RItem.updateCorrOrg(item, org.org.cid, Some(org.org.oid))
                  )
                )
              case AddResult.EntityExists(_) =>
                OptionT.pure[F](0)
              case AddResult.Failure(_) =>
                OptionT.pure[F](0)
            }
          } yield addres)
            .getOrElse(AddResult.Failure(new Exception("Collective mismatch")))

        def setCorrPerson(
            item: Ident,
            person: Option[Ident],
            collective: Ident
        ): F[AddResult] =
          store
            .transact(RItem.updateCorrPerson(item, collective, person))
            .attempt
            .map(AddResult.fromUpdate)

        def addCorrPerson(
            item: Ident,
            person: OOrganization.PersonAndContacts
        ): F[AddResult] =
          (for {
            _ <- OptionT(store.transact(RItem.getCollective(item)))
              .filter(_ == person.person.cid)
            addres <- OptionT.liftF(oorg.addPerson(person))
            _ <- addres match {
              case AddResult.Success =>
                OptionT.liftF(
                  store.transact(
                    RItem
                      .updateCorrPerson(item, person.person.cid, Some(person.person.pid))
                  )
                )
              case AddResult.EntityExists(_) =>
                OptionT.pure[F](0)
              case AddResult.Failure(_) =>
                OptionT.pure[F](0)
            }
          } yield addres)
            .getOrElse(AddResult.Failure(new Exception("Collective mismatch")))

        def setConcPerson(
            item: Ident,
            person: Option[Ident],
            collective: Ident
        ): F[AddResult] =
          store
            .transact(RItem.updateConcPerson(item, collective, person))
            .attempt
            .map(AddResult.fromUpdate)

        def addConcPerson(
            item: Ident,
            person: OOrganization.PersonAndContacts
        ): F[AddResult] =
          (for {
            _ <- OptionT(store.transact(RItem.getCollective(item)))
              .filter(_ == person.person.cid)
            addres <- OptionT.liftF(oorg.addPerson(person))
            _ <- addres match {
              case AddResult.Success =>
                OptionT.liftF(
                  store.transact(
                    RItem
                      .updateConcPerson(item, person.person.cid, Some(person.person.pid))
                  )
                )
              case AddResult.EntityExists(_) =>
                OptionT.pure[F](0)
              case AddResult.Failure(_) =>
                OptionT.pure[F](0)
            }
          } yield addres)
            .getOrElse(AddResult.Failure(new Exception("Collective mismatch")))

        def setConcEquip(
            item: Ident,
            equip: Option[Ident],
            collective: Ident
        ): F[AddResult] =
          store
            .transact(RItem.updateConcEquip(item, collective, equip))
            .attempt
            .map(AddResult.fromUpdate)

        def addConcEquip(item: Ident, equip: REquipment): F[AddResult] =
          (for {
            _ <- OptionT(store.transact(RItem.getCollective(item)))
              .filter(_ == equip.cid)
            addres <- OptionT.liftF(oequip.add(equip))
            _ <- addres match {
              case AddResult.Success =>
                OptionT.liftF(
                  store.transact(
                    RItem.updateConcEquip(item, equip.cid, Some(equip.eid))
                  )
                )
              case AddResult.EntityExists(_) =>
                OptionT.pure[F](0)
              case AddResult.Failure(_) =>
                OptionT.pure[F](0)
            }
          } yield addres)
            .getOrElse(AddResult.Failure(new Exception("Collective mismatch")))

        def setNotes(
            item: Ident,
            notes: Option[String],
            collective: Ident
        ): F[AddResult] =
          store
            .transact(RItem.updateNotes(item, collective, notes))
            .attempt
            .map(AddResult.fromUpdate)
            .flatTap(
              onSuccessIgnoreError(fts.updateItemNotes(logger, item, collective, notes))
            )

        def setName(item: Ident, name: String, collective: Ident): F[AddResult] =
          store
            .transact(RItem.updateName(item, collective, name))
            .attempt
            .map(AddResult.fromUpdate)
            .flatTap(
              onSuccessIgnoreError(fts.updateItemName(logger, item, collective, name))
            )

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

        def deleteItem(itemId: Ident, collective: Ident): F[Int] =
          QItem
            .delete(store)(itemId, collective)
            .flatTap(_ => fts.removeItem(logger, itemId))

        def getProposals(item: Ident, collective: Ident): F[MetaProposalList] =
          store.transact(QAttachment.getMetaProposals(item, collective))

        def deleteAttachment(id: Ident, collective: Ident): F[Int] =
          QAttachment
            .deleteSingleAttachment(store)(id, collective)
            .flatTap(_ => fts.removeAttachment(logger, id))

        def setAttachmentName(
            attachId: Ident,
            name: Option[String],
            collective: Ident
        ): F[AddResult] =
          store
            .transact(RAttachment.updateName(attachId, collective, name))
            .attempt
            .map(AddResult.fromUpdate)
            .flatTap(
              onSuccessIgnoreError(
                OptionT(store.transact(RAttachment.findItemId(attachId)))
                  .semiflatMap(itemId =>
                    fts.updateAttachmentName(logger, itemId, attachId, collective, name)
                  )
                  .fold(())(identity)
              )
            )

        private def onSuccessIgnoreError(update: F[Unit])(ar: AddResult): F[Unit] =
          ar match {
            case AddResult.Success =>
              update.attempt.flatMap {
                case Right(()) => ().pure[F]
                case Left(ex) =>
                  logger.warn(s"Error updating full-text index: ${ex.getMessage}")
              }
            case AddResult.Failure(_) =>
              ().pure[F]
            case AddResult.EntityExists(_) =>
              ().pure[F]
          }
      })
    } yield oitem
}
