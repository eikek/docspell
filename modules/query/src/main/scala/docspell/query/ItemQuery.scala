package docspell.query

import cats.data.{NonEmptyList => Nel}
import docspell.query.ItemQuery.Attr.{DateAttr, StringAttr}

/** A query evaluates to `true` or `false` given enough details about
  * an item.
  *
  * It may consist of (field,op,value) tuples that specify some checks
  * against a specific field of an item using some operator or a
  * combination thereof.
  */
final case class ItemQuery(expr: ItemQuery.Expr, raw: Option[String])

object ItemQuery {

  sealed trait Operator
  object Operator {
    case object Eq   extends Operator
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

    case object ItemName   extends StringAttr
    case object ItemSource extends StringAttr
    case object ItemId     extends StringAttr
    case object Date       extends DateAttr
    case object DueDate    extends DateAttr

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

  }

  sealed trait Expr {
    def negate: Expr =
      Expr.NotExpr(this)
  }

  object Expr {
    case class AndExpr(expr: Nel[Expr]) extends Expr
    case class OrExpr(expr: Nel[Expr])  extends Expr
    case class NotExpr(expr: Expr) extends Expr {
      override def negate: Expr =
        expr
    }

    case class SimpleExpr(op: Operator, prop: Property)      extends Expr
    case class Exists(field: Attr)                           extends Expr
    case class InExpr(attr: StringAttr, values: Nel[String]) extends Expr

    case class TagIdsMatch(op: TagOperator, tags: Nel[String])      extends Expr
    case class TagsMatch(op: TagOperator, tags: Nel[String])        extends Expr
    case class TagCategoryMatch(op: TagOperator, cats: Nel[String]) extends Expr

    case class CustomFieldMatch(name: String, op: Operator, value: String) extends Expr

    case class Fulltext(query: String) extends Expr
  }

}
