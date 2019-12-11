package docspell.common

import java.net.URL

import fs2.Stream
import cats.implicits._
import cats.data.NonEmptyList
import cats.effect.{Blocker, ContextShift, Sync}
import docspell.common.LenientUri.Path
import io.circe.{Decoder, Encoder}
import scodec.bits.ByteVector

/** A URI.
  *
  * It is not compliant to rfc3986, but covers most use cases in a convenient way.
  */
case class LenientUri(scheme: NonEmptyList[String]
  , authority: Option[String]
  , path: LenientUri.Path
  , query: Option[String]
  , fragment: Option[String]) {

  def /(segment: String): LenientUri =
    copy(path = path / segment)

  def ++ (np: Path): LenientUri =
    copy(path = np.segments.foldLeft(path)(_ / _))

  def ++ (np: String): LenientUri = {
    val rel = LenientUri.stripLeading(np, '/')
    ++(LenientUri.unsafe(s"a:$rel").path)
  }

  def toJavaUrl: Either[String, URL] =
    Either.catchNonFatal(new URL(asString)).left.map(_.getMessage)

  def readURL[F[_]: Sync : ContextShift](chunkSize: Int, blocker: Blocker): Stream[F, Byte] =
    Stream.emit(Either.catchNonFatal(new URL(asString))).
      covary[F].
      rethrow.
      flatMap(url => fs2.io.readInputStream(Sync[F].delay(url.openStream()), chunkSize, blocker, true))

  def host: Option[String] =
    authority.
      map(a => a.indexOf(':') match {
        case -1 => a
        case n => a.substring(0, n)
      })

  def asString: String = {
    val schemePart = scheme.toList.mkString(":")
    val authPart = authority.map(a => s"//$a").getOrElse("")
    val pathPart = path.asString
    val queryPart = query.map(q => s"?$q").getOrElse("")
    val fragPart = fragment.map(f => s"#$f").getOrElse("")
    s"$schemePart:$authPart$pathPart$queryPart$fragPart"
  }
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
      NonEmptyPath(NonEmptyList.of(seg))
    def asString = "/"
  }
  case object EmptyPath extends Path {
    val segments = Nil
    val isRoot = false
    val isEmpty = true
    def /(seg: String): Path =
      NonEmptyPath(NonEmptyList.of(seg))
    def asString = ""
  }
  case class NonEmptyPath(segs: NonEmptyList[String]) extends Path {
    def segments = segs.toList
    val isEmpty = false
    val isRoot = false
    def /(seg: String): Path =
      copy(segs = segs.append(seg))
    def asString = segs.head match {
      case "." => segments.map(percentEncode).mkString("/")
      case ".." => segments.map(percentEncode).mkString("/")
      case _ => "/" + segments.map(percentEncode).mkString("/")
    }
  }

  def unsafe(str: String): LenientUri =
    parse(str).fold(sys.error, identity)

  def fromJava(u: URL): LenientUri =
    unsafe(u.toExternalForm)

  def parse(str: String): Either[String, LenientUri] = {
    def makePath(str: String): Path = str.trim match {
      case "/" => RootPath
      case "" => EmptyPath
      case _ => NonEmptyList.fromList(stripLeading(str, '/').split('/').toList.map(percentDecode)) match {
        case Some(nl) => NonEmptyPath(nl)
        case None => sys.error(s"Invalid url: $str")
      }
    }

    def makeNonEmpty(str: String): Option[String] =
      Option(str).filter(_.nonEmpty)
    def makeScheme(s: String): Option[NonEmptyList[String]] =
      NonEmptyList.fromList(s.split(':').toList.filter(_.nonEmpty).map(_.toLowerCase))

    def splitPathQF(pqf: String): (Path, Option[String], Option[String]) =
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
              (makePath(pqf.substring(0, n)), makeNonEmpty(pqf.substring(n+1)), None)
            case k =>
              (makePath(pqf.substring(0, n)), makeNonEmpty(pqf.substring(n+1, k)), makeNonEmpty(pqf.substring(k+1)))
          }
      }

    str.split("//", 2) match {
      case Array(p0, p1) =>
        // scheme:scheme:authority/path
        val scheme = makeScheme(p0)
        val (auth, pathQF) = p1.indexOf('/') match {
          case -1 => (Some(p1), "")
          case n => (Some(p1.substring(0, n)), p1.substring(n))
        }
        val (path, query, frag) = splitPathQF(pathQF)
        scheme match {
          case None =>
            Left(s"No scheme found: $str")
          case Some(nl) =>
            Right(LenientUri(nl, auth, path, query, frag))
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
                Right(LenientUri(nl, None, path, query, frag))
            }
        }
    }
  }

  private[this] val delims: Set[Char] = ",/?:@&=+$# %".toSet

  private def percent(s: String): String =
    "%" + ByteVector.encodeUtf8(s).
      fold(throw _, identity).
      toHex

  def percentEncode(s: String): String =
    s.flatMap(c =>
      if (delims.contains(c)) percent(c.toString) else c.toString)

  def percentDecode(s: String): String =
    if (!s.contains("%")) s
    else
      s.foldLeft(("", ByteVector.empty)) {
          case ((acc, res), c) =>
            if (acc.length == 2) ("", res ++ ByteVector.fromValidHex(acc.drop(1) + c))
            else if (acc.startsWith("%")) (acc :+ c, res)
            else if (c == '%') ("%", res)
            else (acc, res :+ c.toByte)
        }
        ._2.decodeUtf8.fold(throw _, identity)

  private def stripLeading(s: String, c: Char): String =
    if (s.length > 0 && s.charAt(0) == c) s.substring(1)
    else s


  implicit val encodeLenientUri: Encoder[LenientUri] =
    Encoder.encodeString.contramap(_.asString)

  implicit val decodeLenientUri: Decoder[LenientUri] =
    Decoder.decodeString.emap(LenientUri.parse)
}
