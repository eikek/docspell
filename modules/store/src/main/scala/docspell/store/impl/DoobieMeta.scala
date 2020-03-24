package docspell.store.impl

import java.time.format.DateTimeFormatter
import java.time.{Instant, LocalDate}
import io.circe.{Decoder, Encoder}
import doobie._
import doobie.implicits.legacy.instant._
import doobie.util.log.Success
import emil.doobie.EmilDoobieMeta
import com.github.eikek.calev.CalEvent

import docspell.common._
import docspell.common.syntax.all._

trait DoobieMeta extends EmilDoobieMeta {

  implicit val sqlLogging = LogHandler({
    case e @ Success(_, _, _, _) =>
      DoobieMeta.logger.trace("SQL " + e)
    case e =>
      DoobieMeta.logger.error(s"SQL Failure: $e")
  })

  def jsonMeta[A](implicit d: Decoder[A], e: Encoder[A]): Meta[A] =
    Meta[String].imap(str => str.parseJsonAs[A].fold(ex => throw ex, identity))(a =>
      e.apply(a).noSpaces
    )

  implicit val metaCollectiveState: Meta[CollectiveState] =
    Meta[String].imap(CollectiveState.unsafe)(CollectiveState.asString)

  implicit val metaUserState: Meta[UserState] =
    Meta[String].imap(UserState.unsafe)(UserState.asString)

  implicit val metaPassword: Meta[Password] =
    Meta[String].imap(Password(_))(_.pass)

  implicit val metaIdent: Meta[Ident] =
    Meta[String].imap(Ident.unsafe)(_.id)

  implicit val metaContactKind: Meta[ContactKind] =
    Meta[String].imap(ContactKind.unsafe)(_.asString)

  implicit val metaTimestamp: Meta[Timestamp] =
    Meta[Instant].imap(Timestamp(_))(_.value)

  implicit val metaJobState: Meta[JobState] =
    Meta[String].imap(JobState.unsafe)(_.name)

  implicit val metaDirection: Meta[Direction] =
    Meta[Boolean].imap(flag =>
      if (flag) Direction.Incoming: Direction else Direction.Outgoing: Direction
    )(d => Direction.isIncoming(d))

  implicit val metaPriority: Meta[Priority] =
    Meta[Int].imap(Priority.fromInt)(Priority.toInt)

  implicit val metaLogLevel: Meta[LogLevel] =
    Meta[String].imap(LogLevel.unsafeString)(_.name)

  implicit val metaLenientUri: Meta[LenientUri] =
    Meta[String].imap(LenientUri.unsafe)(_.asString)

  implicit val metaNodeType: Meta[NodeType] =
    Meta[String].imap(NodeType.unsafe)(_.name)

  implicit val metaLocalDate: Meta[LocalDate] =
    Meta[String].imap(str => LocalDate.parse(str))(_.format(DateTimeFormatter.ISO_DATE))

  implicit val metaItemState: Meta[ItemState] =
    Meta[String].imap(ItemState.unsafe)(_.name)

  implicit val metNerTag: Meta[NerTag] =
    Meta[String].imap(NerTag.unsafe)(_.name)

  implicit val metaNerLabel: Meta[NerLabel] =
    jsonMeta[NerLabel]

  implicit val metaNerLabelList: Meta[List[NerLabel]] =
    jsonMeta[List[NerLabel]]

  implicit val metaItemProposal: Meta[MetaProposal] =
    jsonMeta[MetaProposal]

  implicit val metaItemProposalList: Meta[MetaProposalList] =
    jsonMeta[MetaProposalList]

  implicit val metaLanguage: Meta[Language] =
    Meta[String].imap(Language.unsafe)(_.iso3)


  implicit val metaCalEvent: Meta[CalEvent] =
    Meta[String].timap(CalEvent.unsafe)(_.asString)
}

object DoobieMeta extends DoobieMeta {
  import org.log4s._
  private val logger = getLogger

}
