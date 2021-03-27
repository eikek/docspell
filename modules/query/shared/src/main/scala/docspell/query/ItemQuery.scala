package docspell.query

import cats.data.{NonEmptyList => Nel}

import docspell.query.ItemQuery.Attr.{DateAttr, IntAttr, StringAttr}

/** A query evaluates to `true` or `false` given enough details about
  * an item.
  *
  * It may consist of (field,op,value) tuples that specify some checks
  * against a specific field of an item using some operator or a
  * combination thereof.
  */
final case class ItemQuery(expr: ItemQuery.Expr, raw: Option[String]) {
  def findFulltext: FulltextExtract.Result =
    FulltextExtract.findFulltext(expr)
}

object ItemQuery {
  val all = ItemQuery(Expr.Exists(Attr.ItemId), Some(""))

  sealed trait Operator
  object Operator {
    case object Eq   extends Operator
    case object Neq  extends Operator
    case object Like extends Operator
    case object Gt   extends Operator
    case object Lt   extends Operator
    case object Gte  extends Operator
    case object Lte  extends Operator
  }

  sealed trait TagOperator
  object TagOperator {
    case object AllMatch extends TagOperator
    case object AnyMatch extends TagOperator
  }

  sealed trait Attr
  object Attr {
    sealed trait StringAttr extends Attr
    sealed trait DateAttr   extends Attr
    sealed trait IntAttr    extends Attr

    case object ItemName    extends StringAttr
    case object ItemSource  extends StringAttr
    case object ItemNotes   extends StringAttr
    case object ItemId      extends StringAttr
    case object Date        extends DateAttr
    case object DueDate     extends DateAttr
    case object AttachCount extends IntAttr

    object Correspondent {
      case object OrgId      extends StringAttr
      case object OrgName    extends StringAttr
      case object PersonId   extends StringAttr
      case object PersonName extends StringAttr
    }

    object Concerning {
      case object PersonId   extends StringAttr
      case object PersonName extends StringAttr
      case object EquipId    extends StringAttr
      case object EquipName  extends StringAttr
    }

    object Folder {
      case object FolderId   extends StringAttr
      case object FolderName extends StringAttr
    }
  }

  sealed trait Property
  object Property {
    final case class StringProperty(attr: StringAttr, value: String) extends Property
    final case class DateProperty(attr: DateAttr, value: Date)       extends Property
    final case class IntProperty(attr: IntAttr, value: Int)          extends Property

    def apply(sa: StringAttr, value: String): Property =
      StringProperty(sa, value)

    def apply(da: DateAttr, value: Date): Property =
      DateProperty(da, value)

    def apply(na: IntAttr, value: Int): Property =
      IntProperty(na, value)
  }

  sealed trait Expr {
    def negate: Expr =
      Expr.NotExpr(this)
  }

  object Expr {
    final case class AndExpr(expr: Nel[Expr]) extends Expr
    final case class OrExpr(expr: Nel[Expr])  extends Expr
    final case class NotExpr(expr: Expr) extends Expr {
      override def negate: Expr =
        expr
    }

    final case class SimpleExpr(op: Operator, prop: Property)      extends Expr
    final case class Exists(field: Attr)                           extends Expr
    final case class InExpr(attr: StringAttr, values: Nel[String]) extends Expr
    final case class InDateExpr(attr: DateAttr, values: Nel[Date]) extends Expr
    final case class InboxExpr(inbox: Boolean)                     extends Expr
    final case class DirectionExpr(incoming: Boolean)              extends Expr

    final case class TagIdsMatch(op: TagOperator, tags: Nel[String])      extends Expr
    final case class TagsMatch(op: TagOperator, tags: Nel[String])        extends Expr
    final case class TagCategoryMatch(op: TagOperator, cats: Nel[String]) extends Expr

    final case class CustomFieldMatch(name: String, op: Operator, value: String)
        extends Expr
    final case class CustomFieldIdMatch(id: String, op: Operator, value: String)
        extends Expr

    final case class Fulltext(query: String)         extends Expr
    final case class ChecksumMatch(checksum: String) extends Expr
    final case class AttachId(id: String)            extends Expr

    case object ValidItemStates extends Expr

    // things that can be expressed with terms above
    sealed trait MacroExpr extends Expr {
      def body: Expr
    }
    final case class NamesMacro(searchTerm: String) extends MacroExpr {
      val body =
        Expr.or(
          like(Attr.ItemName, searchTerm),
          like(Attr.Correspondent.OrgName, searchTerm),
          like(Attr.Correspondent.PersonName, searchTerm),
          like(Attr.Concerning.PersonName, searchTerm),
          like(Attr.Concerning.EquipName, searchTerm)
        )
    }

    final case class CorrMacro(term: String) extends MacroExpr {
      val body =
        Expr.or(
          like(Attr.Correspondent.OrgName, term),
          like(Attr.Correspondent.PersonName, term)
        )
    }

    final case class ConcMacro(term: String) extends MacroExpr {
      val body =
        Expr.or(
          like(Attr.Concerning.PersonName, term),
          like(Attr.Concerning.EquipName, term)
        )
    }

    final case class DateRangeMacro(attr: DateAttr, left: Date, right: Date)
        extends MacroExpr {
      val body =
        and(date(Operator.Gte, attr, left), date(Operator.Lt, attr, right))
    }

    final case class YearMacro(attr: DateAttr, year: Int) extends MacroExpr {
      val body =
        DateRangeMacro(attr, date(year), date(year + 1))

      private def date(y: Int): Date =
        Date(y, 1, 1).fold(throw _, identity)
    }

    def or(expr0: Expr, exprs: Expr*): OrExpr =
      OrExpr(Nel.of(expr0, exprs: _*))

    def and(expr0: Expr, exprs: Expr*): AndExpr =
      AndExpr(Nel.of(expr0, exprs: _*))

    def string(op: Operator, attr: StringAttr, value: String): SimpleExpr =
      SimpleExpr(op, Property(attr, value))

    def like(attr: StringAttr, value: String): SimpleExpr =
      string(Operator.Like, attr, value)

    def date(op: Operator, attr: DateAttr, value: Date): SimpleExpr =
      SimpleExpr(op, Property(attr, value))
  }

}
