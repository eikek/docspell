package docspell.query.internal

import cats.parse.{Parser => P}

import docspell.query.ItemQuery.Attr

object AttrParser {

  val name: P[Attr.StringAttr] =
    P.ignoreCase("name").as(Attr.ItemName)

  val source: P[Attr.StringAttr] =
    P.ignoreCase("source").as(Attr.ItemSource)

  val id: P[Attr.StringAttr] =
    P.ignoreCase("id").as(Attr.ItemId)

  val date: P[Attr.DateAttr] =
    P.ignoreCase("date").as(Attr.Date)

  val notes: P[Attr.StringAttr] =
    P.ignoreCase("notes").as(Attr.ItemNotes)

  val dueDate: P[Attr.DateAttr] =
    P.stringIn(List("dueDate", "due", "due-date")).as(Attr.DueDate)

  val corrOrgId: P[Attr.StringAttr] =
    P.stringIn(List("correspondent.org.id", "corr.org.id"))
      .as(Attr.Correspondent.OrgId)

  val corrOrgName: P[Attr.StringAttr] =
    P.stringIn(List("correspondent.org.name", "corr.org.name"))
      .as(Attr.Correspondent.OrgName)

  val corrPersId: P[Attr.StringAttr] =
    P.stringIn(List("correspondent.person.id", "corr.pers.id"))
      .as(Attr.Correspondent.PersonId)

  val corrPersName: P[Attr.StringAttr] =
    P.stringIn(List("correspondent.person.name", "corr.pers.name"))
      .as(Attr.Correspondent.PersonName)

  val concPersId: P[Attr.StringAttr] =
    P.stringIn(List("concerning.person.id", "conc.pers.id"))
      .as(Attr.Concerning.PersonId)

  val concPersName: P[Attr.StringAttr] =
    P.stringIn(List("concerning.person.name", "conc.pers.name"))
      .as(Attr.Concerning.PersonName)

  val concEquipId: P[Attr.StringAttr] =
    P.stringIn(List("concerning.equip.id", "conc.equip.id"))
      .as(Attr.Concerning.EquipId)

  val concEquipName: P[Attr.StringAttr] =
    P.stringIn(List("concerning.equip.name", "conc.equip.name"))
      .as(Attr.Concerning.EquipName)

  val folderId: P[Attr.StringAttr] =
    P.ignoreCase("folder.id").as(Attr.Folder.FolderId)

  val folderName: P[Attr.StringAttr] =
    P.ignoreCase("folder").as(Attr.Folder.FolderName)

  val attachCountAttr: P[Attr.IntAttr] =
    P.ignoreCase("attach.count").as(Attr.AttachCount)

  // combining grouped by type

  val intAttr: P[Attr.IntAttr] =
    attachCountAttr

  val dateAttr: P[Attr.DateAttr] =
    P.oneOf(List(date, dueDate))

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
