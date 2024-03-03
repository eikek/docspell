/*
 * Copyright 2020 Eike K. & Contributors
 *
 * SPDX-License-Identifier: AGPL-3.0-or-later
 */

package docspell.common

import cats.data.NonEmptyList
import cats.kernel.Monoid
import cats.syntax.all._

trait UrlMatcher {
  def matches(url: LenientUri): Boolean
}

object UrlMatcher {
  val True = instance(_ => true)
  val False = instance(_ => false)

  def instance(f: LenientUri => Boolean): UrlMatcher =
    (url: LenientUri) => f(url)

  def fromString(str: String): Either[String, UrlMatcher] =
    if (str == "") False.asRight
    else if (str == "*") True.asRight
    else LenientUri.parse(str).map(fromUrl)

  def unsafeFromString(str: String): UrlMatcher =
    fromString(str).fold(sys.error, identity)

  def fromStringList(str: List[String]): Either[String, UrlMatcher] =
    str match {
      case Nil => False.asRight
      case _   => str.map(_.trim).traverse(fromString).map(_.combineAll)
    }

  def fromUrl(url: LenientUri): UrlMatcher = {
    val schemeGlob = Glob(url.scheme.head)
    val hostGlob = HostGlob(url.host)
    val pathGlob = Glob(url.path.asString)
    new Impl(schemeGlob, hostGlob, pathGlob, url.path.segments.size)
  }

  def any(ulrm: IterableOnce[UrlMatcher]): UrlMatcher =
    anyMonoid.combineAll(ulrm)

  def all(urlm: IterableOnce[UrlMatcher]): UrlMatcher =
    allMonoid.combineAll(urlm)

  val anyMonoid: Monoid[UrlMatcher] =
    Monoid.instance(False, (a, b) => instance(url => a.matches(url) || b.matches(url)))

  val allMonoid: Monoid[UrlMatcher] =
    Monoid.instance(True, (a, b) => instance(url => a.matches(url) && b.matches(url)))

  implicit val defaultMonoid: Monoid[UrlMatcher] = anyMonoid

  private class Impl(scheme: Glob, host: HostGlob, path: Glob, pathSegmentCount: Int)
      extends UrlMatcher {
    def matches(url: LenientUri) = {
      // strip path to only match prefixes
      val mPath: LenientUri.Path =
        NonEmptyList.fromList(url.path.segments.take(pathSegmentCount)) match {
          case Some(nel) => LenientUri.NonEmptyPath(nel, trailingSlash = false)
          case None      => LenientUri.RootPath
        }

      url.scheme.forall(scheme.matches(false)) &&
      host.matches(url.host) &&
      path.matchFilenameOrPath(mPath.asString)
    }
  }

  private class HostGlob(glob: Option[Glob]) {
    def matches(host: Option[String]): Boolean =
      (glob, host) match {
        case (Some(pattern), Some(word)) =>
          pattern.matches(false)(HostGlob.prepareHost(word))
        case (None, None) => true
        case _            => false
      }

    override def toString = s"HostGlob(${glob.map(_.asString)})"
  }

  private object HostGlob {
    def apply(hostPattern: Option[String]): HostGlob =
      new HostGlob(hostPattern.map(p => Glob(prepareHost(p))))

    private def prepareHost(host: String): String =
      host.replace('.', '/')
  }
}
