/*
 * Copyright 2020 Eike K. & Contributors
 *
 * SPDX-License-Identifier: AGPL-3.0-or-later
 */

package docspell.jsonminiq

import cats.Monoid
import cats.data.NonEmptyVector
import cats.implicits._

import io.circe.Decoder
import io.circe.Encoder
import io.circe.Json.Folder
import io.circe.{Json, JsonNumber, JsonObject}

/** Cteate a predicate for a Json value. */
sealed trait JsonMiniQuery { self =>

  def apply(json: Json): Vector[Json]

  def >>(next: JsonMiniQuery): JsonMiniQuery =
    JsonMiniQuery.Chain(self, next)

  def ++(other: JsonMiniQuery): JsonMiniQuery =
    JsonMiniQuery.Concat(NonEmptyVector.of(self, other))

  def thenAny(other: JsonMiniQuery, more: JsonMiniQuery*): JsonMiniQuery =
    self >> JsonMiniQuery.or(other, more: _*)

  def thenAll(other: JsonMiniQuery, more: JsonMiniQuery*): JsonMiniQuery =
    self >> JsonMiniQuery.and(other, more: _*)

  def at(field: String, fields: String*): JsonMiniQuery =
    self >> JsonMiniQuery.Fields(NonEmptyVector(field, fields.toVector))

  def at(index: Int, indexes: Int*): JsonMiniQuery =
    self >> JsonMiniQuery.Indexes(NonEmptyVector(index, indexes.toVector))

  def isAll(value: String, values: String*): JsonMiniQuery =
    self >> JsonMiniQuery.Filter(
      NonEmptyVector(value, values.toVector),
      JsonMiniQuery.MatchType.All
    )

  def isAny(value: String, values: String*): JsonMiniQuery =
    self >> JsonMiniQuery.Filter(
      NonEmptyVector(value, values.toVector),
      JsonMiniQuery.MatchType.Any
    )

  def is(value: String): JsonMiniQuery =
    isAny(value)

  def &&(other: JsonMiniQuery): JsonMiniQuery =
    JsonMiniQuery.and(self, other)

  def ||(other: JsonMiniQuery): JsonMiniQuery =
    self ++ other

  def matches(json: Json): Boolean =
    apply(json).nonEmpty

  def notMatches(json: Json): Boolean =
    !matches(json)

  /** Returns a string representation of this that can be parsed back to this value.
    * Formatting can fail, because not everything is supported. The idea is that every
    * value that was parsed, can be formatted.
    */
  def asString: Either[String, String] =
    Format(this)

  def unsafeAsString: String =
    asString.fold(sys.error, identity)
}

object JsonMiniQuery {

  def parse(str: String): Either[String, JsonMiniQuery] =
    Parser.query
      .parseAll(str)
      .leftMap(err =>
        s"Unexpected input at ${err.failedAtOffset}. Expected: ${err.expected.toList.mkString(", ")}"
      )

  def unsafeParse(str: String): JsonMiniQuery =
    parse(str).fold(sys.error, identity)

  val root: JsonMiniQuery = Identity
  val id: JsonMiniQuery = Identity
  val none: JsonMiniQuery = Empty

  def and(self: JsonMiniQuery, more: JsonMiniQuery*): JsonMiniQuery =
    Forall(NonEmptyVector(self, more.toVector))

  def or(self: JsonMiniQuery, more: JsonMiniQuery*): JsonMiniQuery =
    Concat(NonEmptyVector(self, more.toVector))

  // --- impl

  case object Identity extends JsonMiniQuery {
    def apply(json: Json) = Vector(json)
    override def >>(next: JsonMiniQuery): JsonMiniQuery = next
  }

  case object Empty extends JsonMiniQuery {
    def apply(json: Json) = Vector.empty
    override def at(field: String, fields: String*): JsonMiniQuery = this
    override def at(field: Int, fields: Int*): JsonMiniQuery = this
    override def isAll(value: String, values: String*) = this
    override def isAny(value: String, values: String*) = this
    override def >>(next: JsonMiniQuery): JsonMiniQuery = this
    override def ++(other: JsonMiniQuery): JsonMiniQuery = other
  }

  private def unwrapArrays(json: Vector[Json]): Vector[Json] =
    json.foldLeft(Vector.empty[Json]) { (res, el) =>
      el.asArray.map(x => res ++ x).getOrElse(res :+ el)
    }

