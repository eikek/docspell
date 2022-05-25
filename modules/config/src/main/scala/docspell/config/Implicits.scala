/*
 * Copyright 2020 Eike K. & Contributors
 *
 * SPDX-License-Identifier: AGPL-3.0-or-later
 */

package docspell.config

import java.nio.file.{Path => JPath}

import scala.reflect.ClassTag

import cats.syntax.all._
import fs2.io.file.Path

import docspell.addons.RunnerType
import docspell.common._
import docspell.ftspsql.{PgQueryParser, RankNormalization}
import docspell.logging.{Level, LogConfig}

import com.github.eikek.calev.CalEvent
import pureconfig.ConfigReader
import pureconfig.error.{CannotConvert, FailureReason}
import pureconfig.generic.{CoproductHint, FieldCoproductHint}
import scodec.bits.ByteVector

object Implicits {
  // the value "s-3" looks strange, this is to allow to write "s3" in the config
  implicit val fileStoreCoproductHint: CoproductHint[FileStoreConfig] =
    new FieldCoproductHint[FileStoreConfig]("type") {
      override def fieldValue(name: String) =
        if (name.equalsIgnoreCase("S3")) "s3"
        else super.fieldValue(name)
    }

  implicit val urlMatcherReader: ConfigReader[UrlMatcher] = {
    val fromList = ConfigReader[List[String]].emap(reason(UrlMatcher.fromStringList))
    val fromString = ConfigReader[String].emap(
      reason(str => UrlMatcher.fromStringList(str.split("[\\s,]+").toList))
    )
    fromList.orElse(fromString)
  }

  implicit val runnerSelectReader: ConfigReader[List[RunnerType]] =
    ConfigReader[String].emap(reason(RunnerType.fromSeparatedString))

  implicit val accountIdReader: ConfigReader[AccountId] =
    ConfigReader[String].emap(reason(AccountId.parse))

  implicit val pathReader: ConfigReader[Path] =
    ConfigReader[JPath].map(Path.fromNioPath)

  implicit val lenientUriReader: ConfigReader[LenientUri] =
    ConfigReader[String].emap(reason(LenientUri.parse))

  implicit val durationReader: ConfigReader[Duration] =
    ConfigReader[scala.concurrent.duration.Duration].map(sd => Duration(sd))

  implicit val passwordReader: ConfigReader[Password] =
    ConfigReader[String].map(Password(_))

  implicit val mimeTypeReader: ConfigReader[MimeType] =
    ConfigReader[String].emap(reason(MimeType.parse))

  implicit val identReader: ConfigReader[Ident] =
    ConfigReader[String].emap(reason(Ident.fromString))

  implicit def identMapReader[B: ConfigReader]: ConfigReader[Map[Ident, B]] =
    pureconfig.configurable.genericMapReader[Ident, B](reason(Ident.fromString))

  implicit val byteVectorReader: ConfigReader[ByteVector] =
    ConfigReader[String].emap(reason { str =>
      if (str.startsWith("hex:"))
        ByteVector.fromHex(str.drop(4)).toRight("Invalid hex value.")
      else if (str.startsWith("b64:"))
        ByteVector.fromBase64(str.drop(4)).toRight("Invalid Base64 string.")
      else
        ByteVector
          .encodeUtf8(str)
          .left
          .map(ex => s"Invalid utf8 string: ${ex.getMessage}")
    })

  implicit val caleventReader: ConfigReader[CalEvent] =
    ConfigReader[String].emap(reason(CalEvent.parse))

  implicit val priorityReader: ConfigReader[Priority] =
    ConfigReader[String].emap(reason(Priority.fromString))

  implicit val nlpModeReader: ConfigReader[NlpMode] =
    ConfigReader[String].emap(reason(NlpMode.fromString))

  implicit val logFormatReader: ConfigReader[LogConfig.Format] =
    ConfigReader[String].emap(reason(LogConfig.Format.fromString))

  implicit val logLevelReader: ConfigReader[Level] =
    ConfigReader[String].emap(reason(Level.fromString))

  implicit val fileStoreTypeReader: ConfigReader[FileStoreType] =
    ConfigReader[String].emap(reason(FileStoreType.fromString))

  implicit val pgQueryParserReader: ConfigReader[PgQueryParser] =
    ConfigReader[String].emap(reason(PgQueryParser.fromName))

  implicit val pgRankNormalizationReader: ConfigReader[RankNormalization] =
    ConfigReader[List[Int]].emap(
      reason(ints => ints.traverse(RankNormalization.byNumber).map(_.reduce(_ && _)))
    )

  implicit val languageReader: ConfigReader[Language] =
    ConfigReader[String].emap(reason(Language.fromString))

  implicit def languageMapReader[B: ConfigReader]: ConfigReader[Map[Language, B]] =
    pureconfig.configurable.genericMapReader[Language, B](reason(Language.fromString))

  implicit val ftsTypeReader: ConfigReader[FtsType] =
    ConfigReader[String].emap(reason(FtsType.fromName))

  implicit val byteSizeReader: ConfigReader[ByteSize] =
    ConfigReader[String].emap(reason(ByteSize.parse))

  def reason[T, A: ClassTag](
      f: T => Either[String, A]
  ): T => Either[FailureReason, A] =
    in =>
      f(in).left.map(str =>
        CannotConvert(in.toString, implicitly[ClassTag[A]].runtimeClass.toString, str)
      )
}
