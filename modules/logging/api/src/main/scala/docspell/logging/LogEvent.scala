/*
 * Copyright 2020 Eike K. & Contributors
 *
 * SPDX-License-Identifier: AGPL-3.0-or-later
 */

package docspell.logging

import io.circe.{Encoder, Json}
import sourcecode._

final case class LogEvent(
    level: Level,
    msg: () => String,
    additional: List[() => LogEvent.AdditionalMsg],
    data: Map[String, () => Json],
    pkg: Pkg,
    fileName: FileName,
    name: Name,
    line: Line
) {

  def asString =
    s"${level.name} ${name.value}/${fileName}:${line.value} - ${msg()}"

  def data[A: Encoder](key: String, value: => A): LogEvent =
    copy(data = data.updated(key, () => Encoder[A].apply(value)))

  def addData(m: Map[String, Json]): LogEvent =
    copy(data = data ++ m.view.mapValues(json => () => json).toMap)

  def addMessage(msg: => String): LogEvent =
    copy(additional = (() => Left(msg)) :: additional)

  def addError(ex: Throwable): LogEvent =
    copy(additional = (() => Right(ex)) :: additional)

  def findErrors: List[Throwable] =
    additional.map(a => a()).collect { case Right(ex) =>
      ex
    }
}

object LogEvent {

  type AdditionalMsg = Either[String, Throwable]

  def of(l: Level, m: => String)(implicit
      pkg: Pkg,
      fileName: FileName,
      name: Name,
      line: Line
  ): LogEvent = LogEvent(l, () => m, Nil, Map.empty, pkg, fileName, name, line)
}
