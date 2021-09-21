/*
 * Copyright 2020 Eike K. & Contributors
 *
 * SPDX-License-Identifier: AGPL-3.0-or-later
 */

package docspell.query.internal

import cats.parse.{Parser => P}

import docspell.query.ItemQuery.Attr
import docspell.query.internal.{Constants => C}

object AttrParser {

  val name: P[Attr.StringAttr] =
    P.ignoreCase(C.name).as(Attr.ItemName)

  val source: P[Attr.StringAttr] =
    P.ignoreCase(C.source).as(Attr.ItemSource)

  val id: P[Attr.StringAttr] =
    P.ignoreCase(C.id).as(Attr.ItemId)

  val date: P[Attr.DateAttr] =
    P.ignoreCase(C.date).as(Attr.Date)

  val notes: P[Attr.StringAttr] =
    P.ignoreCase(C.notes).as(Attr.ItemNotes)

  val dueDate: P[Attr.DateAttr] =
    P.ignoreCase(C.due).as(Attr.DueDate)

  val created: P[Attr.DateAttr] =
    P.ignoreCase(C.created).as(Attr.CreatedDate)

  val corrOrgId: P[Attr.StringAttr] =
    P.ignoreCase(C.corrOrgId)
      .as(Attr.Correspondent.OrgId)

  val corrOrgName: P[Attr.StringAttr] =
    P.ignoreCase(C.corrOrgName)
      .as(Attr.Correspondent.OrgName)

  val corrPersId: P[Attr.StringAttr] =
    P.ignoreCase(C.corrPersId)
      .as(Attr.Correspondent.PersonId)

  val corrPersName: P[Attr.StringAttr] =
    P.ignoreCase(C.corrPersName)
      .as(Attr.Correspondent.PersonName)

  val concPersId: P[Attr.StringAttr] =
    P.ignoreCase(C.concPersId)
      .as(Attr.Concerning.PersonId)

  val concPersName: P[Attr.StringAttr] =
    P.ignoreCase(C.concPersName)
      .as(Attr.Concerning.PersonName)

  val concEquipId: P[Attr.StringAttr] =
    P.ignoreCase(C.concEquipId)
      .as(Attr.Concerning.EquipId)

  val concEquipName: P[Attr.StringAttr] =
    P.ignoreCase(C.concEquipName)
      .as(Attr.Concerning.EquipName)

  val folderId: P[Attr.StringAttr] =
    P.ignoreCase(C.folderId).as(Attr.Folder.FolderId)

  val folderName: P[Attr.StringAttr] =
    P.ignoreCase(C.folder).as(Attr.Folder.FolderName)

  val attachCountAttr: P[Attr.IntAttr] =
    P.ignoreCase(C.attachCount).as(Attr.AttachCount)

  // combining grouped by type

  val intAttr: P[Attr.IntAttr] =
    attachCountAttr

  val dateAttr: P[Attr.DateAttr] =
    P.oneOf(List(date, dueDate, created))

  val stringAttr: P[Attr.StringAttr] =
    P.oneOf(
      List(
        name,
        source,
        id,
        notes,
        corrOrgId,
        corrOrgName,
        corrPersId,
        corrPersName,
        concPersId,
        concPersName,
        concEquipId,
        concEquipName,
        folderId,
        folderName
      )
    )

  val anyAttr: P[Attr] =
    P.oneOf(List(dateAttr, stringAttr, intAttr))
}
