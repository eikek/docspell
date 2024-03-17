/*
 * Copyright 2020 Eike K. & Contributors
 *
 * SPDX-License-Identifier: AGPL-3.0-or-later
 */

package docspell.store.qb

import docspell.logging.TestLoggingConfig
import docspell.store.qb.DSL._
import docspell.store.qb.model._

import munit._

class QueryBuilderTest extends FunSuite with TestLoggingConfig {

  test("simple") {
    val c = CourseRecord.as("c")
    val owner = PersonRecord.as("p1")
    val lecturer = PersonRecord.as("p2")

    val proj = select(c.all, owner.all, lecturer.all)

    val tables =
      from(c)
        .innerJoin(owner, c.ownerId === owner.id)
        .leftJoin(lecturer, c.lecturerId === lecturer.id)

    val cond =
      where(
        c.name.like("%scala%"),
        c.lessons <= 15,
        or(
          owner.name.like("%"),
          lecturer.id >= 1
        )
      )

    val q = Select(proj, tables, cond).orderBy(c.name.desc)
    q match {
      case Select.Ordered(
            Select.SimpleSelect(false, projs, from, where, group),
            sb,
            vempty
          ) =>
        assert(vempty.isEmpty)
        assertEquals(
          sb,
          OrderBy(SelectExpr.SelectColumn(c.name, None), OrderBy.OrderType.Desc)
        )
        assertEquals(11, projs.size)
        from match {
          case None =>
            fail("Unexpected from value")
          case Some(FromExpr.From(_)) =>
            fail("Unexpected from value")
          case Some(FromExpr.Joined(f, joins)) =>
            assertEquals(f, FromExpr.From(c))
            assertEquals(2, joins.size)
            joins.head match {
              case FromExpr.Join.InnerJoin(FromExpr.Relation.Table(tbl), cond) =>
                assertEquals(tbl, owner)
                assertEquals(cond, c.ownerId === owner.id)
              case _ =>
                fail("Unexpected join result")
            }
            joins.tail.head match {
              case FromExpr.Join.LeftJoin(FromExpr.Relation.Table(tbl), cond) =>
                assertEquals(tbl, lecturer)
                assertEquals(cond, c.lecturerId === lecturer.id)
              case _ =>
                fail("Unexpected join result")
            }
          case _ =>
            fail("Unexpected result")
        }
        assertEquals(group, None)
        assert(where != Condition.unit)
      case _ =>
        fail("Unexpected case")
    }
  }
}
