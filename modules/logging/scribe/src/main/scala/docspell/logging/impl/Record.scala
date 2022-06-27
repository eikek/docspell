/*
 * Copyright 2020 Eike K. & Contributors
 *
 * SPDX-License-Identifier: AGPL-3.0-or-later
 */

package docspell.logging.impl

import docspell.logging.impl.Record._

import io.circe.syntax._
import io.circe.{Encoder, Json}
import perfolation._
import scribe.LogRecord
import scribe.data.MDC
import scribe.message.Message

// From: https://github.com/outr/scribe/blob/8e99521e1ee1f0c421629764dd96e4eb193d84bd/json/shared/src/main/scala/scribe/json/JsonWriter.scala
// which would introduce jackson and other dependencies. Modified to work with circe.
// Original licensed under MIT.

private[impl] case class Record(
    level: String,
    levelValue: Double,
    message: String,
    additionalMessages: List[String],
    fileName: String,
    className: String,
    methodName: Option[String],
    line: Option[Int],
    column: Option[Int],
    data: Map[String, Json],
    traces: List[Trace],
    timeStamp: Long,
    date: String,
    time: String
)

private[impl] object Record {

  def fromLogRecord(record: LogRecord): Record = {
    val l = record.timeStamp
    val traces = record.messages.collect {
      case message: Message[_] if message.value.isInstanceOf[Throwable] =>
        throwable2Trace(message.value.asInstanceOf[Throwable])
    }
    val (firstMessage, additionalMessages) = record.messages match {
      case h :: rest =>
        (h.logOutput.plainText, rest.map(_.logOutput.plainText))
      case Nil =>
        ("", Nil)
    }

    Record(
      level = record.level.name,
      levelValue = record.levelValue,
      message = firstMessage,
      additionalMessages = additionalMessages,
      fileName = record.fileName,
      className = record.className,
      methodName = record.methodName,
      line = record.line,
      column = record.column,
      data = (record.data ++ MDC.map).map { case (key, value) =>
        value() match {
          case value: Json   => key -> value
          case value: Int    => key -> value.asJson
          case value: Long   => key -> value.asJson
          case value: Double => key -> value.asJson
          case any           => key -> Json.fromString(any.toString)
        }
      },
      traces = traces,
      timeStamp = l,
      date = l.t.F,
      time = s"${l.t.T}.${l.t.L}${l.t.z}"
    )
  }

  private def throwable2Trace(throwable: Throwable): Trace = {
    val elements = throwable.getStackTrace.toList.map { e =>
      TraceElement(e.getClassName, e.getMethodName, e.getLineNumber)
    }
    Trace(
      throwable.getLocalizedMessage,
      elements,
      Option(throwable.getCause).map(throwable2Trace)
    )
  }

  implicit val jsonEncoder: Encoder[Record] =
    Encoder.forProduct14(
      "level",
      "levelValue",
      "message",
      "additionalMessages",
      "fileName",
      "className",
      "methodName",
      "line",
      "column",
      "data",
      "traces",
      "timestamp",
      "date",
      "time"
    )(r => Record.unapply(r).get)

  case class Trace(message: String, elements: List[TraceElement], cause: Option[Trace])

  object Trace {
    implicit def jsonEncoder: Encoder[Trace] =
      Encoder.forProduct3("message", "elements", "cause")(r => Trace.unapply(r).get)

    implicit def openEncoder: Encoder[Option[Trace]] =
      Encoder.instance(opt => opt.map(jsonEncoder.apply).getOrElse(Json.Null))
  }

  case class TraceElement(`class`: String, method: String, line: Int)

  object TraceElement {
    implicit val jsonEncoder: Encoder[TraceElement] =
      Encoder.forProduct3("class", "method", "line")(r => TraceElement.unapply(r).get)
  }
}
