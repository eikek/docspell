/*
 * Copyright 2020 Eike K. & Contributors
 *
 * SPDX-License-Identifier: AGPL-3.0-or-later
 */

package docspell.store.impl

import java.time.format.DateTimeFormatter
import java.time.{Instant, LocalDate}

import docspell.common._
import docspell.common.syntax.all._
import docspell.jsonminiq.JsonMiniQuery
import docspell.notification.api.{ChannelType, EventType}
import docspell.query.{ItemQuery, ItemQueryParser}
import docspell.totp.Key

import com.github.eikek.calev.CalEvent
import doobie._
import doobie.implicits.legacy.instant._
import doobie.util.log.Success
import emil.doobie.EmilDoobieMeta
import io.circe.Json
import io.circe.{Decoder, Encoder}
import scodec.bits.ByteVector

trait DoobieMeta extends EmilDoobieMeta {

  implicit val sqlLogging = LogHandler {
    case e @ Success(_, _, _, _) =>
      DoobieMeta.logger.trace("SQL " + e)
    case e =>
      DoobieMeta.logger.error(s"SQL Failure: $e")
  }

  def jsonMeta[A](implicit d: Decoder[A], e: Encoder[A]): Meta[A] =
    Meta[String].imap(str => str.parseJsonAs[A].fold(ex => throw ex, identity))(a =>
      e.apply(a).noSpaces
    )

  implicit val metaAccountSource: Meta[AccountSource] =
    Meta[String].imap(AccountSource.unsafeFromString)(_.name)

  implicit val metaDuration: Meta[Duration] =
    Meta[Long].imap(Duration.millis)(_.millis)

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

  implicit val metaIdRef: Meta[List[IdRef]] =
    jsonMeta[List[IdRef]]

  implicit val metaLanguage: Meta[Language] =
    Meta[String].imap(Language.unsafe)(_.iso3)

  implicit val metaCalEvent: Meta[CalEvent] =
    Meta[String].timap(CalEvent.unsafe)(_.asString)

  implicit val metaGlob: Meta[Glob] =
    Meta[String].timap(Glob.apply)(_.asString)

  implicit val metaCustomFieldType: Meta[CustomFieldType] =
    Meta[String].timap(CustomFieldType.unsafe)(_.name)

  implicit val metaListType: Meta[ListType] =
    Meta[String].timap(ListType.unsafeFromString)(_.name)

  implicit val metaPersonUse: Meta[PersonUse] =
    Meta[String].timap(PersonUse.unsafeFromString)(_.name)

  implicit val metaEquipUse: Meta[EquipmentUse] =
    Meta[String].timap(EquipmentUse.unsafeFromString)(_.name)

  implicit val metaOrgUse: Meta[OrgUse] =
    Meta[String].timap(OrgUse.unsafeFromString)(_.name)

  implicit val metaJsonString: Meta[Json] =
    Meta[String].timap(DoobieMeta.parseJsonUnsafe)(_.noSpaces)

  implicit val metaKey: Meta[Key] =
    Meta[String].timap(Key.unsafeFromString)(_.asString)

  implicit val metaMimeType: Meta[MimeType] =
    Meta[String].timap(MimeType.unsafe)(_.asString)

  implicit val metaByteVectorHex: Meta[ByteVector] =
    Meta[String].timap(s => ByteVector.fromValidHex(s))(_.toHex)

  implicit val metaByteSize: Meta[ByteSize] =
    Meta[Long].timap(ByteSize.apply)(_.bytes)

  implicit val metaItemQuery: Meta[ItemQuery] =
    Meta[String].timap(s => ItemQueryParser.parseUnsafe(s))(q =>
      q.raw.getOrElse(ItemQueryParser.unsafeAsString(q.expr))
    )

  implicit val metaEventType: Meta[EventType] =
    Meta[String].timap(EventType.unsafeFromString)(_.name)

  implicit val metaJsonMiniQuery: Meta[JsonMiniQuery] =
    Meta[String].timap(JsonMiniQuery.unsafeParse)(_.unsafeAsString)

  implicit val channelTypeRead: Read[ChannelType] =
    Read[String].map(ChannelType.unsafeFromString)
}

object DoobieMeta extends DoobieMeta {
  import org.log4s._
  private val logger = getLogger

  private def parseJsonUnsafe(str: String): Json =
    io.circe.parser
      .parse(str)
      .fold(throw _, identity)

}
