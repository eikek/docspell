/*
 * Copyright 2020 Eike K. & Contributors
 *
 * SPDX-License-Identifier: AGPL-3.0-or-later
 */

package docspell.config

import cats._
import cats.data.{NonEmptyChain, Validated, ValidatedNec}
import cats.implicits._

final case class Validation[C](run: C => ValidatedNec[String, C]) {

  def validOrThrow(c: C): C =
    run(c) match {
      case Validated.Valid(cfg) => cfg
      case Validated.Invalid(errs) =>
        val msg = errs.toList.mkString("- ", "\n- ", "\n")
        throw sys.error(s"\n\n$msg")
    }

  def andThen(next: Validation[C]): Validation[C] =
    Validation(c =>
      run(c) match {
        case Validated.Valid(c2) => next.run(c2)
        case f: Validated.Invalid[NonEmptyChain[String]] =>
          next.run(c) match {
            case Validated.Valid(_) => f
            case Validated.Invalid(errs2) =>
              Validation.invalid(f.e ++ errs2)
          }
      }
    )
}

object Validation {

  def flatten[C](run: C => Validation[C]): Validation[C] =
    Validation(c => run(c).run(c))

  def failWhen[C](isInvalid: C => Boolean, msg: => String): Validation[C] =
    Validation(c => if (isInvalid(c)) invalid(msg) else valid(c))

  def okWhen[C](isValid: C => Boolean, msg: => String): Validation[C] =
    Validation(c => if (isValid(c)) valid(c) else invalid(msg))

  def valid[C](c: C): ValidatedNec[String, C] =
    Validated.validNec(c)

  def invalid[C](msgs: NonEmptyChain[String]): ValidatedNec[String, C] =
    Validated.Invalid(msgs)

  def invalid[C](msg: String, msgs: String*): ValidatedNec[String, C] =
    Validated.Invalid(NonEmptyChain(msg, msgs: _*))

  def asValid[C]: Validation[C] =
    Validation(c => valid(c))

  def insert[C](c: C): Validation[C] =
    Validation(_ => valid(c))

  def error[C](msg: String, msgs: String*): Validation[C] =
    Validation(_ => invalid(msg, msgs: _*))

  implicit def validationMonoid[C]: Monoid[Validation[C]] =
    Monoid.instance(asValid, (v1, v2) => v1.andThen(v2))

  def of[C](v1: Validation[C], vn: Validation[C]*): Validation[C] =
    Monoid[Validation[C]].combineAll(v1 :: vn.toList)
}
