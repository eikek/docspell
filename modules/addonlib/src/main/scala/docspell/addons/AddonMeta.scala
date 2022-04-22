/*
 * Copyright 2020 Eike K. & Contributors
 *
 * SPDX-License-Identifier: AGPL-3.0-or-later
 */

package docspell.addons

import java.io.FileNotFoundException

import cats.data.OptionT
import cats.effect._
import cats.syntax.all._
import fs2.Stream
import fs2.io.file.{Files, Path}

import docspell.common.Glob
import docspell.files.Zip

import io.circe.generic.semiauto.{deriveDecoder, deriveEncoder}
import io.circe.yaml.{parser => YamlParser}
import io.circe.{Decoder, Encoder}
import io.circe.{parser => JsonParser}

case class AddonMeta(
    meta: AddonMeta.Meta,
    triggers: Option[Set[AddonTriggerType]],
    args: Option[List[String]],
    runner: Option[AddonMeta.Runner],
    options: Option[AddonMeta.Options]
) {

  def nameAndVersion: String =
    s"${meta.name}-${meta.version}"

  def parseResult: Boolean =
    options.exists(_.collectOutput)

  def ignoreResult: Boolean =
    !parseResult

  def isImpure: Boolean =
    options.exists(_.isImpure)

  def isPure: Boolean =
    options.forall(_.isPure)

  /** Returns a list of runner types that are possible to use for this addon. This is also
    * inspecting the archive to return defaults when the addon isn't declaring it in the
    * descriptor.
    */
  def enabledTypes[F[_]: Async](
      archive: Either[Path, Stream[F, Byte]]
  ): F[List[RunnerType]] =
    for {
      filesExists <- AddonArchive.dockerAndFlakeExists(archive)
      (dockerFileExists, flakeFileExists) = filesExists

      nixEnabled = runner.flatMap(_.nix).map(_.enable) match {
        case Some(flag) => flag
        case None       => flakeFileExists
      }

      dockerEnabled = runner.flatMap(_.docker).map(_.enable) match {
        case Some(flag) => flag
        case None       => dockerFileExists
      }

      trivialEnabled = runner.flatMap(_.trivial).exists(_.enable)

      result = RunnerType.all.filter(_.fold(nixEnabled, dockerEnabled, trivialEnabled))
    } yield result

}

object AddonMeta {

  def empty(name: String, version: String): AddonMeta =
    AddonMeta(Meta(name, version, None), None, None, None, None)

  case class Meta(name: String, version: String, description: Option[String])
  case class Runner(
      nix: Option[NixRunner],
      docker: Option[DockerRunner],
      trivial: Option[TrivialRunner]
  )
  case class NixRunner(enable: Boolean)
  case class DockerRunner(enable: Boolean, image: Option[String], build: Option[String])
  case class TrivialRunner(enable: Boolean, exec: String)
  case class Options(networking: Boolean, collectOutput: Boolean) {
    def isPure = !networking && collectOutput
    def isImpure = networking
    def isUseless = !networking && !collectOutput
    def isUseful = networking || collectOutput
  }

  object NixRunner {
    implicit val jsonEncoder: Encoder[NixRunner] =
      deriveEncoder
    implicit val jsonDecoder: Decoder[NixRunner] =
      deriveDecoder
  }

  object DockerRunner {
    implicit val jsonEncoder: Encoder[DockerRunner] =
      deriveEncoder
    implicit val jsonDecoder: Decoder[DockerRunner] =
      deriveDecoder
  }

  object TrivialRunner {
    implicit val jsonEncoder: Encoder[TrivialRunner] =
      deriveEncoder
    implicit val jsonDecoder: Decoder[TrivialRunner] =
      deriveDecoder
  }

  object Runner {
    implicit val jsonEncoder: Encoder[Runner] =
      deriveEncoder
    implicit val jsonDecoder: Decoder[Runner] =
      deriveDecoder
  }

  object Options {
    implicit val jsonEncoder: Encoder[Options] =
      deriveEncoder
    implicit val jsonDecoder: Decoder[Options] =
      deriveDecoder
  }

  object Meta {
    implicit val jsonEncoder: Encoder[Meta] =
      deriveEncoder
    implicit val jsonDecoder: Decoder[Meta] =
      deriveDecoder
  }

  implicit val jsonEncoder: Encoder[AddonMeta] =
    deriveEncoder

  implicit val jsonDecoder: Decoder[AddonMeta] =
    deriveDecoder

  def fromJsonString(str: String): Either[Throwable, AddonMeta] =
    JsonParser.decode[AddonMeta](str)

  def fromJsonBytes[F[_]: Sync](bytes: Stream[F, Byte]): F[AddonMeta] =
    bytes
      .through(fs2.text.utf8.decode)
      .compile
      .string
      .map(fromJsonString)
      .rethrow

  def fromYamlString(str: String): Either[Throwable, AddonMeta] =
    YamlParser.parse(str).flatMap(_.as[AddonMeta])

  def fromYamlBytes[F[_]: Sync](bytes: Stream[F, Byte]): F[AddonMeta] =
    bytes
      .through(fs2.text.utf8.decode)
      .compile
      .string
      .map(fromYamlString)
      .rethrow

  def findInDirectory[F[_]: Sync: Files](dir: Path): F[AddonMeta] = {
    val logger = docspell.logging.getLogger[F]
    val jsonFile = dir / "docspell-addon.json"
    val yamlFile = dir / "docspell-addon.yaml"
    val yamlFile2 = dir / "docspell-addon.yml"

    OptionT
      .liftF(Files[F].exists(jsonFile))
      .flatTap(OptionT.whenF(_)(logger.debug(s"Reading json addon file $jsonFile")))
      .flatMap(OptionT.whenF(_)(fromJsonBytes(Files[F].readAll(jsonFile))))
      .orElse(
        OptionT
          .liftF(Files[F].exists(yamlFile))
          .flatTap(OptionT.whenF(_)(logger.debug(s"Reading yaml addon file $yamlFile")))
          .flatMap(OptionT.whenF(_)(fromYamlBytes(Files[F].readAll(yamlFile))))
      )
      .orElse(
        OptionT
          .liftF(Files[F].exists(yamlFile2))
          .flatTap(OptionT.whenF(_)(logger.debug(s"Reading yaml addon file $yamlFile2")))
          .flatMap(OptionT.whenF(_)(fromYamlBytes(Files[F].readAll(yamlFile2))))
      )
      .getOrElseF(
        Sync[F].raiseError(
          new FileNotFoundException(s"No docspell-addon.{yaml|json} file found in $dir!")
        )
      )
  }

  def findInZip[F[_]: Async](zipFile: Stream[F, Byte]): F[AddonMeta] = {
    val fail: F[AddonMeta] = Async[F].raiseError(
      new FileNotFoundException(
        s"No docspell-addon.{yaml|json} file found in zip!"
      )
    )
    zipFile
      .through(Zip.unzip(8192, Glob("**/docspell-addon.*")))
      .filter(bin => !bin.name.endsWith("/"))
      .flatMap { bin =>
        if (bin.extensionIn(Set("json"))) Stream.eval(AddonMeta.fromJsonBytes(bin.data))
        else if (bin.extensionIn(Set("yaml", "yml")))
          Stream.eval(AddonMeta.fromYamlBytes(bin.data))
        else Stream.empty
      }
      .take(1)
      .compile
      .last
      .flatMap(_.map(Sync[F].pure).getOrElse(fail))
  }
}
