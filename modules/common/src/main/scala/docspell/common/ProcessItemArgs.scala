package docspell.common

import io.circe._, io.circe.generic.semiauto._
import docspell.common.syntax.all._
import ProcessItemArgs._

case class ProcessItemArgs(meta: ProcessMeta, files: List[File]) {

  def makeSubject: String = {
    files.flatMap(_.name) match {
      case Nil => s"${meta.sourceAbbrev}: No files"
      case n :: Nil => n
      case n1 :: n2 :: Nil => s"$n1, $n2"
      case more => s"${files.size} files from ${meta.sourceAbbrev}"
    }
  }

}

object ProcessItemArgs {

  val taskName = Ident.unsafe("process-item")

  case class ProcessMeta( collective: Ident
                        , language: Language
                        , direction: Option[Direction]
                        , sourceAbbrev: String
                        , validFileTypes: Seq[MimeType])

  object ProcessMeta {
    implicit val jsonEncoder: Encoder[ProcessMeta] = deriveEncoder[ProcessMeta]
    implicit val jsonDecoder: Decoder[ProcessMeta] = deriveDecoder[ProcessMeta]
  }

  case class File(name: Option[String], fileMetaId: Ident)
  object File {
    implicit val jsonEncoder: Encoder[File] = deriveEncoder[File]
    implicit val jsonDecoder: Decoder[File] = deriveDecoder[File]
  }

  implicit val jsonEncoder: Encoder[ProcessItemArgs] = deriveEncoder[ProcessItemArgs]
  implicit val jsonDecoder: Decoder[ProcessItemArgs] = deriveDecoder[ProcessItemArgs]

  def parse(str: String): Either[Throwable, ProcessItemArgs] =
    str.parseJsonAs[ProcessItemArgs]

}
