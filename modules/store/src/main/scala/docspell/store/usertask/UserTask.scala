/*
 * Copyright 2020 Docspell Contributors
 *
 * SPDX-License-Identifier: GPL-3.0-or-later
 */

package docspell.store.usertask

import cats.effect._
import cats.implicits._

import docspell.common._
import docspell.common.syntax.all._
import docspell.store.records.RPeriodicTask

import com.github.eikek.calev.CalEvent
import io.circe.Decoder
import io.circe.Encoder

case class UserTask[A](
    id: Ident,
    name: Ident,
    enabled: Boolean,
    timer: CalEvent,
    summary: Option[String],
    args: A
) {

  def encode(implicit E: Encoder[A]): UserTask[String] =
    copy(args = E(args).noSpaces)

}

object UserTask {

  implicit final class UserTaskCodec(ut: UserTask[String]) {

    def decode[A](implicit D: Decoder[A]): Either[String, UserTask[A]] =
      ut.args
        .parseJsonAs[A]
        .left
        .map(_.getMessage)
        .map(a => ut.copy(args = a))

    def toPeriodicTask[F[_]: Sync](
        scope: UserTaskScope
    ): F[RPeriodicTask] =
      RPeriodicTask
        .create[F](
          ut.enabled,
          scope,
          ut.name,
          ut.args,
          s"${scope.fold(_.user.id, _.id)}: ${ut.name.id}",
          Priority.Low,
          ut.timer,
          ut.summary
        )
        .map(r => r.copy(id = ut.id))
  }
}
