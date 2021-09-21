/*
 * Copyright 2020 Eike K. & Contributors
 *
 * SPDX-License-Identifier: AGPL-3.0-or-later
 */

package docspell.query.internal

import docspell.query.ItemQuery.Attr
import docspell.query.internal.AttrParser

import munit._

class AttrParserTest extends FunSuite {

  test("string attributes") {
    val p = AttrParser.stringAttr
    assertEquals(p.parseAll("name"), Right(Attr.ItemName))
    assertEquals(p.parseAll("source"), Right(Attr.ItemSource))
    assertEquals(p.parseAll("id"), Right(Attr.ItemId))
    assertEquals(p.parseAll("corr.org.id"), Right(Attr.Correspondent.OrgId))
    assertEquals(p.parseAll("corr.org.name"), Right(Attr.Correspondent.OrgName))
    assertEquals(p.parseAll("conc.pers.id"), Right(Attr.Concerning.PersonId))
    assertEquals(p.parseAll("conc.pers.name"), Right(Attr.Concerning.PersonName))
    assertEquals(p.parseAll("folder"), Right(Attr.Folder.FolderName))
    assertEquals(p.parseAll("folder.id"), Right(Attr.Folder.FolderId))
  }

  test("date attributes") {
    val p = AttrParser.dateAttr
    assertEquals(p.parseAll("date"), Right(Attr.Date))
    assertEquals(p.parseAll("due"), Right(Attr.DueDate))
  }

  test("all attributes parser") {
    val p = AttrParser.anyAttr
    assertEquals(p.parseAll("date"), Right(Attr.Date))
    assertEquals(p.parseAll("name"), Right(Attr.ItemName))
    assertEquals(p.parseAll("source"), Right(Attr.ItemSource))
    assertEquals(p.parseAll("id"), Right(Attr.ItemId))
    assertEquals(p.parseAll("corr.org.id"), Right(Attr.Correspondent.OrgId))
    assertEquals(p.parseAll("corr.org.name"), Right(Attr.Correspondent.OrgName))
  }
}
