package docspell.website

import docspell.common.{IdRef, Ident, Timestamp}
import scodec.bits.ByteVector

import java.time.LocalDate
import scala.util.Random

trait Helper {

  def id(str: String): Ident = Ident.unsafe(str)

  val date20220514 = Timestamp.atUtc(LocalDate.of(2022, 5, 14).atTime(11, 22, 12))

  val cid = id("collective")

  implicit final class StringExt(self: String) {
    def id: Ident = Ident.unsafe(self)
  }

  def idRef(name: String): IdRef = IdRef(randomId, name)

  def randomId = {
    val buffer = Array.ofDim[Byte](6)
    new Random().nextBytes(buffer)
    id(ByteVector.view(buffer).toBase58)
  }

}
