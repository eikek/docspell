/*
 * Copyright 2020 Eike K. & Contributors
 *
 * SPDX-License-Identifier: AGPL-3.0-or-later
 */

package docspell.jsonminiq

import cats.implicits._

/** The inverse to Parser */
private[jsonminiq] object Format {

  def apply(q: JsonMiniQuery): Either[String, String] =
    q match {
      case JsonMiniQuery.Empty    => Right("")
      case JsonMiniQuery.Identity => Right("")
      case JsonMiniQuery.Fields(fields) =>
        Right(fields.toVector.mkString(","))

      case JsonMiniQuery.Indexes(nums) =>
        Right(nums.toVector.mkString("(", ",", ")"))

      case JsonMiniQuery.Filter(values, mt) =>
        formatValue(values.head).map(v => formatMatchType(mt) + v)

      case JsonMiniQuery.Chain(self, next) =>
        for {
          s1 <- apply(self)
          s2 <- apply(next)
          res = next match {
            case _: JsonMiniQuery.Fields =>
              s1 + "." + s2
            case _ =>
              s1 + s2
          }
        } yield res

      case JsonMiniQuery.Concat(inner) =>
        inner.toVector.traverse(apply).map(_.mkString("[", " | ", "]"))

      case JsonMiniQuery.Forall(inner) =>
        inner.toVector.traverse(apply).map(_.mkString("[", " & ", "]"))
    }

  def formatValue(v: String): Either[String, String] =
    if (v.forall(Parser.isValidSimpleValue)) Right(v)
    else if (v.contains("\"") && v.contains("'"))
      Left(s"Value cannot use both \" and ': $v")
    else if (v.contains("'")) Right(s"\"$v\"")
    else Right(s"'$v'")

  def formatMatchType(matchType: JsonMiniQuery.MatchType): String =
    matchType match {
      case JsonMiniQuery.MatchType.All  => "="
      case JsonMiniQuery.MatchType.Any  => ":"
      case JsonMiniQuery.MatchType.None => "!"
    }
}
