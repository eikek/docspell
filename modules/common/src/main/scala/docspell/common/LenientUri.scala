/*
 * Copyright 2020 Eike K. & Contributors
 *
 * SPDX-License-Identifier: AGPL-3.0-or-later
 */

package docspell.common

import java.net.HttpURLConnection
import java.net.URL
import java.net.URLEncoder

import cats.data.NonEmptyList
import cats.effect.Resource
import cats.effect._
import cats.implicits._
import fs2.Stream

import docspell.common.LenientUri.Path

import io.circe.{Decoder, Encoder}
import scodec.bits.ByteVector

/** A URI.
  *
  * It is not compliant to rfc3986, but covers most use cases in a convenient way.
  */
case class LenientUri(
    scheme: NonEmptyList[String],
    authority: Option[String],
    path: LenientUri.Path,
    query: Option[String],
    fragment: Option[String]
) {

  def /(segment: String): LenientUri =
    copy(path = path / segment)

  def ++(np: Path): LenientUri =
    copy(path = np.segments.foldLeft(path)(_ / _))

  def ++(np: String): LenientUri = {
    val rel = LenientUri.stripLeading(np, '/')
    ++(LenientUri.unsafe(s"a:$rel").path)
  }

  def withQuery(name: String, value: String): LenientUri =
    withQueryPlain(name, URLEncoder.encode(value, "UTF-8"))

  def withQueryPlain(name: String, value: String): LenientUri =
    copy(query =
      query.map(q => q + "&" + name + "=" + value).orElse(Option(s"$name=$value"))
    )

  def withFragment(f: String): LenientUri =
    copy(fragment = Some(f))

  def rootPathToEmpty: LenientUri =
    path match {
      case LenientUri.RootPath => copy(path = LenientUri.EmptyPath)
      case _                   => this
    }

  def toJavaUrl: Either[String, URL] =
    Either.catchNonFatal(new URL(asString)).left.map(_.getMessage)

  def open[F[_]: Sync]: Either[String, Resource[F, HttpURLConnection]] =
    toJavaUrl.map { url =>
      Resource
        .make(Sync[F].delay(url.openConnection().asInstanceOf[HttpURLConnection]))(conn =>
          Sync[F].delay(conn.disconnect())
        )
    }

  def readURL[F[_]: Sync](chunkSize: Int): Stream[F, Byte] =
    Stream
      .emit(Either.catchNonFatal(new URL(asString)))
      .covary[F]
      .rethrow
      .flatMap(url =>
        fs2.io.readInputStream(
          Sync[F].delay(url.openStream()),
          chunkSize,
          closeAfterUse = true
        )
      )

  def readText[F[_]: Sync](chunkSize: Int): F[String] =
    readURL[F](chunkSize).through(fs2.text.utf8.decode).compile.foldMonoid

  def host: Option[String] =
    authority.map(a =>
      a.indexOf(':') match {
        case -1 => a
        case n  => a.substring(0, n)
      }
    )

  def isLocal: Boolean =
    host.exists(_.equalsIgnoreCase("localhost"))

  def asString: String = {
    val schemePart = scheme.toList.mkString(":")
    val authPart = authority.map(a => s"//$a").getOrElse("")
    val pathPart = path.asString
    val queryPart = query.map(q => s"?$q").getOrElse("")
    val fragPart = fragment.map(f => s"#$f").getOrElse("")
    s"$schemePart:$authPart$pathPart$queryPart$fragPart"
  }
  override def toString(): String =
    asString
}

object LenientUri {

  sealed trait Path {
    def segments: List[String]
    def isRoot: Boolean
    def isEmpty: Boolean
    def /(segment: String): Path
    def asString: String
  }
  case object RootPath extends Path {
    val segments = Nil
    val isRoot = true
    val isEmpty = false
    def /(seg: String): Path =
      NonEmptyPath(NonEmptyList.of(seg), trailingSlash = false)
    def asString = "/"
  }
  case object EmptyPath extends Path {
    val segments = Nil
    val isRoot = false
    val isEmpty = true
    def /(seg: String): Path =
      NonEmptyPath(NonEmptyList.of(seg), trailingSlash = false)
    def asString = ""
  }
  case class NonEmptyPath(segs: NonEmptyList[String], trailingSlash: Boolean)
      extends Path {
    def segments = segs.toList
    val isEmpty = false
    val isRoot = false
    private val slashSuffix = if (trailingSlash) "/" else ""
    def /(seg: String): Path =
      copy(segs = segs.append(seg))
    def asString =
      segs.head match {
        case "."  => segments.map(percentEncode).mkString("/") + slashSuffix
        case ".." => segments.map(percentEncode).mkString("/") + slashSuffix
        case _    => "/" + segments.map(percentEncode).mkString("/") + slashSuffix
      }
  }

