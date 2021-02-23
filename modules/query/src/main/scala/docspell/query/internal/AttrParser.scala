package docspell.query.internal

import cats.parse.{Parser => P}
import docspell.query.ItemQuery.Attr

object AttrParser {

  val name: P[Attr.StringAttr] =
    P.ignoreCase("name").map(_ => Attr.ItemName)

  val source: P[Attr.StringAttr] =
    P.ignoreCase("source").map(_ => Attr.ItemSource)

  val id: P[Attr.StringAttr] =
    P.ignoreCase("id").map(_ => Attr.ItemId)

  val date: P[Attr.DateAttr] =
    P.ignoreCase("date").map(_ => Attr.Date)

  val dueDate: P[Attr.DateAttr] =
    P.stringIn(List("dueDate", "due", "due-date")).map(_ => Attr.DueDate)

  val corrOrgId: P[Attr.StringAttr] =
    P.stringIn(List("correspondent.org.id", "corr.org.id"))
      .map(_ => Attr.Correspondent.OrgId)

  val corrOrgName: P[Attr.StringAttr] =
    P.stringIn(List("correspondent.org.name", "corr.org.name"))
      .map(_ => Attr.Correspondent.OrgName)

  val corrPersId: P[Attr.StringAttr] =
    P.stringIn(List("correspondent.person.id", "corr.pers.id"))
      .map(_ => Attr.Correspondent.PersonId)

  val corrPersName: P[Attr.StringAttr] =
    P.stringIn(List("correspondent.person.name", "corr.pers.name"))
      .map(_ => Attr.Correspondent.PersonName)

  val concPersId: P[Attr.StringAttr] =
    P.stringIn(List("concerning.person.id", "conc.pers.id"))
      .map(_ => Attr.Concerning.PersonId)

  val concPersName: P[Attr.StringAttr] =
    P.stringIn(List("concerning.person.name", "conc.pers.name"))
      .map(_ => Attr.Concerning.PersonName)

  val concEquipId: P[Attr.StringAttr] =
    P.stringIn(List("concerning.equip.id", "conc.equip.id"))
      .map(_ => Attr.Concerning.EquipId)

  val concEquipName: P[Attr.StringAttr] =
    P.stringIn(List("concerning.equip.name", "conc.equip.name"))
      .map(_ => Attr.Concerning.EquipName)

  val folderId: P[Attr.StringAttr] =
    P.ignoreCase("folder.id").map(_ => Attr.Folder.FolderId)

  val folderName: P[Attr.StringAttr] =
    P.ignoreCase("folder").map(_ => Attr.Folder.FolderName)

  val dateAttr: P[Attr.DateAttr] =
    P.oneOf(List(date, dueDate))

  val stringAttr: P[Attr.StringAttr] =
    P.oneOf(
      List(
        name,
        source,
        id,
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
    P.oneOf(List(dateAttr, stringAttr))
}
