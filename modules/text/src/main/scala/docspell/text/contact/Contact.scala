package docspell.text.contact

import fs2.Stream
import cats.implicits._
import docspell.common.{Ident, LenientUri, NerLabel, NerTag}
import docspell.text.split.TextSplitter

object Contact {
  private[this] val protocols = Set("ftp", "http", "https")

  def annotate(text: String): Vector[NerLabel] =
    TextSplitter
      .splitToken[Nothing](text, " \t\r\n".toSet)
      .map({ token =>
        if (isEmailAddress(token.value))
          NerLabel(token.value, NerTag.Email, token.begin, token.end).some
        else if (isWebsite(token.value))
          NerLabel(token.value, NerTag.Website, token.begin, token.end).some
        else None
      })
      .flatMap(_.map(Stream.emit).getOrElse(Stream.empty))
      .toVector

  def isEmailAddress(str: String): Boolean = {
    val atIdx = str.indexOf('@')
    if (atIdx <= 0 || str.indexOf('@', atIdx + 1) > 0) false
    else {
      val name = str.substring(0, atIdx)
      val dom  = str.substring(atIdx + 1)
      Domain.isDomain(dom) && name.forall(c => !c.isWhitespace)
    }
  }

  def isWebsite(str: String): Boolean =
    LenientUri
      .parse(str)
      .toOption
      .map(uri => protocols.contains(uri.scheme.head))
      .getOrElse(Domain.isDomain(str))

  def isDocspellOpenUpload(str: String): Boolean = {
    def isUploadPath(p: LenientUri.Path): Boolean =
      p match {
        case LenientUri.RootPath  => false
        case LenientUri.EmptyPath => false
        case LenientUri.NonEmptyPath(segs) =>
          Ident.fromString(segs.last).isRight &&
            segs.init.takeRight(3) == List("open", "upload", "item")
      }
    LenientUri
      .parse(str)
      .toOption
      .exists(uri => protocols.contains(uri.scheme.head) && isUploadPath(uri.path))
  }
}
