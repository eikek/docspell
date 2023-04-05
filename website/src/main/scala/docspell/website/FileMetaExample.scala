package docspell.website

import cats.syntax.option._
import docspell.common.{ByteSize, Language, MimeType}
import docspell.store.queries.AttachedFile
import io.circe.syntax._
import scodec.bits.ByteVector

object FileMetaExample extends Helper {

  val example1 = AttachedFile(
    id = randomId,
    name = "the filename.png".some,
    position = 0,
    language = Language.English.some,
    mimetype = MimeType.png,
    length = ByteSize(454654L),
    checksum = ByteVector.fromValidHex("caffe0caffe").digest("SHA-256")
  )

  val example2 = AttachedFile(
    id = randomId,
    name = "other filename.png".some,
    position = 1,
    language = Language.English.some,
    mimetype = MimeType.pdf,
    length = ByteSize(1232214L),
    checksum = ByteVector.fromValidHex("eff0eff0eff").digest("SHA-256")
  )

  val example = List(
    example1,
    example2
  )

  val exampleJson = example.asJson.spaces2
}
