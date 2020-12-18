package docspell.backend.ops

import cats.data.NonEmptyList
import cats.data.OptionT
import cats.effect.{Effect, Resource}
import cats.implicits._

import docspell.backend.JobFactory
import docspell.common._
import docspell.ftsclient.FtsClient
import docspell.store.UpdateResult
import docspell.store.queries.{QAttachment, QItem, QMoveAttachment}
import docspell.store.queue.JobQueue
import docspell.store.records._
import docspell.store.{AddResult, Store}

import doobie.implicits._
import org.log4s.getLogger

trait OItem[F[_]] {

  /** Sets the given tags (removing all existing ones). */
  def setTags(item: Ident, tagIds: List[Ident], collective: Ident): F[UpdateResult]

  /** Sets tags for multiple items. The tags of the items will be
    * replaced with the given ones. Same as `setTags` but for multiple
    * items.
    */
  def setTagsMultipleItems(
      items: NonEmptyList[Ident],
      tags: List[Ident],
      collective: Ident
  ): F[UpdateResult]

  /** Create a new tag and add it to the item. */
  def addNewTag(item: Ident, tag: RTag): F[AddResult]

  /** Apply all tags to the given item. Tags must exist, but can be IDs
    * or names. Existing tags on the item are left unchanged.
    */
  def linkTags(item: Ident, tags: List[String], collective: Ident): F[UpdateResult]

  def linkTagsMultipleItems(
      items: NonEmptyList[Ident],
      tags: List[String],
      collective: Ident
  ): F[UpdateResult]

  def removeTagsMultipleItems(
      items: NonEmptyList[Ident],
      tags: List[String],
      collective: Ident
  ): F[UpdateResult]

  /** Toggles tags of the given item. Tags must exist, but can be IDs or names. */
  def toggleTags(item: Ident, tags: List[String], collective: Ident): F[UpdateResult]

  def setDirection(
      item: NonEmptyList[Ident],
      direction: Direction,
      collective: Ident
  ): F[UpdateResult]

  def setFolder(item: Ident, folder: Option[Ident], collective: Ident): F[UpdateResult]

  def setFolderMultiple(
      items: NonEmptyList[Ident],
      folder: Option[Ident],
      collective: Ident
  ): F[UpdateResult]

  def setCorrOrg(
      items: NonEmptyList[Ident],
      org: Option[Ident],
      collective: Ident
  ): F[UpdateResult]

  def addCorrOrg(item: Ident, org: OOrganization.OrgAndContacts): F[AddResult]

  def setCorrPerson(
      items: NonEmptyList[Ident],
      person: Option[Ident],
      collective: Ident
  ): F[UpdateResult]

  def addCorrPerson(item: Ident, person: OOrganization.PersonAndContacts): F[AddResult]

  def setConcPerson(
      items: NonEmptyList[Ident],
      person: Option[Ident],
      collective: Ident
  ): F[UpdateResult]

  def addConcPerson(item: Ident, person: OOrganization.PersonAndContacts): F[AddResult]

  def setConcEquip(
      items: NonEmptyList[Ident],
      equip: Option[Ident],
      collective: Ident
  ): F[UpdateResult]

  def addConcEquip(item: Ident, equip: REquipment): F[AddResult]

  def setNotes(item: Ident, notes: Option[String], collective: Ident): F[UpdateResult]

  def setName(item: Ident, name: String, collective: Ident): F[UpdateResult]

  def setNameMultiple(
      items: NonEmptyList[Ident],
      name: String,
      collective: Ident
  ): F[UpdateResult]

  def setState(item: Ident, state: ItemState, collective: Ident): F[AddResult] =
    setStates(NonEmptyList.of(item), state, collective)

  def setStates(
      item: NonEmptyList[Ident],
      state: ItemState,
      collective: Ident
  ): F[AddResult]

  def setItemDate(
      item: NonEmptyList[Ident],
      date: Option[Timestamp],
      collective: Ident
  ): F[UpdateResult]

  def setItemDueDate(
      item: NonEmptyList[Ident],
      date: Option[Timestamp],
      collective: Ident
  ): F[UpdateResult]

  def getProposals(item: Ident, collective: Ident): F[MetaProposalList]

  def deleteItem(itemId: Ident, collective: Ident): F[Int]

  def deleteItemMultiple(items: NonEmptyList[Ident], collective: Ident): F[Int]

  def deleteAttachment(id: Ident, collective: Ident): F[Int]

  def moveAttachmentBefore(itemId: Ident, source: Ident, target: Ident): F[AddResult]

