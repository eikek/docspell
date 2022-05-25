/*
 * Copyright 2020 Eike K. & Contributors
 *
 * SPDX-License-Identifier: AGPL-3.0-or-later
 */

package docspell.backend.ops

import cats.data.EitherT
import cats.effect._
import cats.syntax.all._
import fs2.Stream
import fs2.io.file.Path

import docspell.addons.{AddonMeta, RunnerType}
import docspell.backend.Config
import docspell.backend.ops.AddonValidationError._
import docspell.backend.ops.OAddons.AddonValidationResult
import docspell.common.{Ident, LenientUri, UrlReader}
import docspell.joexapi.model.AddonSupport
import docspell.store.Store
import docspell.store.records.RAddonArchive

final class AddonValidate[F[_]: Async](
    cfg: Config.Addons,
    store: Store[F],
    joexOps: OJoex[F]
) {
  private[this] val logger = docspell.logging.getLogger[F]

  def fromUrl(
      collective: Ident,
      url: LenientUri,
      reader: UrlReader[F],
      localUrl: Option[LenientUri] = None,
      checkExisting: Boolean = true
  ): F[AddonValidationResult[AddonMeta]] =
    if (!cfg.enabled) AddonsDisabled.resultF
    else if (cfg.isDenied(url)) UrlUntrusted(url).resultF
    else if (checkExisting)
      store.transact(RAddonArchive.findByUrl(collective, url)).flatMap {
        case Some(ar) =>
          AddonExists("An addon with this url already exists!", ar).resultF
        case None =>
          archive(collective, reader(localUrl.getOrElse(url)).asRight, checkExisting)
      }
    else archive(collective, reader(localUrl.getOrElse(url)).asRight, checkExisting)

  def archive(
      collective: Ident,
      addonData: Either[Path, Stream[F, Byte]],
      checkExisting: Boolean = true
  ): F[AddonValidationResult[AddonMeta]] =
    (for {
      _ <- EitherT.cond[F](cfg.enabled, (), AddonsDisabled.cast)

      meta <-
        EitherT(
          addonData
            .fold(
              AddonMeta.findInDirectory[F],
              AddonMeta.findInZip[F]
            )
            .attempt
        )
          .leftMap(ex => NotAnAddon(ex).cast)
      _ <- EitherT.cond(
        meta.triggers.exists(_.nonEmpty),
        (),
        InvalidAddon(
          "The addon doesn't define any triggers. At least one is required!"
        ).cast
      )
      _ <- EitherT.cond(
        meta.options.exists(_.isUseful),
        (),
        InvalidAddon(
          "Addon defines no output and no networking. It can't do anything useful."
        ).cast
      )
      _ <- EitherT.cond(cfg.allowImpure || meta.isPure, (), ImpureAddonsDisabled.cast)

      _ <-
        if (checkExisting)
          EitherT(
            store
              .transact(
                RAddonArchive
                  .findByNameAndVersion(collective, meta.meta.name, meta.meta.version)
              )
              .map {
                case Some(ar) => AddonExists(ar).result
                case None     => rightUnit
              }
          )
        else rightUnitT

      joexSupport <- EitherT.liftF(joexOps.getAddonSupport)
      addonRunners <- EitherT.liftF(meta.enabledTypes(addonData))
      _ <- EitherT.liftF(
        logger.info(
          s"Comparing joex support vs addon runner: $joexSupport vs. $addonRunners"
        )
      )
      _ <- EitherT.fromEither(validateJoexSupport(addonRunners, joexSupport))

    } yield meta).value

  private def validateJoexSupport(
      addonRunnerTypes: List[RunnerType],
      joexSupport: List[AddonSupport]
  ): AddonValidationResult[Unit] = {
    val addonRunners = addonRunnerTypes.mkString(", ")
    for {
      _ <- Either.cond(
        joexSupport.nonEmpty,
        (),
        AddonUnsupported("There are no joex nodes that have addons enabled!", Nil).cast
      )
      _ <- Either.cond(
        addonRunners.nonEmpty,
        (),
        InvalidAddon("The addon doesn't enable any runner.")
      )

      ids = joexSupport
        .map(n => n.nodeId -> n.runners.intersect(addonRunnerTypes).toSet)

      unsupportedJoex = ids.filter(_._2.isEmpty).map(_._1)

      _ <- Either.cond(
        ids.forall(_._2.nonEmpty),
        (),
        AddonUnsupported(
          s"A joex node doesn't support this addons runners: $addonRunners. " +
            s"Check: ${unsupportedJoex.map(_.id).mkString(", ")}.",
          unsupportedJoex
        ).cast
      )
    } yield ()
  }

  private def rightUnit: AddonValidationResult[Unit] =
    ().asRight[AddonValidationError]

  private def rightUnitT: EitherT[F, AddonValidationError, Unit] =
    EitherT.fromEither(rightUnit)

  implicit final class ErrorOps(self: AddonValidationError) {
    def result: AddonValidationResult[AddonMeta] =
      self.toLeft

    def resultF: F[AddonValidationResult[AddonMeta]] =
      result.pure[F]
  }
}