  final case class Fields(names: NonEmptyVector[String]) extends JsonMiniQuery {
    def apply(json: Json) = json.foldWith(folder)

    private val folder: Folder[Vector[Json]] = new Folder[Vector[Json]] {
      def onNull = Vector.empty
      def onBoolean(value: Boolean) = Vector.empty
      def onNumber(value: JsonNumber) = Vector.empty
      def onString(value: String) = Vector.empty
      def onArray(value: Vector[Json]) =
        unwrapArrays(value.flatMap(inner => inner.foldWith(this)))
      def onObject(value: JsonObject) =
        unwrapArrays(names.toVector.flatMap(value.apply))
    }
  }
  final case class Indexes(indexes: NonEmptyVector[Int]) extends JsonMiniQuery {
    def apply(json: Json) = json.foldWith(folder)

    private val folder: Folder[Vector[Json]] = new Folder[Vector[Json]] {
      def onNull = Vector.empty
      def onBoolean(value: Boolean) = Vector.empty
      def onNumber(value: JsonNumber) = Vector.empty
      def onString(value: String) = Vector.empty
      def onArray(value: Vector[Json]) =
        unwrapArrays(indexes.toVector.flatMap(i => value.get(i.toLong)))
      def onObject(value: JsonObject) =
        Vector.empty
    }
  }

  sealed trait MatchType {
    def monoid: Monoid[Boolean]
  }
  object MatchType {
    case object Any extends MatchType {
      val monoid = Monoid.instance(false, _ || _)
    }
    case object All extends MatchType {
      val monoid = Monoid.instance(true, _ && _)
    }
    case object None extends MatchType { // = not Any
      val monoid = Monoid.instance(true, _ && !_)
    }
  }

  final case class Filter(
      values: NonEmptyVector[String],
      combine: MatchType
  ) extends JsonMiniQuery {
    def apply(json: Json): Vector[Json] =
      json.asArray match {
        case Some(arr) =>
          unwrapArrays(arr.filter(el => el.foldWith(folder(combine))))
        case None =>
          if (json.foldWith(folder(combine))) unwrapArrays(Vector(json))
          else Vector.empty
      }

    private val anyMatch = folder(MatchType.Any)

    private def folder(matchType: MatchType): Folder[Boolean] = new Folder[Boolean] {
      def onNull =
        onString("*null*")

      def onBoolean(value: Boolean) =
        values
          .map(_.equalsIgnoreCase(value.toString))
          .fold(matchType.monoid)

      def onNumber(value: JsonNumber) =
        values
          .map(
            _.equalsIgnoreCase(
              value.toLong.map(_.toString).getOrElse(value.toDouble.toString)
            )
          )
          .fold(matchType.monoid)

      def onString(value: String) =
        values
          .map(_.equalsIgnoreCase(value))
          .fold(matchType.monoid)

      def onArray(value: Vector[Json]) =
        value
          .map(inner => inner.foldWith(anyMatch))
          .fold(matchType.monoid.empty)(matchType.monoid.combine)

      def onObject(value: JsonObject) = false
    }
  }

  final case class Chain(self: JsonMiniQuery, next: JsonMiniQuery) extends JsonMiniQuery {
    def apply(json: Json): Vector[Json] =
      next(Json.fromValues(self(json)))
  }

  final case class Concat(qs: NonEmptyVector[JsonMiniQuery]) extends JsonMiniQuery {
    def apply(json: Json): Vector[Json] =
      qs.toVector.flatMap(_.apply(json))
  }

  final case class Forall(qs: NonEmptyVector[JsonMiniQuery]) extends JsonMiniQuery {
    def apply(json: Json): Vector[Json] =
      combineWhenNonEmpty(qs.toVector.map(_.apply(json)), Vector.empty)

    @annotation.tailrec
    private def combineWhenNonEmpty(
        values: Vector[Vector[Json]],
        result: Vector[Json]
    ): Vector[Json] =
      values.headOption match {
        case Some(v) if v.nonEmpty => combineWhenNonEmpty(values.tail, result ++ v)
        case Some(_)               => Vector.empty
        case None                  => result
      }
  }

  implicit val jsonDecoder: Decoder[JsonMiniQuery] =
    Decoder.decodeString.emap(parse)

  implicit val jsonEncoder: Encoder[JsonMiniQuery] =
    Encoder.encodeString.contramap(_.unsafeAsString)
}
