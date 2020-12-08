package docspell.store.qb

import minitest._
import docspell.store.qb._
import docspell.store.qb.model._
import docspell.store.qb.DSL._

object QueryBuilderTest extends SimpleTestSuite {

  test("simple") {
    val c        = CourseRecord.as("c")
    val owner    = PersonRecord.as("p1")
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
      case Select.Ordered(Select.SimpleSelect(proj, from, where, group), sb, vempty) =>
        assert(vempty.isEmpty)
        assertEquals(sb, OrderBy(SelectExpr.SelectColumn(c.name), OrderBy.OrderType.Desc))
        assertEquals(11, proj.size)
        from match {
          case FromExpr.From(_) =>
            fail("Unexpected from value")
          case FromExpr.Joined(f, joins) =>
            assertEquals(f, FromExpr.From(c))
            assertEquals(2, joins.size)
            joins.head match {
              case Join.InnerJoin(tbl, cond) =>
                assertEquals(tbl, owner)
                assertEquals(cond, c.ownerId === owner.id)
              case _ =>
                fail("Unexpected join result")
            }
            joins.tail.head match {
              case Join.LeftJoin(tbl, cond) =>
                assertEquals(tbl, lecturer)
                assertEquals(cond, c.lecturerId === lecturer.id)
              case _ =>
                fail("Unexpected join result")
            }
        }
        assertEquals(group, None)
        assert(where.isDefined)
      case _ =>
        fail("Unexpected case")
    }
  }
}
