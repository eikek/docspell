package docspell.ftsclient

import cats.data.NonEmptyList
import cats.implicits._
import docspell.common._

import FtsBasicResult.AttachmentMatch

final case class FtsBasicResult(item: Ident, attachments: NonEmptyList[AttachmentMatch]) {

  def score: Double =
    attachments.map(_.score).toList.max
}

object FtsBasicResult {

  case class AttachmentMatch(id: Ident, score: Double)

}
