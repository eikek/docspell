/*
 * Copyright 2020 Eike K. & Contributors
 *
 * SPDX-License-Identifier: AGPL-3.0-or-later
 */

package docspell.backend

import cats.data.{NonEmptyList => Nel}
import cats.effect.Sync
import cats.syntax.all._
import docspell.backend.BackendCommands.EventContext
import docspell.backend.ops.OCustomFields.SetValue
import docspell.backend.ops._
import docspell.common.bc._
import docspell.common._

private[backend] class BackendCommands[F[_]: Sync](
    itemOps: OItem[F],
    attachOps: OAttachment[F],
    fieldOps: OCustomFields[F],
    notificationOps: ONotification[F],
    eventContext: Option[EventContext]
) extends BackendCommandRunner[F, Unit] {
  private[this] val logger = docspell.logging.getLogger[F]

  def run(collective: CollectiveId, cmd: BackendCommand): F[Unit] =
    doRun(collective, cmd).attempt.flatMap {
      case Right(_) => ().pure[F]
      case Left(ex) =>
        logger.error(ex)(s"Backend command $cmd failed for collective $collective.")
    }

  def doRun(collective: CollectiveId, cmd: BackendCommand): F[Unit] =
    cmd match {
      case BackendCommand.ItemUpdate(item, actions) =>
        actions.traverse_(a => runItemAction(collective, item, a))

      case BackendCommand.AttachmentUpdate(item, attach, actions) =>
        actions.traverse_(a => runAttachAction(collective, item, attach, a))
    }

  def runAll(collective: CollectiveId, cmds: List[BackendCommand]): F[Unit] =
    cmds.traverse_(run(collective, _))

  def runItemAction(collective: CollectiveId, item: Ident, action: ItemAction): F[Unit] =
    action match {
      case ItemAction.AddTags(tags) =>
        logger.debug(s"Setting tags $tags on ${item.id} for ${collective.value}") *>
          itemOps
            .linkTags(item, tags.toList, collective)
            .flatMap(sendEvents)

      case ItemAction.RemoveTags(tags) =>
        logger.debug(s"Remove tags $tags on ${item.id} for ${collective.value}") *>
          itemOps
            .removeTagsMultipleItems(Nel.of(item), tags.toList, collective)
            .flatMap(sendEvents)

      case ItemAction.ReplaceTags(tags) =>
        logger.debug(s"Replace tags $tags on ${item.id} for $collective") *>
          itemOps
            .setTags(item, tags.toList, collective)
            .flatMap(sendEvents)

      case ItemAction.SetFolder(folder) =>
        logger.debug(s"Set folder $folder on ${item.id} for $collective") *>
          itemOps
            .setFolder(item, folder, collective)
            .void

      case ItemAction.RemoveTagsCategory(cats) =>
        logger.debug(
          s"Remove tags in categories $cats on ${item.id} for $collective"
        ) *>
          itemOps
            .removeTagsOfCategories(item, collective, cats)
            .flatMap(sendEvents)

      case ItemAction.SetCorrOrg(id) =>
        logger.debug(
          s"Set correspondent organization ${id.map(_.id)} for $collective"
        ) *>
          itemOps.setCorrOrg(Nel.of(item), id, collective).void

      case ItemAction.SetCorrPerson(id) =>
        logger.debug(
          s"Set correspondent person ${id.map(_.id)} for $collective"
        ) *>
          itemOps.setCorrPerson(Nel.of(item), id, collective).void

      case ItemAction.SetConcPerson(id) =>
        logger.debug(
          s"Set concerning person ${id.map(_.id)} for $collective"
        ) *>
          itemOps.setConcPerson(Nel.of(item), id, collective).void

      case ItemAction.SetConcEquipment(id) =>
        logger.debug(
          s"Set concerning equipment ${id.map(_.id)} for $collective"
        ) *>
          itemOps.setConcEquip(Nel.of(item), id, collective).void

      case ItemAction.SetField(field, value) =>
        logger.debug(
          s"Set field on item ${item.id} ${field.id} to '$value' for $collective"
        ) *>
          fieldOps
            .setValue(item, SetValue(field, value, collective))
            .flatMap(sendEvents)

      case ItemAction.SetNotes(notes) =>
        logger.debug(s"Set notes on item ${item.id} for $collective") *>
          itemOps.setNotes(item, notes, collective).void

      case ItemAction.AddNotes(notes, sep) =>
        logger.debug(s"Add notes on item ${item.id} for $collective") *>
          itemOps.addNotes(item, notes, sep, collective).void

      case ItemAction.SetName(name) =>
        logger.debug(s"Set name '$name' on item ${item.id} for $collective") *>
          itemOps.setName(item, name, collective).void
    }

  def runAttachAction(
      collective: CollectiveId,
      itemId: Ident,
      attachId: Ident,
      action: AttachmentAction
  ): F[Unit] =
    action match {
      case AttachmentAction.SetExtractedText(text) =>
        attachOps.setExtractedText(
          collective,
          itemId,
          attachId,
          text.getOrElse("").pure[F]
        )
    }

  private def sendEvents(result: AttachedEvent[_]): F[Unit] =
    eventContext match {
      case Some(ctx) =>
        notificationOps.offerEvents(result.event(ctx.account, ctx.baseUrl))
      case None => ().pure[F]
    }
}

object BackendCommands {

  /** If supplied, notification events will be send. */
  case class EventContext(account: AccountInfo, baseUrl: Option[LenientUri])

  def fromBackend[F[_]: Sync](
      backendApp: BackendApp[F],
      eventContext: Option[EventContext] = None
  ): BackendCommandRunner[F, Unit] =
    new BackendCommands[F](
      backendApp.item,
      backendApp.attachment,
      backendApp.customFields,
      backendApp.notification,
      eventContext
    )

  def apply[F[_]: Sync](
      item: OItem[F],
      attachment: OAttachment[F],
      fields: OCustomFields[F],
      notification: ONotification[F],
      eventContext: Option[EventContext] = None
  ): BackendCommandRunner[F, Unit] =
    new BackendCommands[F](item, attachment, fields, notification, eventContext)
}
