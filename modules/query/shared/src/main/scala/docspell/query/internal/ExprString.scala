/*
 * Copyright 2020 Eike K. & Contributors
 *
 * SPDX-License-Identifier: AGPL-3.0-or-later
 */

package docspell.query.internal

import java.time.Period

import docspell.query.Date
import docspell.query.Date.DateLiteral
import docspell.query.ItemQuery.Attr._
import docspell.query.ItemQuery.Expr._
import docspell.query.ItemQuery._
import docspell.query.internal.{Constants => C}

/** Creates the string representation for a given expression. The returned string can be
  * parsed back to the expression using `ExprParser`. Note that expressions obtained from
  * the `ItemQueryParser` have macros already expanded.
  *
  * It may fail when the expression contains non-public parts. Every expression that has
  * been created by parsing a string, can be transformed back to a string. But an
  * expression created via code may contain parts that cannot be transformed to a string.
  */
object ExprString {

  final case class PrivateExprError(expr: Expr.PrivateExpr)
  type Result = Either[PrivateExprError, String]

  def apply(expr: Expr): Result =
    expr match {
      case AndExpr(inner) =>
        val es = inner.traverse(ExprString.apply)
        es.map(_.toList.mkString(" ")).map(els => s"(& $els )")

      case OrExpr(inner) =>
        val es = inner.traverse(ExprString.apply)
        es.map(_.toList.mkString(" ")).map(els => s"(| $els )")

      case NotExpr(inner) =>
        inner match {
          case NotExpr(inner2) =>
            apply(inner2)
          case _ =>
            apply(inner).map(n => s"!$n")
        }

      case m: MacroExpr =>
        Right(macroStr(m))

      case DirectionExpr(v) =>
        Right(s"${C.incoming}${C.like}${v}")

      case InboxExpr(v) =>
        Right(s"${C.inbox}${C.like}${v}")

      case InExpr(attr, values) =>
        val els = values.map(quote).toList.mkString(",")
        Right(s"${attrStr(attr)}${C.in}$els")

      case InDateExpr(attr, values) =>
        val els = values.map(dateStr).toList.mkString(",")
        Right(s"${attrStr(attr)}${C.in}$els")

      case TagsMatch(op, values) =>
        val els = values.map(quote).toList.mkString(",")
        Right(s"${C.tag}${tagOpStr(op)}$els")

      case TagIdsMatch(op, values) =>
        val els = values.map(quote).toList.mkString(",")
        Right(s"${C.tagId}${tagOpStr(op)}$els")

      case Exists(field) =>
        Right(s"${C.exist}${C.like}${attrStr(field)}")

      case Fulltext(v) =>
        Right(s"${C.content}${C.like}${quote(v)}")

      case SimpleExpr(op, prop) =>
        prop match {
          case Property.StringProperty(attr, value) =>
            Right(s"${stringAttr(attr)}${opStr(op)}${quote(value)}")
          case Property.DateProperty(attr, value) =>
            Right(s"${dateAttr(attr)}${opStr(op)}${dateStr(value)}")
//          case Property.IntProperty(attr, value) =>
//            Right(s"${attrStr(attr)}${opStr(op)}$value")
        }

      case TagCategoryMatch(op, values) =>
        val els = values.map(quote).toList.mkString(",")
        Right(s"${C.cat}${tagOpStr(op)}$els")

      case CustomFieldMatch(name, op, value) =>
        Right(s"${C.customField}:$name${opStr(op)}${quote(value)}")

      case CustomFieldIdMatch(id, op, value) =>
        Right(s"${C.customFieldId}:$id${opStr(op)}${quote(value)}")

      case ChecksumMatch(cs) =>
        Right(s"${C.checksum}${C.like}$cs")

      case AttachId(aid) =>
        Right(s"${C.attachId}${C.eqs}$aid")

      case pe: PrivateExpr =>
        // There is no parser equivalent for this
        Left(PrivateExprError(pe))
    }

