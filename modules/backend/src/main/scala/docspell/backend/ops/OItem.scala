/*
 * Copyright 2020 Eike K. & Contributors
 *
 * SPDX-License-Identifier: AGPL-3.0-or-later
 */

package docspell.backend.ops

import cats.data.{NonEmptyList => Nel, OptionT}
import cats.effect.{Async, Resource}
import cats.implicits._
import docspell.backend.AttachedEvent
import docspell.backend.JobFactory
import docspell.backend.fulltext.CreateIndex
import docspell.backend.item.Merge
import docspell.common._
import docspell.ftsclient.FtsClient
import docspell.logging.Logger
import docspell.notification.api.Event
import docspell.scheduler.JobStore
import docspell.store.queries.{QAttachment, QItem, QMoveAttachment}
import docspell.store.records._
import docspell.store.{AddResult, Store, UpdateResult}
import doobie.implicits._

trait OItem[F[_]] {

  /** Sets the given tags (removing all existing ones). */
  def setTags(
      item: Ident,
      tagIds: List[String],
      collective: Ident
  ): F[AttachedEvent[UpdateResult]]

  /** Sets tags for multiple items. The tags of the items will be replaced with the given
    * ones. Same as `setTags` but for multiple items.
    */
  def setTagsMultipleItems(
      items: Nel[Ident],
      tags: List[String],
      collective: Ident
  ): F[AttachedEvent[UpdateResult]]

  /** Create a new tag and add it to the item. */
  def addNewTag(collective: Ident, item: Ident, tag: RTag): F[AttachedEvent[AddResult]]

  /** Apply all tags to the given item. Tags must exist, but can be IDs or names. Existing
    * tags on the item are left unchanged.
    */
  def linkTags(
      item: Ident,
      tags: List[String],
      collective: Ident
  ): F[AttachedEvent[UpdateResult]]

  def linkTagsMultipleItems(
      items: Nel[Ident],
      tags: List[String],
      collective: Ident
  ): F[AttachedEvent[UpdateResult]]

  def removeTagsMultipleItems(
      items: Nel[Ident],
      tags: List[String],
      collective: Ident
  ): F[AttachedEvent[UpdateResult]]

  /** Toggles tags of the given item. Tags must exist, but can be IDs or names. */
  def toggleTags(
      item: Ident,
      tags: List[String],
      collective: Ident
  ): F[AttachedEvent[UpdateResult]]

  def setDirection(
      item: Nel[Ident],
      direction: Direction,
      collective: Ident
  ): F[UpdateResult]

  def setFolder(item: Ident, folder: Option[Ident], collective: Ident): F[UpdateResult]

  def setFolderMultiple(
      items: Nel[Ident],
      folder: Option[Ident],
      collective: Ident
  ): F[UpdateResult]

  def setCorrOrg(
      items: Nel[Ident],
      org: Option[Ident],
      collective: Ident
  ): F[UpdateResult]

  def addCorrOrg(item: Ident, org: OOrganization.OrgAndContacts): F[AddResult]

  def setCorrPerson(
      items: Nel[Ident],
      person: Option[Ident],
      collective: Ident
  ): F[UpdateResult]

  def addCorrPerson(item: Ident, person: OOrganization.PersonAndContacts): F[AddResult]

  def setConcPerson(
      items: Nel[Ident],
      person: Option[Ident],
      collective: Ident
  ): F[UpdateResult]

  def addConcPerson(item: Ident, person: OOrganization.PersonAndContacts): F[AddResult]

  def setConcEquip(
      items: Nel[Ident],
      equip: Option[Ident],
      collective: Ident
  ): F[UpdateResult]

  def addConcEquip(item: Ident, equip: REquipment): F[AddResult]

  def setNotes(item: Ident, notes: Option[String], collective: Ident): F[UpdateResult]

  def setName(item: Ident, name: String, collective: Ident): F[UpdateResult]

  def setNameMultiple(
      items: Nel[Ident],
      name: String,
      collective: Ident
  ): F[UpdateResult]

  def setState(item: Ident, state: ItemState, collective: Ident): F[AddResult] =
    setStates(Nel.of(item), state, collective)

  def setStates(
      item: Nel[Ident],
      state: ItemState,
      collective: Ident
  ): F[AddResult]

  def restore(items: Nel[Ident], collective: Ident): F[UpdateResult]

  def setItemDate(
      item: Nel[Ident],
      date: Option[Timestamp],
      collective: Ident
  ): F[UpdateResult]

