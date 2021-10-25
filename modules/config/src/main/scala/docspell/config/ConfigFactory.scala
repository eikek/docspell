/*
 * Copyright 2020 Eike K. & Contributors
 *
 * SPDX-License-Identifier: AGPL-3.0-or-later
 */

package docspell.config

import scala.reflect.ClassTag

import cats.data.OptionT
import cats.effect._
import cats.implicits._
import fs2.io.file.{Files, Path}

import docspell.common.Logger

import pureconfig.{ConfigReader, ConfigSource}

object ConfigFactory {

  /** Reads the configuration trying the following in order:
    *   1. if 'args' contains at least one element, the first is interpreted as a config
    *      file
    *   1. otherwise check the system property 'config.file' for an existing file and use
    *      it if it does exist; ignore if it doesn't exist
    *   1. if no file is found, read the config from environment variables falling back to
    *      the default config
    */
  def default[F[_]: Async, C: ClassTag: ConfigReader](logger: Logger[F], atPath: String)(
      args: List[String],
      validation: Validation[C]
  ): F[C] =
    findFileFromArgs(args).flatMap {
      case Some(file) =>
        logger.info(s"Using config file: $file") *>
          readFile[F, C](file, atPath).map(validation.validOrThrow)
      case None =>
        checkSystemProperty.value.flatMap {
          case Some(file) =>
            logger.info(s"Using config file from system property: $file") *>
              readConfig(atPath).map(validation.validOrThrow)
          case None =>
            logger.info("Using config from environment variables!") *>
              readEnv(atPath).map(validation.validOrThrow)
        }
    }

  /** Reads the configuration from the given file. */
  private def readFile[F[_]: Sync, C: ClassTag: ConfigReader](
      file: Path,
      at: String
  ): F[C] =
    Sync[F].delay {
      System.setProperty(
        "config.file",
        file.toNioPath.toAbsolutePath.normalize.toString
      )
      ConfigSource.default.at(at).loadOrThrow[C]
    }

  /** Reads the config as specified in typesafe's config library; usually loading the file
    * given as system property 'config.file'.
    */
  private def readConfig[F[_]: Sync, C: ClassTag: ConfigReader](
      at: String
  ): F[C] =
    Sync[F].delay(ConfigSource.default.at(at).loadOrThrow[C])

  /** Reads the configuration from environment variables. */
  private def readEnv[F[_]: Sync, C: ClassTag: ConfigReader](at: String): F[C] =
    Sync[F].delay(ConfigSource.fromConfig(EnvConfig.get).at(at).loadOrThrow[C])

  /** Uses the first argument as a path to the config file. If it is specified but the
    * file doesn't exist, an exception is thrown.
    */
  private def findFileFromArgs[F[_]: Async](args: List[String]): F[Option[Path]] =
    args.headOption
      .map(Path.apply)
      .traverse(p =>
        Files[F].exists(p).flatMap {
          case true  => p.pure[F]
          case false => Async[F].raiseError(new Exception(s"File not found: $p"))
        }
      )

  /** If the system property 'config.file' is set, it is checked whether the file exists.
    * If it doesn't exist, the property is removed to not raise any exception. In contrast
    * to giving the file as argument, it is not an error to specify a non-existing file
    * via a system property.
    */
  private def checkSystemProperty[F[_]: Async]: OptionT[F, Path] =
    for {
      cf <- OptionT(
        Sync[F].delay(
          Option(System.getProperty("config.file")).map(_.trim).filter(_.nonEmpty)
        )
      )
      cp = Path(cf)
      exists <- OptionT.liftF(Files[F].exists(cp))
      file <-
        if (exists) OptionT.pure[F](cp)
        else
          OptionT
            .liftF(Sync[F].delay(System.clearProperty("config.file")))
            .flatMap(_ => OptionT.none[F, Path])
    } yield file

}
