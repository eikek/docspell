/*
 * Copyright 2020 Eike K. & Contributors
 *
 * SPDX-License-Identifier: AGPL-3.0-or-later
 */

package docspell.query

import java.time.{Instant, Period, ZoneOffset}

import cats.data.NonEmptyList

import docspell.query.ItemQuery.Expr.TagIdsMatch
import docspell.query.ItemQuery._

import org.scalacheck.Gen

/** Generator for syntactically valid queries. */
object ItemQueryGen {

  def exprGen: Gen[Expr] =
    Gen.oneOf(
      simpleExprGen,
      existsExprGen,
      inExprGen,
      inDateExprGen,
      inboxExprGen,
      directionExprGen,
      tagIdsMatchExprGen,
      tagMatchExprGen,
      tagCatMatchExpr,
      customFieldMatchExprGen,
      customFieldIdMatchExprGen,
      fulltextExprGen,
      checksumMatchExprGen,
      attachIdExprGen,
      namesMacroGen,
      corrMacroGen,
      concMacroGen,
      yearMacroGen,
      dateRangeMacro,
      Gen.lzy(andExprGen(exprGen)),
      Gen.lzy(orExprGen(exprGen)),
      Gen.lzy(notExprGen(exprGen))
    )

  def andExprGen(g: Gen[Expr]): Gen[Expr.AndExpr] =
    nelGen(g).map(Expr.AndExpr)

  def orExprGen(g: Gen[Expr]): Gen[Expr.OrExpr] =
    nelGen(g).map(Expr.OrExpr)

  // avoid generating nested not expressions, they are already flattened by the parser
  // and only occur artificially
  def notExprGen(g: Gen[Expr]): Gen[Expr] =
    g.map {
      case Expr.NotExpr(inner) => inner
      case e                   => Expr.NotExpr(e)
    }

  val opGen: Gen[Operator] =
    Gen.oneOf(
      Operator.Like,
      Operator.Gte,
      Operator.Lt,
      Operator.Gt,
      Operator.Lte,
      Operator.Eq,
      Operator.Neq
    )

  val tagOpGen: Gen[TagOperator] =
    Gen.oneOf(TagOperator.AllMatch, TagOperator.AnyMatch)

  val stringAttrGen: Gen[Attr.StringAttr] =
    Gen.oneOf(
      Attr.Concerning.EquipName,
      Attr.Concerning.EquipId,
      Attr.Concerning.PersonName,
      Attr.Concerning.PersonId,
      Attr.Correspondent.OrgName,
      Attr.Correspondent.OrgId,
      Attr.Correspondent.PersonName,
      Attr.Correspondent.PersonId,
      Attr.ItemId,
      Attr.ItemName,
      Attr.ItemSource,
      Attr.ItemNotes,
      Attr.Folder.FolderId,
      Attr.Folder.FolderName
    )

  val dateAttrGen: Gen[Attr.DateAttr] =
    Gen.oneOf(Attr.Date, Attr.DueDate, Attr.CreatedDate)

  val attrGen: Gen[Attr] =
    Gen.oneOf(stringAttrGen, dateAttrGen)

  private val valueChars =
    Gen.oneOf(Gen.alphaNumChar, Gen.oneOf(" /{}*?-:@#$~+%…_[]^!ß"))

  private val stringValueGen: Gen[String] =
    Gen.choose(1, 20).flatMap(n => Gen.stringOfN(n, valueChars))

  private val identGen: Gen[String] =
    Gen
      .choose(3, 12)
      .flatMap(n =>
        Gen.stringOfN(
          n,
          Gen.oneOf((('A' to 'Z') ++ ('a' to 'z') ++ ('0' to '9') ++ "-_.@").toSet)
        )
      )

  private def nelGen[T](gen: Gen[T]): Gen[NonEmptyList[T]] =
    for {
      head <- gen
      tail <- Gen.choose(0, 9).flatMap(n => Gen.listOfN(n, gen))
    } yield NonEmptyList(head, tail)

  private val dateMillisGen: Gen[Long] =
    Gen.choose(0, Instant.parse("2100-12-24T20:00:00Z").toEpochMilli)

  val localDateGen: Gen[Date.Local] =
    dateMillisGen
      .map(ms => Instant.ofEpochMilli(ms).atOffset(ZoneOffset.UTC).toLocalDate)
      .map(Date.Local)

  val millisDateGen: Gen[Date.Millis] =
    dateMillisGen.map(Date.Millis)

  val dateLiteralGen: Gen[Date.DateLiteral] =
    Gen.oneOf(
      localDateGen,
      millisDateGen,
      Gen.const(Date.Today)
    )

  val periodGen: Gen[Period] =
    for {
      mOrD <- Gen.oneOf(a => Period.ofDays(a), a => Period.ofMonths(a))
      num <- Gen.choose(1, 30)
    } yield mOrD(num)

