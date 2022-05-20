/*
 * Copyright 2020 Eike K. & Contributors
 *
 * SPDX-License-Identifier: AGPL-3.0-or-later
 */

package docspell.addons

import cats.Monoid

import docspell.addons.out.AddonOutput

import io.circe.generic.extras.Configuration
import io.circe.generic.extras.semiauto.{deriveConfiguredDecoder, deriveConfiguredEncoder}
import io.circe.generic.semiauto.{deriveDecoder, deriveEncoder}
import io.circe.{Codec, Decoder, Encoder}

sealed trait AddonResult {
  def toEither: Either[Throwable, AddonOutput]

  def isSuccess: Boolean = toEither.isRight
  def isFailure: Boolean = !isSuccess

  def cast: AddonResult = this
}

object AddonResult {
  val emptySuccess: AddonResult = success(AddonOutput.empty)

  /** The addon was run successful, but decoding its stdout failed. */
  case class DecodingError(message: String) extends AddonResult {
    def toEither = Left(new IllegalStateException(message))
  }
  object DecodingError {
    implicit val jsonEncoder: Encoder[DecodingError] = deriveEncoder
    implicit val jsonDecoder: Decoder[DecodingError] = deriveDecoder
  }

  def decodingError(message: String): AddonResult =
    DecodingError(message)

  def decodingError(ex: Throwable): AddonResult =
    DecodingError(ex.getMessage)

  /** Running the addon resulted in an invalid return code (!= 0). */
  case class ExecutionError(rc: Int) extends AddonResult {
    def toEither = Left(new IllegalStateException(s"Exit code: $rc"))
  }

  object ExecutionError {
    implicit val jsonEncoder: Encoder[ExecutionError] = deriveEncoder
    implicit val jsonDecoder: Decoder[ExecutionError] = deriveDecoder
  }

  def executionError(rc: Int): AddonResult =
    ExecutionError(rc)

  /** The execution of the addon failed with an exception. */
  case class ExecutionFailed(error: Throwable) extends AddonResult {
    def toEither = Left(error)
  }

  object ExecutionFailed {
    implicit val throwableCodec: Codec[Throwable] =
      Codec.from(
        Decoder[String].emap(str => Right(ErrorMessageThrowable(str))),
        Encoder[String].contramap(_.getMessage)
      )

    implicit val jsonEncoder: Encoder[ExecutionFailed] = deriveEncoder
    implicit val jsonDecoder: Decoder[ExecutionFailed] = deriveDecoder

    private class ErrorMessageThrowable(msg: String) extends RuntimeException(msg) {
      override def fillInStackTrace() = this
    }
    private object ErrorMessageThrowable {
      def apply(str: String): Throwable = new ErrorMessageThrowable(str)
    }
  }

  def executionFailed(error: Throwable): AddonResult =
    ExecutionFailed(error)

  /** The addon was run successfully and its output was decoded (if any). */
  case class Success(output: AddonOutput) extends AddonResult {
    def toEither = Right(output)
  }

  object Success {
    implicit val jsonEncoder: Encoder[Success] = deriveEncoder
    implicit val jsonDecoder: Decoder[Success] = deriveDecoder
  }

  def success(output: AddonOutput): AddonResult =
    Success(output)

  val empty: AddonResult = Success(AddonOutput.empty)

  def combine(a: AddonResult, b: AddonResult): AddonResult =
    (a, b) match {
      case (Success(o1), Success(o2)) => Success(AddonOutput.combine(o1, o2))
      case (Success(_), e)            => e
      case (e, Success(_))            => e
      case _                          => a
    }

  implicit val deriveConfig: Configuration =
    Configuration.default.withDiscriminator("result").withKebabCaseConstructorNames

  implicit val jsonDecoder: Decoder[AddonResult] = deriveConfiguredDecoder
  implicit val jsonEncoder: Encoder[AddonResult] = deriveConfiguredEncoder

  implicit val addonResultMonoid: Monoid[AddonResult] =
    Monoid.instance(empty, combine)
}