  def setItemDueDate(
      item: Nel[Ident],
      date: Option[Timestamp],
      collective: Ident
  ): F[UpdateResult]

  def getProposals(item: Ident, collective: Ident): F[MetaProposalList]

  def deleteItem(itemId: Ident, collective: Ident): F[Int]

  def deleteItemMultiple(items: Nel[Ident], collective: Ident): F[Int]

  def deleteAttachment(id: Ident, collective: Ident): F[Int]

  def setDeletedState(items: Nel[Ident], collective: Ident): F[Int]

  def deleteAttachmentMultiple(
      attachments: Nel[Ident],
      collective: Ident
  ): F[Int]

  def moveAttachmentBefore(itemId: Ident, source: Ident, target: Ident): F[AddResult]

  def setAttachmentName(
      attachId: Ident,
      name: Option[String],
      collective: Ident
  ): F[UpdateResult]

  /** Submits the item for re-processing. The list of attachment ids can be used to only
    * re-process a subset of the item's attachments. If this list is empty, all
    * attachments are reprocessed. This call only submits the job into the queue.
    */
  def reprocess(
      item: Ident,
      attachments: List[Ident],
      account: AccountId,
      notifyJoex: Boolean
  ): F[UpdateResult]

  def reprocessAll(
      items: Nel[Ident],
      account: AccountId,
      notifyJoex: Boolean
  ): F[UpdateResult]

  /** Submits a task that finds all non-converted pdfs and triggers converting them using
    * ocrmypdf. Each file is converted by a separate task.
    */
  def convertAllPdf(
      collective: Option[Ident],
      submitter: Option[Ident],
      notifyJoex: Boolean
  ): F[UpdateResult]

  /** Submits a task that (re)generates the preview image for an attachment. */
  def generatePreview(
      args: MakePreviewArgs,
      account: AccountId,
      notifyJoex: Boolean
  ): F[UpdateResult]

  /** Submits a task that (re)generates the preview images for all attachments. */
  def generateAllPreviews(
      storeMode: MakePreviewArgs.StoreMode,
      notifyJoex: Boolean
  ): F[UpdateResult]

  /** Merges a list of items into one item. The remaining items are deleted. */
  def merge(
      logger: Logger[F],
      items: Nel[Ident],
      collective: Ident
  ): F[UpdateResult]
}

