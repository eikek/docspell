/*
 * Copyright 2020 Eike K. & Contributors
 *
 * SPDX-License-Identifier: AGPL-3.0-or-later
 */

package docspell.store.qb.impl

import docspell.store.qb.DSL._
import docspell.store.qb._
import docspell.store.qb.model.{CourseRecord, PersonRecord}

import munit._

class DSLTest extends FunSuite {

  val course = CourseRecord.as("c")
  val person = PersonRecord.as("p")

  test("delete") {
    val frag = DML.deleteFragment(course, course.ownerId === 15L)
    assertEquals(frag.internals.sql, "DELETE FROM course c WHERE c.owner_id = ? ")
  }

  test("and") {
    val c = course.lessons > 4 && person.id === 3 && person.name.like("%a%")
    val expect =
      Condition.And(course.lessons > 4, person.id === 3, person.name.like("%a%"))
    assertEquals(c, expect)
  }
}
