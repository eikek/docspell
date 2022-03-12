/*
 * Copyright 2020 Eike K. & Contributors
 *
 * SPDX-License-Identifier: AGPL-3.0-or-later
 */

package docspell.scheduler

import docspell.scheduler.JobTaskResultEncoder.instance

import io.circe.Encoder

trait JobTaskResultEncoder[A] { self =>
  def encode(a: A): JobTaskResult

  final def contramap[B](f: B => A): JobTaskResultEncoder[B] =
    JobTaskResultEncoder.instance(b => self.encode(f(b)))

  final def map(f: JobTaskResult => JobTaskResult): JobTaskResultEncoder[A] =
    instance(a => f(self.encode(a)))

  final def modify(f: (A, JobTaskResult) => JobTaskResult): JobTaskResultEncoder[A] =
    instance(a => f(a, self.encode(a)))

  final def withMessage(f: A => String): JobTaskResultEncoder[A] =
    modify((a, r) => r.withMessage(f(a)))
}

object JobTaskResultEncoder {

  def apply[A](implicit v: JobTaskResultEncoder[A]): JobTaskResultEncoder[A] = v

  def instance[A](f: A => JobTaskResult): JobTaskResultEncoder[A] =
    (a: A) => f(a)

  def fromJson[A: Encoder]: JobTaskResultEncoder[A] =
    instance(a => JobTaskResult.json(Encoder[A].apply(a)))

  implicit val unitJobTaskResultEncoder: JobTaskResultEncoder[Unit] =
    instance(_ => JobTaskResult.empty)

  implicit def optionJobTaskResultEncoder[A](implicit
      ea: JobTaskResultEncoder[A]
  ): JobTaskResultEncoder[Option[A]] =
    instance {
      case Some(a) => ea.encode(a)
      case None    => JobTaskResult.empty
    }
}
