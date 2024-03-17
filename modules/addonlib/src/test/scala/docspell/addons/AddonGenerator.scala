/*
 * Copyright 2020 Eike K. & Contributors
 *
 * SPDX-License-Identifier: AGPL-3.0-or-later
 */

package docspell.addons

import cats.effect.{IO, Resource}
import cats.syntax.all._
import fs2.Stream
import fs2.io.file.{Files, Path, PosixPermissions}

import docspell.addons.out.AddonOutput
import docspell.common.LenientUri
import docspell.common.util.Zip

import io.circe.syntax._

object AddonGenerator {
  private[this] val logger = docspell.logging.getLogger[IO]

  def successAddon(
      name: String,
      version: String = "1.0",
      output: Option[AddonOutput] = None
  ): Resource[IO, AddonArchive] =
    output match {
      case None =>
        generate(name, version, collectOutput = false)("exit 0")
      case Some(out) =>
        generate(name, version, collectOutput = true)(
          s"""
             |cat <<-EOF
             |${out.asJson.noSpaces}
             |EOF""".stripMargin
        )
    }

  def failingAddon(
      name: String,
      version: String = "1.0",
      pure: Boolean = true
  ): Resource[IO, AddonArchive] =
    generate(name, version, pure)("exit 1")

  def generate(name: String, version: String, collectOutput: Boolean)(
      script: String
  ): Resource[IO, AddonArchive] =
    Files[IO].tempDirectory(None, s"addon-gen-$name-$version-", None).evalMap { dir =>
      for {
        yml <- createDescriptor(dir, name, version, collectOutput)
        bin <- createScript(dir, script)
        zip <- createZip(dir, List(yml, bin))
        url = LenientUri.fromJava(zip.toNioPath.toUri.toURL)
      } yield AddonArchive(url, name, version)
    }

  private def createZip(dir: Path, files: List[Path]) =
    Stream
      .emits(files)
      .map(f => (f.fileName.toString, f))
      .covary[IO]
      .through(Zip[IO](logger.some).zipFiles())
      .through(Files[IO].writeAll(dir / "addon.zip"))
      .compile
      .drain
      .as(dir / "addon.zip")

  private def createDescriptor(
      dir: Path,
      name: String,
      version: String,
      collectOutput: Boolean
  ): IO[Path] = {
    val meta = AddonMeta(
      meta = AddonMeta.Meta(name, version, None),
      triggers = Set(AddonTriggerType.ExistingItem: AddonTriggerType).some,
      args = None,
      runner = AddonMeta
        .Runner(None, None, AddonMeta.TrivialRunner(enable = true, "addon.sh").some)
        .some,
      options =
        AddonMeta.Options(networking = !collectOutput, collectOutput = collectOutput).some
    )

    Stream
      .emit(meta.asJson.noSpaces)
      .covary[IO]
      .through(fs2.text.utf8.encode)
      .through(Files[IO].writeAll(dir / "docspell-addon.json"))
      .compile
      .drain
      .as(dir / "docspell-addon.json")
  }

  private def createScript(dir: Path, content: String): IO[Path] = {
    val scriptFile = dir / "addon.sh"
    Stream
      .emit(s"""
               |#!/usr/bin/env bash
               |
               |$content
               |
               |""".stripMargin)
      .covary[IO]
      .through(fs2.text.utf8.encode)
      .through(Files[IO].writeAll(scriptFile))
      .compile
      .drain
      .as(scriptFile)
      .flatTap(f =>
        Files[IO].setPosixPermissions(f, PosixPermissions.fromOctal("777").get)
      )
  }
}
