package docspell.query.internal

import cats.data.{NonEmptyList => Nel}
import cats.parse.{Parser0, Parser => P}

object BasicParser {
  private[this] val whitespace: P[Unit] = P.charIn(" \t\r\n").void

  val ws0: Parser0[Unit] = whitespace.rep0.void
  val ws1: P[Unit]       = whitespace.rep(1).void

  private[this] val listSep: P[Unit] =
    P.char(',').surroundedBy(BasicParser.ws0).void

  def rep[A](pa: P[A]): P[Nel[A]] =
    pa.repSep(listSep)

  private[this] val basicString: P[String] =
    P.charsWhile(c =>
      c > ' ' && c != '"' && c != '\\' && c != ',' && c != '[' && c != ']'
    )

  private[this] val identChars: Set[Char] =
    (('A' to 'Z') ++ ('a' to 'z') ++ ('0' to '9') ++ "-_.").toSet

  val parenAnd: P[Unit] =
    P.stringIn(List("(&", "(and")).void.surroundedBy(ws0)

  val parenClose: P[Unit] =
    P.char(')').surroundedBy(ws0)

  val parenOr: P[Unit] =
    P.stringIn(List("(|", "(or")).void.surroundedBy(ws0)

  val identParser: P[String] =
    P.charsWhile(identChars.contains)

  val singleString: P[String] =
    basicString.backtrack.orElse(StringUtil.quoted('"'))

  val stringListValue: P[Nel[String]] = rep(singleString).with1
    .between(P.char('['), P.char(']'))
    .backtrack
    .orElse(rep(singleString))

  val stringOrMore: P[Nel[String]] =
    stringListValue.backtrack.orElse(
      singleString.map(v => Nel.of(v))
    )

}
