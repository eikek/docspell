package docspell.common

import io.circe._

sealed trait MetaProposalType { self: Product =>

  final def name: String =
    productPrefix.toLowerCase
}

object MetaProposalType {

  case object CorrOrg    extends MetaProposalType
  case object CorrPerson extends MetaProposalType
  case object ConcPerson extends MetaProposalType
  case object ConcEquip  extends MetaProposalType
  case object DocDate    extends MetaProposalType
  case object DueDate    extends MetaProposalType

  val all: List[MetaProposalType] =
    List(CorrOrg, CorrPerson, ConcPerson, ConcEquip)

  def fromString(str: String): Either[String, MetaProposalType] =
    str.toLowerCase match {
      case "corrorg"    => Right(CorrOrg)
      case "corrperson" => Right(CorrPerson)
      case "concperson" => Right(ConcPerson)
      case "concequip"  => Right(ConcEquip)
      case "docdate"    => Right(DocDate)
      case "duedate"    => Right(DueDate)
      case _            => Left(s"Invalid item-proposal-type: $str")
    }

  def unsafe(str: String): MetaProposalType =
    fromString(str).fold(sys.error, identity)

  implicit val jsonDecoder: Decoder[MetaProposalType] =
    Decoder.decodeString.emap(fromString)
  implicit val jsonEncoder: Encoder[MetaProposalType] =
    Encoder.encodeString.contramap(_.name)
}
