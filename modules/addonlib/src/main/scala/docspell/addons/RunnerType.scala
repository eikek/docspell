/*
 * Copyright 2020 Eike K. & Contributors
 *
 * SPDX-License-Identifier: AGPL-3.0-or-later
 */

package docspell.addons

import cats.data.NonEmptyList
import cats.syntax.all._

import io.circe.{Decoder, Encoder}

sealed trait RunnerType {
  def name: String

  def fold[A](
      nixFlake: => A,
      docker: => A,
      trivial: => A
  ): A
}
object RunnerType {
  case object NixFlake extends RunnerType {
    val name = "nix-flake"

    def fold[A](
        nixFlake: => A,
        docker: => A,
        trivial: => A
    ): A = nixFlake
  }
  case object Docker extends RunnerType {
    val name = "docker"

    def fold[A](
        nixFlake: => A,
        docker: => A,
        trivial: => A
    ): A = docker
  }
  case object Trivial extends RunnerType {
    val name = "trivial"

    def fold[A](
        nixFlake: => A,
        docker: => A,
        trivial: => A
    ): A = trivial
  }

  val all: NonEmptyList[RunnerType] =
    NonEmptyList.of(NixFlake, Docker, Trivial)

  def fromString(str: String): Either[String, RunnerType] =
    all.find(_.name.equalsIgnoreCase(str)).toRight(s"Invalid runner value: $str")

  def unsafeFromString(str: String): RunnerType =
    fromString(str).fold(sys.error, identity)

  def fromSeparatedString(str: String): Either[String, List[RunnerType]] =
    str.split("[\\s,]+").toList.map(_.trim).traverse(fromString)

  implicit val jsonDecoder: Decoder[RunnerType] =
    Decoder[String].emap(RunnerType.fromString)

  implicit val jsonEncoder: Encoder[RunnerType] =
    Encoder[String].contramap(_.name)
}
