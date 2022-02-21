/*
 * Copyright 2020 Eike K. & Contributors
 *
 * SPDX-License-Identifier: AGPL-3.0-or-later
 */

package docspell.store.qb.impl

import docspell.logging.TestLoggingConfig
import docspell.store.qb.DSL._
import docspell.store.qb._
import docspell.store.qb.model._

import munit._

class SelectBuilderTest extends FunSuite with TestLoggingConfig {

  test("basic fragment") {
    val c = CourseRecord.as("c")
    val owner = PersonRecord.as("o")
    val lecturer = PersonRecord.as("l")

    val proj = select(c.all)
    val table = from(c)
      .innerJoin(owner, c.ownerId === owner.id)
      .leftJoin(lecturer, c.lecturerId === lecturer.id)
    val cond = where(
      c.name.like("%test%"),
      owner.name === "Harald"
    )

    val q = Select(proj, table, cond)
    val frag = SelectBuilder(q)
    assertEquals(
      frag.toString,
      """Fragment("SELECT c.id, c.name, c.owner_id, c.lecturer_id, c.lessons FROM course c INNER JOIN person o ON c.owner_id = o.id LEFT JOIN person l ON c.lecturer_id = l.id WHERE (LOWER(c.name) LIKE ?  AND o.name = ? )")"""
    )
  }

}