  def setAttachmentName(
      attachId: Ident,
      name: Option[String],
      collective: Ident
  ): F[UpdateResult]

  /** Submits the item for re-processing. The list of attachment ids can
    * be used to only re-process a subset of the item's attachments.
    * If this list is empty, all attachments are reprocessed. This
    * call only submits the job into the queue.
    */
  def reprocess(
      item: Ident,
      attachments: List[Ident],
      account: AccountId,
      notifyJoex: Boolean
  ): F[UpdateResult]

  def reprocessAll(
      items: NonEmptyList[Ident],
      account: AccountId,
      notifyJoex: Boolean
  ): F[UpdateResult]

  /** Submits a task that finds all non-converted pdfs and triggers
    * converting them using ocrmypdf. Each file is converted by a
    * separate task.
    */
  def convertAllPdf(
      collective: Option[Ident],
      account: AccountId,
      notifyJoex: Boolean
  ): F[UpdateResult]

  /** Submits a task that (re)generates the preview image for an
    * attachment.
    */
  def generatePreview(
      args: MakePreviewArgs,
      account: AccountId,
      notifyJoex: Boolean
  ): F[UpdateResult]
}

object OItem {

  def apply[F[_]: Effect](
      store: Store[F],
      fts: FtsClient[F],
      queue: JobQueue[F],
      joex: OJoex[F]
  ): Resource[F, OItem[F]] =
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
            .transact(QMoveAttachment.moveAttachmentBefore(itemId, source, target))
            .attempt
            .map(AddResult.fromUpdate)

        def linkTags(
            item: Ident,
            tags: List[String],
            collective: Ident
        ): F[UpdateResult] =
          linkTagsMultipleItems(NonEmptyList.of(item), tags, collective)

        def linkTagsMultipleItems(
            items: NonEmptyList[Ident],
            tags: List[String],
            collective: Ident
        ): F[UpdateResult] =
          tags.distinct match {
            case Nil => UpdateResult.success.pure[F]
            case ws =>
              store.transact {
                (for {
                  itemIds <- OptionT
                    .liftF(RItem.filterItems(items, collective))
                    .filter(_.nonEmpty)
                  given <- OptionT.liftF(RTag.findAllByNameOrId(ws, collective))
                  _ <- OptionT.liftF(
                    itemIds.traverse(item =>
                      RTagItem.appendTags(item, given.map(_.tagId).toList)
                    )
                  )
                } yield UpdateResult.success).getOrElse(UpdateResult.notFound)
              }
          }