object OItem {
  def apply[F[_]: Async](
      store: Store[F],
      fts: FtsClient[F],
      createIndex: CreateIndex[F],
      jobStore: JobStore[F],
      joex: OJoex[F]
  ): Resource[F, OItem[F]] =
    for {
      otag <- OTag(store)
      oorg <- OOrganization(store)
      oequip <- OEquipment(store)
      logger <- Resource.pure[F, Logger[F]](docspell.logging.getLogger[F])
      oitem <- Resource.pure[F, OItem[F]](new OItem[F] {

        def merge(
            logger: Logger[F],
            items: Nel[Ident],
            collective: Ident
        ): F[UpdateResult] =
          Merge(logger, store, this, createIndex).merge(items, collective).attempt.map {
            case Right(Right(_))                  => UpdateResult.success
            case Right(Left(Merge.Error.NoItems)) => UpdateResult.NotFound
            case Left(ex)                         => UpdateResult.failure(ex)
          }

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
        ): F[AttachedEvent[UpdateResult]] =
          linkTagsMultipleItems(Nel.of(item), tags, collective)

        def linkTagsMultipleItems(
            items: Nel[Ident],
            tags: List[String],
            collective: Ident
        ): F[AttachedEvent[UpdateResult]] =
          tags.distinct match {
            case Nil => AttachedEvent.only(UpdateResult.success).pure[F]
            case ws =>
              store
                .transact {
                  (for {
                    itemIds <- OptionT
                      .liftF(RItem.filterItems(items, collective))
                      .subflatMap(l => Nel.fromFoldable(l))
                    given <- OptionT.liftF(RTag.findAllByNameOrId(ws, collective))
                    added <- OptionT.liftF(
                      itemIds.traverse(item =>
                        RTagItem.appendTags(item, given.map(_.tagId).toList)
                      )
                    )
                    ev = Event.TagsChanged.partial(
                      itemIds,
                      added.toList.flatten.map(_.id),
                      Nil
                    )
                  } yield AttachedEvent(UpdateResult.success)(ev))
                    .getOrElse(AttachedEvent.only(UpdateResult.notFound))
                }
          }

        def removeTagsMultipleItems(
            items: Nel[Ident],
            tags: List[String],
            collective: Ident
        ): F[AttachedEvent[UpdateResult]] =
          tags.distinct match {
            case Nil => AttachedEvent.only(UpdateResult.success).pure[F]
            case ws =>
              store.transact {
                (for {
                  itemIds <- OptionT
                    .liftF(RItem.filterItems(items, collective))
                    .subflatMap(l => Nel.fromFoldable(l))
                  given <- OptionT.liftF(RTag.findAllByNameOrId(ws, collective))
                  _ <- OptionT.liftF(
                    itemIds.traverse(item =>
                      RTagItem.removeAllTags(item, given.map(_.tagId).toList)
                    )
                  )
                  mkEvent = Event.TagsChanged
                    .partial(itemIds, Nil, given.map(_.tagId.id).toList)
                } yield AttachedEvent(UpdateResult.success)(mkEvent))
                  .getOrElse(AttachedEvent.only(UpdateResult.notFound))
              }
          }

        def toggleTags(
            item: Ident,
            tags: List[String],
            collective: Ident
        ): F[AttachedEvent[UpdateResult]] =
          tags.distinct match {
            case Nil => AttachedEvent.only(UpdateResult.success).pure[F]
            case kws =>
              val db =
                (for {
                  _ <- OptionT(RItem.checkByIdAndCollective(item, collective))
                  given <- OptionT.liftF(RTag.findAllByNameOrId(kws, collective))
                  exist <- OptionT.liftF(RTagItem.findAllIn(item, given.map(_.tagId)))
                  remove = given.map(_.tagId).toSet.intersect(exist.map(_.tagId).toSet)
                  toadd = given.map(_.tagId).diff(exist.map(_.tagId))
                  _ <- OptionT.liftF(RTagItem.setAllTags(item, toadd))
                  _ <- OptionT.liftF(RTagItem.removeAllTags(item, remove.toSeq))
                  mkEvent = Event.TagsChanged.partial(
                    Nel.of(item),
                    toadd.map(_.id).toList,
                    remove.map(_.id).toList
                  )

                } yield AttachedEvent(UpdateResult.success)(mkEvent))
                  .getOrElse(AttachedEvent.only(UpdateResult.notFound))

              store.transact(db)
          }

        def setTags(
            item: Ident,
            tagIds: List[String],
            collective: Ident
        ): F[AttachedEvent[UpdateResult]] =
          setTagsMultipleItems(Nel.of(item), tagIds, collective)

        def setTagsMultipleItems(
            items: Nel[Ident],
            tags: List[String],
            collective: Ident
        ): F[AttachedEvent[UpdateResult]] = {
          val dbTask =
            for {
              k <- RTagItem.deleteItemTags(items, collective)
              given <- RTag.findAllByNameOrId(tags, collective)
              res <- items.traverse(i => RTagItem.setAllTags(i, given.map(_.tagId)))
              n = res.fold
              mkEvent = Event.TagsChanged.partial(
                items,
                given.map(_.tagId.id).toList,
                Nil
              )
            } yield AttachedEvent(k + n)(mkEvent)

          for {
            data <- store.transact(dbTask)
          } yield data.map(UpdateResult.fromUpdateRows)
        }

        def addNewTag(
            collective: Ident,
            item: Ident,
            tag: RTag
        ): F[AttachedEvent[AddResult]] =
          (for {
            _ <- OptionT(store.transact(RItem.getCollective(item)))
              .filter(_ == tag.collective)
            addres <- OptionT.liftF(otag.add(tag))
            res <- addres match {
              case AddResult.Success =>
                OptionT.liftF(
                  store
                    .transact(RTagItem.setAllTags(item, List(tag.tagId)))
                    .map { _ =>
                      AttachedEvent(())(
                        Event.TagsChanged.partial(
                          Nel.of(item),
                          List(tag.tagId.id),
                          Nil
                        )
                      )
                    }
                )

              case AddResult.EntityExists(_) =>
                OptionT.pure[F](AttachedEvent.only(()))
              case AddResult.Failure(_) =>
                OptionT.pure[F](AttachedEvent.only(()))
            }
          } yield res.map(_ => addres))
            .getOrElse(
              AttachedEvent.only(AddResult.Failure(new Exception("Collective mismatch")))
            )

        def setDirection(
            items: Nel[Ident],
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
            items: Nel[Ident],
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
            items: Nel[Ident],
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
                      Nel.of(item),
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
            items: Nel[Ident],
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
                        Nel.of(item),
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
            items: Nel[Ident],
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
                        Nel.of(item),
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
            items: Nel[Ident],
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
                      .updateConcEquip(Nel.of(item), equip.cid, Some(equip.eid))
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
            items: Nel[Ident],
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
            items: Nel[Ident],
            state: ItemState,
            collective: Ident
        ): F[AddResult] =
          store
            .transact(RItem.updateStateForCollective(items, state, collective))
            .attempt
            .map(AddResult.fromUpdate)

        def restore(
            items: Nel[Ident],
            collective: Ident
        ): F[UpdateResult] =
          UpdateResult.fromUpdate(for {
            n <- store
              .transact(
                RItem.restoreStateForCollective(items, ItemState.Created, collective)
              )
            _ <- createIndex.reIndexData(logger, collective.some, items.some, 10)
          } yield n)

        def setItemDate(
            items: Nel[Ident],
            date: Option[Timestamp],
            collective: Ident
        ): F[UpdateResult] =
          UpdateResult.fromUpdate(
            store
              .transact(RItem.updateDate(items, collective, date))
          )

        def setItemDueDate(
            items: Nel[Ident],
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

        def deleteItemMultiple(items: Nel[Ident], collective: Ident): F[Int] =
          for {
            itemIds <- store.transact(RItem.filterItems(items, collective))
            results <- itemIds.traverse(item => deleteItem(item, collective))
            n = results.sum
          } yield n

        def setDeletedState(items: Nel[Ident], collective: Ident): F[Int] =
          for {
            n <- store.transact(RItem.setState(items, collective, ItemState.Deleted))
            _ <- items.traverse(id => fts.removeItem(logger, id))
          } yield n

        def getProposals(item: Ident, collective: Ident): F[MetaProposalList] =
          store.transact(QAttachment.getMetaProposals(item, collective))

        def deleteAttachment(id: Ident, collective: Ident): F[Int] =
          QAttachment
            .deleteSingleAttachment(store)(id, collective)
            .flatTap(_ => fts.removeAttachment(logger, id))

        def deleteAttachmentMultiple(
            attachments: Nel[Ident],
            collective: Ident
        ): F[Int] =
          for {
            attachmentIds <- store.transact(
              RAttachment.filterAttachments(attachments, collective)
            )
            results <- attachmentIds.traverse(attachment =>
              deleteAttachment(attachment, collective)
            )
            n = results.sum
          } yield n

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
            _ <- OptionT.liftF(jobStore.insertIfNew(job.encode))
            _ <- OptionT.liftF(if (notifyJoex) joex.notifyAllNodes else ().pure[F])
          } yield UpdateResult.success).getOrElse(UpdateResult.notFound)

        def reprocessAll(
            items: Nel[Ident],
            account: AccountId,
            notifyJoex: Boolean
        ): F[UpdateResult] =
          UpdateResult.fromUpdate(for {
            items <- store.transact(RItem.filterItems(items, account.collective))
            jobs <- items
              .map(item => ReProcessItemArgs(item, Nil))
              .traverse(arg => JobFactory.reprocessItem[F](arg, account, Priority.Low))
              .map(_.map(_.encode))
            _ <- jobStore.insertAllIfNew(jobs)
            _ <- if (notifyJoex) joex.notifyAllNodes else ().pure[F]
          } yield items.size)

        def convertAllPdf(
            collective: Option[Ident],
            submitter: Option[Ident],
            notifyJoex: Boolean
        ): F[UpdateResult] =
          for {
            job <- JobFactory.convertAllPdfs[F](collective, submitter, Priority.Low)
            _ <- jobStore.insertIfNew(job.encode)
            _ <- if (notifyJoex) joex.notifyAllNodes else ().pure[F]
          } yield UpdateResult.success

        def generatePreview(
            args: MakePreviewArgs,
            account: AccountId,
            notifyJoex: Boolean
        ): F[UpdateResult] =
          for {
            job <- JobFactory.makePreview[F](args, account.some)
            _ <- jobStore.insertIfNew(job.encode)
            _ <- if (notifyJoex) joex.notifyAllNodes else ().pure[F]
          } yield UpdateResult.success

        def generateAllPreviews(
            storeMode: MakePreviewArgs.StoreMode,
            notifyJoex: Boolean
        ): F[UpdateResult] =
          for {
            job <- JobFactory.allPreviews[F](AllPreviewsArgs(None, storeMode), None)
            _ <- jobStore.insertIfNew(job.encode)
            _ <- if (notifyJoex) joex.notifyAllNodes else ().pure[F]
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
