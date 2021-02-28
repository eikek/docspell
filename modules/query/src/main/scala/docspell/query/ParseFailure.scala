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

final case class ParseFailure(
    input: String,
    failedAt: Int,
    messages: Nel[ParseFailure.Message]
) {

  def render: String = {
    val items = messages.map(_.msg).toList.mkString(", ")
    s"Failed to read input near $failedAt: $input\nDetails: $items"
  }
}

object ParseFailure {

  final case class Message(offset: Int, msg: String)

  private[query] def fromError(input: String)(pe: Parser.Error): ParseFailure =
    ParseFailure(
      input,
      pe.failedAtOffset,
      Parser.Expectation.unify(pe.expected).map(expectationToMsg)
    )

  private[query] def expectationToMsg(e: Parser.Expectation): Message =
    e match {
      case StartOfString(offset) =>
        Message(offset, "Expected start of string")

      case FailWith(offset, message) =>
        Message(offset, message)

      case InRange(offset, lower, upper) =>
        if (lower == upper) Message(offset, s"Expected character: $lower")
        else Message(offset, s"Expected character from range: [$lower .. $upper]")

      case Length(offset, expected, actual) =>
        Message(offset, s"Expected input of length $expected, but got $actual")

      case ExpectedFailureAt(offset, matched) =>
        Message(offset, s"Expected failing, but matched '$matched'")

      case EndOfString(offset, length) =>
        Message(offset, s"Expected end of string at length: $length")

      case Fail(offset) =>
        Message(offset, s"Failed to parse near $offset")

      case OneOfStr(offset, strs) =>
        val options = strs.mkString(", ")
        Message(offset, s"Expected one of the following strings: $options")
    }
}
