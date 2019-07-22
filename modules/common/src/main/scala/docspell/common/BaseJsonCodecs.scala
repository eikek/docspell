package docspell.common

import java.time.Instant

import io.circe._

object BaseJsonCodecs {

  implicit val encodeInstantEpoch: Encoder[Instant] =
    Encoder.encodeJavaLong.contramap(_.toEpochMilli)

  implicit val decodeInstantEpoch: Decoder[Instant] =
    Decoder.decodeLong.map(Instant.ofEpochMilli)


}