        def removeTagsMultipleItems(
            items: NonEmptyList[Ident],
            tags: List[String],
            collective: Ident
        ): F[UpdateResult] =
          tags.distinct match {
            case Nil => UpdateResult.success.pure[F]
            case ws =>
              store.transact {
                (for {
                  itemIds <- OptionT
                    .liftF(RItem.filterItems(items, collective))
                    .filter(_.nonEmpty)
                  given <- OptionT.liftF(RTag.findAllByNameOrId(ws, collective))
                  _ <- OptionT.liftF(
                    itemIds.traverse(item =>
                      RTagItem.removeAllTags(item, given.map(_.tagId).toList)
                    )
                  )
                } yield UpdateResult.success).getOrElse(UpdateResult.notFound)
              }
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

        def setTags(
            item: Ident,
            tagIds: List[Ident],
            collective: Ident
        ): F[UpdateResult] =
          setTagsMultipleItems(NonEmptyList.of(item), tagIds, collective)

        def setTagsMultipleItems(
            items: NonEmptyList[Ident],
            tags: List[Ident],
            collective: Ident
        ): F[UpdateResult] =
          UpdateResult.fromUpdate(store.transact(for {
            k   <- RTagItem.deleteItemTags(items, collective)
            res <- items.traverse(i => RTagItem.setAllTags(i, tags))
            n = res.fold
          } yield k + n))

        def addNewTag(item: Ident, tag: RTag): F[AddResult] =
          (for {
            _ <- OptionT(store.transact(RItem.getCollective(item)))
              .filter(_ == tag.collective)
            addres <- OptionT.liftF(otag.add(tag))
            _ <- addres match {
              case AddResult.Success =>
                OptionT.liftF(
                  store.transact(RTagItem.setAllTags(item, List(tag.tagId)))
                )
              case AddResult.EntityExists(_) =>
                OptionT.pure[F](0)
              case AddResult.Failure(_) =>
                OptionT.pure[F](0)
            }
          } yield addres)
            .getOrElse(AddResult.Failure(new Exception("Collective mismatch")))

        def setDirection(
            items: NonEmptyList[Ident],
            direction: Direction,
            collective: Ident
        ): F[UpdateResult] =
          UpdateResult.fromUpdate(
            store
              .transact(RItem.updateDirection(items, collective, direction))
          )

        def setFolder(
            item: Ident,
            folder: Option[Ident],
            collective: Ident
        ): F[UpdateResult] =
          UpdateResult
            .fromUpdate(
              store
                .transact(RItem.updateFolder(item, collective, folder))
            )
            .flatTap(
              onSuccessIgnoreError(fts.updateFolder(logger, item, collective, folder))
            )

        def setFolderMultiple(
            items: NonEmptyList[Ident],
            folder: Option[Ident],
            collective: Ident
        ): F[UpdateResult] =
          for {
            results <- items.traverse(i => setFolder(i, folder, collective))
            err <- results.traverse {
              case UpdateResult.NotFound =>
                logger.info("An item was not found when updating the folder") *> 0.pure[F]
              case UpdateResult.Failure(err) =>
                logger.error(err)("An item failed to update its folder") *> 1.pure[F]
              case UpdateResult.Success =>
                0.pure[F]
            }
            res =
              if (results.size == err.fold)
                UpdateResult.failure(new Exception("All items failed to update"))
              else UpdateResult.success
          } yield res

        def setCorrOrg(
            items: NonEmptyList[Ident],
            org: Option[Ident],
            collective: Ident
        ): F[UpdateResult] =
          UpdateResult.fromUpdate(
            store
              .transact(RItem.updateCorrOrg(items, collective, org))
          )

        def addCorrOrg(item: Ident, org: OOrganization.OrgAndContacts): F[AddResult] =
          (for {
            _ <- OptionT(store.transact(RItem.getCollective(item)))
              .filter(_ == org.org.cid)
            addres <- OptionT.liftF(oorg.addOrg(org))
            _ <- addres match {
              case AddResult.Success =>
                OptionT.liftF(
                  store.transact(
                    RItem.updateCorrOrg(
                      NonEmptyList.of(item),
                      org.org.cid,
                      Some(org.org.oid)
                    )
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
            items: NonEmptyList[Ident],
            person: Option[Ident],
            collective: Ident
        ): F[UpdateResult] =
          UpdateResult.fromUpdate(
            store
              .transact(RItem.updateCorrPerson(items, collective, person))
          )

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
                      .updateCorrPerson(
                        NonEmptyList.of(item),
                        person.person.cid,
                        Some(person.person.pid)
                      )
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
            items: NonEmptyList[Ident],
            person: Option[Ident],
            collective: Ident
        ): F[UpdateResult] =
          UpdateResult.fromUpdate(
            store
              .transact(RItem.updateConcPerson(items, collective, person))
          )

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
                      .updateConcPerson(
                        NonEmptyList.of(item),
                        person.person.cid,
                        Some(person.person.pid)
                      )
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
            items: NonEmptyList[Ident],
            equip: Option[Ident],
            collective: Ident
        ): F[UpdateResult] =
          UpdateResult.fromUpdate(
            store
              .transact(RItem.updateConcEquip(items, collective, equip))
          )

        def addConcEquip(item: Ident, equip: REquipment): F[AddResult] =
          (for {
            _ <- OptionT(store.transact(RItem.getCollective(item)))
              .filter(_ == equip.cid)
            addres <- OptionT.liftF(oequip.add(equip))
            _ <- addres match {
              case AddResult.Success =>
                OptionT.liftF(
                  store.transact(
                    RItem
                      .updateConcEquip(NonEmptyList.of(item), equip.cid, Some(equip.eid))
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
        ): F[UpdateResult] =
          UpdateResult
            .fromUpdate(
              store
                .transact(RItem.updateNotes(item, collective, notes))
            )
            .flatTap(
              onSuccessIgnoreError(fts.updateItemNotes(logger, item, collective, notes))
            )

        def setName(item: Ident, name: String, collective: Ident): F[UpdateResult] =
          UpdateResult
            .fromUpdate(
              store
                .transact(RItem.updateName(item, collective, name))
            )
            .flatTap(
              onSuccessIgnoreError(fts.updateItemName(logger, item, collective, name))
            )

        def setNameMultiple(
            items: NonEmptyList[Ident],
            name: String,
            collective: Ident
        ): F[UpdateResult] =
          for {
            results <- items.traverse(i => setName(i, name, collective))
            err <- results.traverse {
              case UpdateResult.NotFound =>
                logger.info("An item was not found when updating the name") *> 0.pure[F]
              case UpdateResult.Failure(err) =>
                logger.error(err)("An item failed to update its name") *> 1.pure[F]
              case UpdateResult.Success =>
                0.pure[F]
            }
            res =
              if (results.size == err.fold)
                UpdateResult.failure(new Exception("All items failed to update"))
              else UpdateResult.success
          } yield res

        def setStates(
            items: NonEmptyList[Ident],
            state: ItemState,
            collective: Ident
        ): F[AddResult] =
          store
            .transact(RItem.updateStateForCollective(items, state, collective))
            .attempt
            .map(AddResult.fromUpdate)

        def setItemDate(
            items: NonEmptyList[Ident],
            date: Option[Timestamp],
            collective: Ident
        ): F[UpdateResult] =
          UpdateResult.fromUpdate(
            store
              .transact(RItem.updateDate(items, collective, date))
          )

        def setItemDueDate(
            items: NonEmptyList[Ident],
            date: Option[Timestamp],
            collective: Ident
        ): F[UpdateResult] =
          UpdateResult.fromUpdate(
            store
              .transact(RItem.updateDueDate(items, collective, date))
          )

        def deleteItem(itemId: Ident, collective: Ident): F[Int] =
          QItem
            .delete(store)(itemId, collective)
            .flatTap(_ => fts.removeItem(logger, itemId))

        def deleteItemMultiple(items: NonEmptyList[Ident], collective: Ident): F[Int] =
          for {
            itemIds <- store.transact(RItem.filterItems(items, collective))
            results <- itemIds.traverse(item => deleteItem(item, collective))
            n = results.fold(0)(_ + _)
          } yield n

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
        ): F[UpdateResult] =
          UpdateResult
            .fromUpdate(
              store
                .transact(RAttachment.updateName(attachId, collective, name))
            )
            .flatTap(
              onSuccessIgnoreError(
                OptionT(store.transact(RAttachment.findItemId(attachId)))
                  .semiflatMap(itemId =>
                    fts.updateAttachmentName(logger, itemId, attachId, collective, name)
                  )
                  .fold(())(identity)
              )
            )

        def reprocess(
            item: Ident,
            attachments: List[Ident],
            account: AccountId,
            notifyJoex: Boolean
        ): F[UpdateResult] =
          (for {
            _ <- OptionT(
              store.transact(RItem.findByIdAndCollective(item, account.collective))
            )
            args = ReProcessItemArgs(item, attachments)
            job <- OptionT.liftF(
              JobFactory.reprocessItem[F](args, account, Priority.Low)
            )
            _ <- OptionT.liftF(queue.insertIfNew(job))
            _ <- OptionT.liftF(if (notifyJoex) joex.notifyAllNodes else ().pure[F])
          } yield UpdateResult.success).getOrElse(UpdateResult.notFound)

        def reprocessAll(
            items: NonEmptyList[Ident],
            account: AccountId,
            notifyJoex: Boolean
        ): F[UpdateResult] =
          UpdateResult.fromUpdate(for {
            items <- store.transact(RItem.filterItems(items, account.collective))
            jobs <- items
              .map(item => ReProcessItemArgs(item, Nil))
              .traverse(arg => JobFactory.reprocessItem[F](arg, account, Priority.Low))
            _ <- queue.insertAllIfNew(jobs)
            _ <- if (notifyJoex) joex.notifyAllNodes else ().pure[F]
          } yield items.size)

        def convertAllPdf(
            collective: Option[Ident],
            account: AccountId,
            notifyJoex: Boolean
        ): F[UpdateResult] =
          for {
            job <- JobFactory.convertAllPdfs[F](collective, account, Priority.Low)
            _   <- queue.insertIfNew(job)
            _   <- if (notifyJoex) joex.notifyAllNodes else ().pure[F]
          } yield UpdateResult.success

        def generatePreview(
            args: MakePreviewArgs,
            account: AccountId,
            notifyJoex: Boolean
        ): F[UpdateResult] =
          for {
            job <- JobFactory.makePreview[F](args, account.some)
            _   <- queue.insertIfNew(job)
            _   <- if (notifyJoex) joex.notifyAllNodes else ().pure[F]
          } yield UpdateResult.success

        private def onSuccessIgnoreError(update: F[Unit])(ar: UpdateResult): F[Unit] =
          ar match {
            case UpdateResult.Success =>
              update.attempt.flatMap {
                case Right(()) => ().pure[F]
                case Left(ex) =>
                  logger.warn(s"Error updating full-text index: ${ex.getMessage}")
              }
            case UpdateResult.Failure(_) =>
              ().pure[F]
            case UpdateResult.NotFound =>
              ().pure[F]
          }
      })
    } yield oitem
}
