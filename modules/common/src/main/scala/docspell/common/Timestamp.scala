package docspell.common

import java.time.{Instant, LocalDate, ZoneId}

import cats.effect.Sync
import io.circe.{Decoder, Encoder}
import java.time.LocalDateTime
import java.time.ZonedDateTime

case class Timestamp(value: Instant) {

  def toMillis: Long = value.toEpochMilli

  def toSeconds: Long = value.toEpochMilli / 1000L

  def minus(d: Duration): Timestamp =
    Timestamp(value.minusNanos(d.nanos))

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
}

object Timestamp {
  val UTC = ZoneId.of("UTC")

  val Epoch = Timestamp(Instant.EPOCH)

  def current[F[_]: Sync]: F[Timestamp] =
    Sync[F].delay(Timestamp(Instant.now))

  def from(zd: ZonedDateTime): Timestamp =
    Timestamp(zd.toInstant)

  implicit val encodeTimestamp: Encoder[Timestamp] =
    BaseJsonCodecs.encodeInstantEpoch.contramap(_.value)

  implicit val decodeTimestamp: Decoder[Timestamp] =
    BaseJsonCodecs.decodeInstantEpoch.map(Timestamp(_))

}