  private[internal] def macroStr(expr: Expr.MacroExpr): String =
    expr match {
      case Expr.NamesMacro(name) =>
        s"${C.names}:${quote(name)}"
      case Expr.YearMacro(_, year) =>
        s"${C.year}:$year" // currently, only for Attr.Date
      case Expr.ConcMacro(term) =>
        s"${C.conc}:${quote(term)}"
      case Expr.CorrMacro(term) =>
        s"${C.corr}:${quote(term)}"
      case Expr.DateRangeMacro(attr, left, right) =>
        val name = attr match {
          case Attr.CreatedDate =>
            C.createdIn
          case Attr.Date =>
            C.dateIn
          case Attr.DueDate =>
            C.dueIn
        }
        (left, right) match {
          case (_: Date.DateLiteral, Date.Calc(date, calc, period)) =>
            s"$name:${dateStr(date)};${calcStr(calc)}${periodStr(period)}"

          case (Date.Calc(date, calc, period), _: DateLiteral) =>
            s"$name:${dateStr(date)};${calcStr(calc)}${periodStr(period)}"

          case (Date.Calc(d1, _, p1), Date.Calc(_, _, _)) =>
            s"$name:${dateStr(d1)};/${periodStr(p1)}"

          case (_: DateLiteral, _: DateLiteral) =>
            sys.error("Invalid date range")
        }
    }

  private[internal] def dateStr(date: Date): String =
    date match {
      case Date.Today =>
        "today"
      case Date.Local(ld) =>
        f"${ld.getYear}-${ld.getMonthValue}%02d-${ld.getDayOfMonth}%02d"

      case Date.Millis(ms) =>
        s"ms$ms"

      case Date.Calc(date, calc, period) =>
        val ds = dateStr(date)
        s"$ds;${calcStr(calc)}${periodStr(period)}"
    }

  private[internal] def calcStr(c: Date.CalcDirection): String =
    c match {
      case Date.CalcDirection.Plus  => "+"
      case Date.CalcDirection.Minus => "-"
    }

  private[internal] def periodStr(p: Period): String =
    if (p.toTotalMonths == 0) s"${p.getDays}d"
    else s"${p.toTotalMonths}m"

  private[internal] def attrStr(attr: Attr): String =
    attr match {
      case a: StringAttr => stringAttr(a)
      case a: DateAttr   => dateAttr(a)
    }

  private[internal] def dateAttr(attr: DateAttr): String =
    attr match {
      case Attr.Date =>
        Constants.date
      case DueDate =>
        Constants.due
      case CreatedDate =>
        Constants.created
    }

  private[internal] def stringAttr(attr: StringAttr): String =
    attr match {
      case Attr.ItemName =>
        Constants.name
      case Attr.ItemId =>
        Constants.id
      case Attr.ItemSource =>
        Constants.source
      case Attr.ItemNotes =>
        Constants.notes
      case Correspondent.OrgId =>
        Constants.corrOrgId
      case Correspondent.OrgName =>
        Constants.corrOrgName
      case Correspondent.PersonId =>
        Constants.corrPersId
      case Correspondent.PersonName =>
        Constants.corrPersName
      case Concerning.EquipId =>
        Constants.concEquipId
      case Concerning.EquipName =>
        Constants.concEquipName
      case Concerning.PersonId =>
        Constants.concPersId
      case Concerning.PersonName =>
        Constants.concPersName
      case Folder.FolderName =>
        Constants.folder
      case Folder.FolderId =>
        Constants.folderId
    }

  private[internal] def opStr(op: Operator): String =
    op match {
      case Operator.Like => Constants.like.toString
      case Operator.Gte  => Constants.gte
      case Operator.Lte  => Constants.lte
      case Operator.Eq   => Constants.eqs.toString
      case Operator.Lt   => Constants.lt.toString
      case Operator.Gt   => Constants.gt.toString
      case Operator.Neq  => Constants.neq
    }

  private[internal] def tagOpStr(op: TagOperator): String =
    op match {
      case TagOperator.AllMatch => C.eqs.toString
      case TagOperator.AnyMatch => C.like.toString
    }

  private def quote(s: String): String =
    s"\"$s\""
}
