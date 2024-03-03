/*
 * Copyright 2020 Eike K. & Contributors
 *
 * SPDX-License-Identifier: AGPL-3.0-or-later
 */

package docspell.query

import cats.data.{NonEmptyList => Nel}
import cats.parse.Parser
import cats.parse.Parser.Expectation.EndOfString
import cats.parse.Parser.Expectation.ExpectedFailureAt
import cats.parse.Parser.Expectation.Fail
import cats.parse.Parser.Expectation.FailWith
import cats.parse.Parser.Expectation.InRange
import cats.parse.Parser.Expectation.Length
import cats.parse.Parser.Expectation.OneOfStr
import cats.parse.Parser.Expectation.StartOfString
import cats.parse.Parser.Expectation.WithContext

final case class ParseFailure(
    input: String,
    failedAt: Int,
    messages: Nel[ParseFailure.Message]
) {

  def render: String = {
    val items = messages.map(_.render).toList.mkString(", ")
    s"Failed to read input near $failedAt: $input\nDetails: $items"
  }
}

object ParseFailure {

  sealed trait Message {
    def offset: Int
    def render: String
  }
  final case class SimpleMessage(offset: Int, msg: String) extends Message {
    def render: String =
      s"Failed at $offset: $msg"
  }
  final case class ExpectMessage(offset: Int, expected: List[String], exhaustive: Boolean)
      extends Message {
    def render: String = {
      val opts = expected.mkString(", ")
      val dots = if (exhaustive) "" else "…"
      s"Expected: $opts$dots"
    }
  }

  private[query] def fromError(input: String)(pe: Parser.Error): ParseFailure =
    ParseFailure(
      input,
      pe.failedAtOffset,
      packMsg(Parser.Expectation.unify(pe.expected).map(expectationToMsg))
    )

  private[query] def packMsg(msg: Nel[Message]): Nel[Message] = {
    val expectMsg = combineExpected(msg.collect { case em: ExpectMessage => em })
      .sortBy(_.offset)
      .headOption

    val simpleMsg = msg.collect { case sm: SimpleMessage => sm }

    Nel.fromListUnsafe((simpleMsg ++ expectMsg).sortBy(_.offset))
  }

  private[query] def combineExpected(msg: List[ExpectMessage]): List[ExpectMessage] =
    msg
      .groupBy(_.offset)
      .map { case (offset, es) =>
        ExpectMessage(
          offset,
          es.flatMap(_.expected).distinct.sorted,
          es.forall(_.exhaustive)
        )
      }
      .toList

  private[query] def expectationToMsg(e: Parser.Expectation): Message =
    e match {
      case StartOfString(offset) =>
        SimpleMessage(offset, "Expected start of string")

      case FailWith(offset, message) =>
        SimpleMessage(offset, message)

      case InRange(offset, lower, upper) =>
        if (lower == upper) ExpectMessage(offset, List(lower.toString), exhaustive = true)
        else {
          val expect = s"$lower-$upper"
          ExpectMessage(offset, List(expect), exhaustive = true)
        }

      case Length(offset, expected, actual) =>
        SimpleMessage(offset, s"Expected input of length $expected, but got $actual")

      case ExpectedFailureAt(offset, matched) =>
        SimpleMessage(offset, s"Expected failing, but matched '$matched'")

      case EndOfString(offset, length) =>
        SimpleMessage(offset, s"Expected end of string at length: $length")

      case Fail(offset) =>
        SimpleMessage(offset, s"Failed to parse near $offset")

      case OneOfStr(offset, strs) =>
        val options = strs.take(8)
        ExpectMessage(offset, options.take(7), options.size < 8)

      case WithContext(ctx, expect) =>
        ExpectMessage(
          expect.offset,
          s"Failed to parse near: $ctx" :: Nil,
          exhaustive = true
        )
    }
}
