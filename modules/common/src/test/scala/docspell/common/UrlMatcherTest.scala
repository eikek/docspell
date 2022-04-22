/*
 * Copyright 2020 Eike K. & Contributors
 *
 * SPDX-License-Identifier: AGPL-3.0-or-later
 */

package docspell.common

import munit._

class UrlMatcherTest extends FunSuite {

  test("it should match patterns") {
    assertUrlsMatch(
      uri("https://github.com/docspell/*") -> uri("https://github.com/docspell/dsc"),
      uri("*s://test.com/*") -> uri("https://test.com/a"),
      uri("*s://test.com/*") -> uri("https://test.com/a/b"),
      uri("*s://test.com/*") -> uri("https://test.com/a/b/c"),
      uri("*s://test.com/project/*") -> uri("https://test.com/project/c"),
      uri("https://*.test.com/projects/*") -> uri("https://a.test.com/projects/p1"),
      uri("https://*.test.com/projects/*") -> uri("https://b.test.com/projects/p1"),
      uri("https://*.test.com/projects/*") -> uri("https://b.test.com/projects/p1")
    )

    assertUrlsNotMatch(
      uri("https://*.test.com/projects/*") -> uri("https://test.com/projects/p1"),
      uri("*s://test.com/project/*") -> uri("https://test.com/subject/c")
    )
  }

  def uri(str: String): LenientUri = LenientUri.unsafe(str)

  def assertUrlsMatch(tests: List[(LenientUri, LenientUri)]): Unit =
    tests.foreach { case (patternUri, checkUri) =>
      assert(
        UrlMatcher.fromUrl(patternUri).matches(checkUri),
        s"$patternUri does not match $checkUri"
      )
    }

  def assertUrlsMatch(
      test: (LenientUri, LenientUri),
      more: (LenientUri, LenientUri)*
  ): Unit =
    assertUrlsMatch(test :: more.toList)

  def assertUrlsNotMatch(tests: List[(LenientUri, LenientUri)]): Unit =
    tests.foreach { case (patternUri, checkUri) =>
      assert(
        !UrlMatcher.fromUrl(patternUri).matches(checkUri),
        s"$patternUri incorrectly matches $checkUri"
      )
    }

  def assertUrlsNotMatch(
      test: (LenientUri, LenientUri),
      more: (LenientUri, LenientUri)*
  ): Unit =
    assertUrlsNotMatch(test :: more.toList)
}