  def unsafe(str: String): LenientUri =
    parse(str).fold(sys.error, identity)

  def fromJava(u: URL): LenientUri =
    unsafe(u.toExternalForm)

  def parse(str: String): Either[String, LenientUri] = {
    def makePath(str: String): Either[String, Path] =
      str.trim match {
        case "/" => Right(RootPath)
        case ""  => Right(EmptyPath)
        case uriStr =>
          Either.fromOption(
            stripLeading(uriStr, '/')
              .split('/')
              .toList
              .traverse(percentDecode)
              .flatMap(NonEmptyList.fromList)
              .map(NonEmptyPath(_, uriStr.endsWith("/"))),
            s"Invalid path: $str"
          )
      }

    def makeNonEmpty(str: String): Option[String] =
      Option(str).filter(_.nonEmpty)
    def makeScheme(s: String): Option[NonEmptyList[String]] =
      NonEmptyList.fromList(s.split(':').toList.filter(_.nonEmpty).map(_.toLowerCase))

    def splitPathQF(pqf: String): (Either[String, Path], Option[String], Option[String]) =
      pqf.indexOf('?') match {
        case -1 =>
          pqf.indexOf('#') match {
            case -1 =>
              (makePath(pqf), None, None)
            case n =>
              (makePath(pqf.substring(0, n)), None, makeNonEmpty(pqf.substring(n + 1)))
          }
        case n =>
          pqf.indexOf('#', n) match {
            case -1 =>
              (makePath(pqf.substring(0, n)), makeNonEmpty(pqf.substring(n + 1)), None)
            case k =>
              (
                makePath(pqf.substring(0, n)),
                makeNonEmpty(pqf.substring(n + 1, k)),
                makeNonEmpty(pqf.substring(k + 1))
              )
          }
      }

    str.split("//", 2) match {
      case Array(p0, p1) =>
        // scheme:scheme:authority/path
        val scheme = makeScheme(p0)
        val (auth, pathQF) = p1.indexOf('/') match {
          case -1 => (Some(p1), "")
          case n  => (Some(p1.substring(0, n)), p1.substring(n))
        }
        val (path, query, frag) = splitPathQF(pathQF)
        scheme match {
          case None =>
            Left(s"No scheme found: $str")
          case Some(nl) =>
            path.map(p => LenientUri(nl, auth, p, query, frag))
        }
      case Array(p0) =>
        // scheme:scheme:path
        p0.lastIndexOf(':') match {
          case -1 =>
            Left(s"No scheme found: $str")
          case n =>
            val scheme = makeScheme(p0.substring(0, n))
            val (path, query, frag) = splitPathQF(p0.substring(n + 1))
            scheme match {
              case None =>
                Left(s"No scheme found: $str")
              case Some(nl) =>
                path.map(p => LenientUri(nl, None, p, query, frag))
            }
        }
      case _ =>
        // str.split(…, 2) returns either array of length 2 or 1, never empty
        sys.error("Unreachable code")
    }
  }

  private[this] val delims: Set[Char] = ",/?:@&$# %".toSet

  private def percent(s: String): String =
    "%" + ByteVector.encodeUtf8(s).fold(throw _, identity).toHex

  def percentEncode(s: String): String =
    s.flatMap(c => if (delims.contains(c)) percent(c.toString) else c.toString)

  def percentDecode(s: String): Option[String] = {
    @annotation.tailrec
    def go(pos: Int, acc: Option[String], result: ByteVector): Option[ByteVector] =
      if (pos >= s.length) Some(result)
      else {
        val c = s.charAt(pos)
        acc match {
          case Some(enc) if enc.length == 1 =>
            ByteVector.fromHex(enc + c) match {
              case Some(next) =>
                go(pos + 1, None, result ++ next)
              case None =>
                None
            }

          case Some(enc) =>
            go(pos + 1, Some(enc + c), result)

          case None if c == '%' =>
            go(pos + 1, Some(""), result)

          case None =>
            go(pos + 1, acc, result :+ c.toByte)
        }
      }

    go(0, None, ByteVector.empty).flatMap(bv => bv.decodeUtf8.toOption)
  }

  private def stripLeading(s: String, c: Char): String =
    if (s.length > 0 && s.charAt(0) == c) s.substring(1)
    else s

  implicit val encodeLenientUri: Encoder[LenientUri] =
    Encoder.encodeString.contramap(_.asString)

  implicit val decodeLenientUri: Decoder[LenientUri] =
    Decoder.decodeString.emap(LenientUri.parse)
}