  val calcGen: Gen[Date.CalcDirection] =
    Gen.oneOf(Date.CalcDirection.Plus, Date.CalcDirection.Minus)

  val dateCalcGen: Gen[Date.Calc] =
    for {
      dl <- dateLiteralGen
      calc <- calcGen
      period <- periodGen
    } yield Date.Calc(dl, calc, period)

  val dateValueGen: Gen[Date] =
    Gen.oneOf(dateLiteralGen, dateCalcGen)

  val stringPropGen: Gen[Property.StringProperty] =
    for {
      attr <- stringAttrGen
      sval <- stringValueGen
    } yield Property.StringProperty(attr, sval)

  val datePropGen: Gen[Property.DateProperty] =
    for {
      attr <- dateAttrGen
      dv <- dateValueGen
    } yield Property.DateProperty(attr, dv)

  val propertyGen: Gen[Property] =
    Gen.oneOf(stringPropGen, datePropGen)

  val simpleExprGen: Gen[Expr.SimpleExpr] =
    for {
      op <- opGen
      prop <- propertyGen
    } yield Expr.SimpleExpr(op, prop)

  val existsExprGen: Gen[Expr.Exists] =
    attrGen.map(Expr.Exists)

  val inExprGen: Gen[Expr.InExpr] =
    for {
      attr <- stringAttrGen
      vals <- nelGen(stringValueGen)
    } yield Expr.InExpr(attr, vals)

  val inDateExprGen: Gen[Expr.InDateExpr] =
    for {
      attr <- dateAttrGen
      vals <- nelGen(dateValueGen)
    } yield Expr.InDateExpr(attr, vals)

  val inboxExprGen: Gen[Expr.InboxExpr] =
    Gen.oneOf(true, false).map(Expr.InboxExpr)

  val directionExprGen: Gen[Expr.DirectionExpr] =
    Gen.oneOf(true, false).map(Expr.DirectionExpr)

  val tagIdsMatchExprGen: Gen[Expr.TagIdsMatch] =
    for {
      op <- tagOpGen
      vals <- nelGen(stringValueGen)
    } yield TagIdsMatch(op, vals)

  val tagMatchExprGen: Gen[Expr.TagsMatch] =
    for {
      op <- tagOpGen
      vals <- nelGen(stringValueGen)
    } yield Expr.TagsMatch(op, vals)

  val tagCatMatchExpr: Gen[Expr.TagCategoryMatch] =
    for {
      op <- tagOpGen
      vals <- nelGen(stringValueGen)
    } yield Expr.TagCategoryMatch(op, vals)

  val customFieldMatchExprGen: Gen[Expr.CustomFieldMatch] =
    for {
      name <- identGen
      op <- opGen
      value <- stringValueGen
    } yield Expr.CustomFieldMatch(name, op, value)

  val customFieldIdMatchExprGen: Gen[Expr.CustomFieldIdMatch] =
    for {
      name <- identGen
      op <- opGen
      value <- identGen
    } yield Expr.CustomFieldIdMatch(name, op, value)

  val fulltextExprGen: Gen[Expr.Fulltext] =
    Gen
      .choose(3, 20)
      .flatMap(n => Gen.stringOfN(n, valueChars))
      .map(Expr.Fulltext)

  val checksumMatchExprGen: Gen[Expr.ChecksumMatch] =
    Gen.stringOfN(64, Gen.hexChar).map(Expr.ChecksumMatch)

  val attachIdExprGen: Gen[Expr.AttachId] =
    identGen.map(Expr.AttachId)

  val namesMacroGen: Gen[Expr.NamesMacro] =
    stringValueGen.map(Expr.NamesMacro)

  val concMacroGen: Gen[Expr.ConcMacro] =
    stringValueGen.map(Expr.ConcMacro)

  val corrMacroGen: Gen[Expr.CorrMacro] =
    stringValueGen.map(Expr.CorrMacro)

  val yearMacroGen: Gen[Expr.YearMacro] =
    Gen.choose(1900, 9999).map(Expr.YearMacro(Attr.Date, _))

  val dateRangeMacro: Gen[Expr.DateRangeMacro] =
    for {
      attr <- dateAttrGen
      dl <- dateLiteralGen
      p <- periodGen
      calc <- Gen.option(calcGen)
      range = calc match {
        case Some(c @ Date.CalcDirection.Plus) =>
          Expr.DateRangeMacro(attr, dl, Date.Calc(dl, c, p))
        case Some(c @ Date.CalcDirection.Minus) =>
          Expr.DateRangeMacro(attr, Date.Calc(dl, c, p), dl)
        case None =>
          Expr.DateRangeMacro(
            attr,
            Date.Calc(dl, Date.CalcDirection.Minus, p),
            Date.Calc(dl, Date.CalcDirection.Plus, p)
          )
      }
    } yield range
}
