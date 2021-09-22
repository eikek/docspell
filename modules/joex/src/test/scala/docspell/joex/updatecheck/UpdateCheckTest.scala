/*
 * Copyright 2020 Eike K. & Contributors
 *
 * SPDX-License-Identifier: AGPL-3.0-or-later
 */

package docspell.joex.updatecheck

import io.circe.{parser => jsonParser}
import munit._

class UpdateCheckTest extends FunSuite {

  val testRelease =
    UpdateCheck.Release(
      "https://github.com/eikek/docspell/releases/tag/v0.26.0",
      99899888,
      "v0.26.0",
      "Docspell 0.26.0",
      "2021-08-28T10:02:01Z",
      "2021-08-28T10:30:38Z"
    )

  test("parse example response") {
    val release =
      jsonParser
        .parse(UpdateCheckTest.exampleResponsePartial)
        .flatMap(_.as[UpdateCheck.Release])
        .getOrElse(sys.error("Could not parse test response"))

    assertEquals(release.version, "0.26.0")
    assertEquals(release, testRelease)
  }

  test("snapshot is matches") {
    val thisVersion = ThisVersion.constant("0.24.0-SNAPSHOT")
    assert(testRelease.matchesVersion(thisVersion))
  }

  test("newer version does not match ") {
    val thisVersion = ThisVersion.constant("0.25.0")
    assert(!testRelease.matchesVersion(thisVersion))
  }

  test("same version matches") {
    val thisVersion = ThisVersion.constant("0.26.0")
    assert(testRelease.matchesVersion(thisVersion))
  }

}

object UpdateCheckTest {

  val exampleResponsePartial =
    """
      |{
      |  "url": "https://api.github.com/repos/eikek/docspell/releases/99899888",
      |  "assets_url": "https://api.github.com/repos/eikek/docspell/releases/99899888/assets",
      |  "upload_url": "https://uploads.github.com/repos/eikek/docspell/releases/99899888/assets{?name,label}",
      |  "html_url": "https://github.com/eikek/docspell/releases/tag/v0.26.0",
      |  "id": 99899888,
      |  "node_id": "MDc6UmVsZWFzZTQ4NjEwNTY2",
      |  "tag_name": "v0.26.0",
      |  "target_commitish": "master",
      |  "name": "Docspell 0.26.0",
      |  "draft": false,
      |  "prerelease": false,
      |  "created_at": "2021-08-28T10:02:01Z",
      |  "published_at": "2021-08-28T10:30:38Z",
      |  "assets": [
      |    {
      |      "url": "https://api.github.com/repos/eikek/docspell/releases/assets/43494218",
      |      "id": 43494218,
      |      "node_id": "MDEyOlJlbGVhc2VBc3NldDQzNDk0MjE4",
      |      "name": "docspell-joex-0.26.0.zip",
      |      "label": "",
      |      "content_type": "application/zip",
      |      "state": "uploaded",
      |      "size": 328163415,
      |      "download_count": 24,
      |      "created_at": "2021-08-28T10:16:24Z",
      |      "updated_at": "2021-08-28T10:16:36Z",
      |      "browser_download_url": "https://github.com/eikek/docspell/releases/download/v0.26.0/docspell-joex-0.26.0.zip"
      |    },
      |    {
      |      "url": "https://api.github.com/repos/eikek/docspell/releases/assets/43494232",
      |      "id": 43494232,
      |      "node_id": "MDEyOlJlbGVhc2VBc3NldDQzNDk0MjMy",
      |      "name": "docspell-joex_0.26.0_all.deb",
      |      "label": "",
      |      "content_type": "application/vnd.debian.binary-package",
      |      "state": "uploaded",
      |      "size": 337991872,
      |      "download_count": 8,
      |      "created_at": "2021-08-28T10:16:37Z",
      |      "updated_at": "2021-08-28T10:16:53Z",
      |      "browser_download_url": "https://github.com/eikek/docspell/releases/download/v0.26.0/docspell-joex_0.26.0_all.deb"
      |    }
      |  ],
      |  "tarball_url": "https://api.github.com/repos/eikek/docspell/tarball/v0.26.0",
      |  "zipball_url": "https://api.github.com/repos/eikek/docspell/zipball/v0.26.0"
      |}
      |""".stripMargin
}
