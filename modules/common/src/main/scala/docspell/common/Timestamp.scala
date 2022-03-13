/*
 * Copyright 2020 Eike K. & Contributors
 *
 * SPDX-License-Identifier: AGPL-3.0-or-later
 */

package docspell.common

import java.time.temporal.ChronoUnit
import java.time.{Duration => _, _}

import cats.effect.Sync

import io.circe.{Decoder, Encoder}

case class Timestamp(value: Instant) {

  def toMillis: Long = value.toEpochMilli

  def toSeconds: Long = value.toEpochMilli / 1000L

  def minus(d: Duration): Timestamp =
    Timestamp(value.minusNanos(d.nanos))

  def -(d: Duration): Timestamp =
    minus(d)

  def +(d: Duration): Timestamp =
    plus(d)

  def plus(d: Duration): Timestamp =
    Timestamp(value.plusNanos(d.nanos))

  def minusHours(n: Long): Timestamp =
    Timestamp(value.minusSeconds(n * 60 * 60))

  def toUtcDate: LocalDate =
    value.atZone(Timestamp.UTC).toLocalDate

  def toUtcDateTime: LocalDateTime =
    value.atZone(Timestamp.UTC).toLocalDateTime

  def atZone(zone: ZoneId): ZonedDateTime =
    value.atZone(zone)

  def atUTC: ZonedDateTime = atZone(Timestamp.UTC)

  def asString: String = value.toString

  def <(other: Timestamp): Boolean =
    this.value.isBefore(other.value)

  def >(other: Timestamp): Boolean =
    this.value.isAfter(other.value)
}

object Timestamp {
  val UTC: ZoneId = ZoneOffset.UTC

  val Epoch = Timestamp(Instant.EPOCH)

  def current[F[_]: Sync]: F[Timestamp] =
    Sync[F].delay(Timestamp(Instant.now))

  def from(zd: ZonedDateTime): Timestamp =
    Timestamp(zd.toInstant)

  def atUtc(ldt: LocalDateTime): Timestamp =
    from(ldt.atZone(UTC))

  def ofMillis(ms: Long): Timestamp =
    Timestamp(Instant.ofEpochMilli(ms))

  def daysBetween(ts0: Timestamp, ts1: Timestamp): Long =
    ChronoUnit.DAYS.between(ts0.toUtcDate, ts1.toUtcDate)

  implicit val encodeTimestamp: Encoder[Timestamp] =
    BaseJsonCodecs.encodeInstantEpoch.contramap(_.value)

  implicit val decodeTimestamp: Decoder[Timestamp] =
    BaseJsonCodecs.decodeInstantEpoch.map(Timestamp(_))

  implicit val ordering: Ordering[Timestamp] =
    Ordering.by(_.value)
}
