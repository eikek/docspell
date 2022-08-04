/*
 * Copyright 2020 Eike K. & Contributors
 *
 * SPDX-License-Identifier: AGPL-3.0-or-later
 */

package docspell.backend.ops

import cats.data.NonEmptyList
import cats.effect._
import cats.syntax.all._
import docspell.backend.ops.AddonRunConfigError._
import docspell.backend.ops.OAddons.{AddonRunConfigResult, AddonRunInsert}
import docspell.common.CollectiveId
import docspell.store.Store
import docspell.store.records.RAddonArchive

object AddonRunConfigValidate {

  def apply[F[_]: Sync](store: Store[F], cid: CollectiveId)(
      cfg: AddonRunInsert
  ): F[AddonRunConfigResult[AddonRunInsert]] = {
    val init: AddonRunConfigResult[Unit] = ().asRight

    List(
      checkScheduled(cfg).pure[F],
      checkTriggers(store, cid)(cfg)
    )
      .foldLeftM(init)((res, fr) => fr.map(r => res.flatMap(_ => r)))
      .map(_.as(cfg))
  }

  def checkTriggers[F[_]: Sync](store: Store[F], cid: CollectiveId)(
      cfg: AddonRunInsert
  ): F[AddonRunConfigResult[Unit]] =
    for {
      addons <- store.transact(RAddonArchive.findByIds(cid, cfg.addons.map(_.addonId)))
      given = cfg.triggered.toList.toSet
      res = addons
        .flatMap(r => given.diff(r.triggers).map(tt => r.nameAndVersion -> tt))

      maybeError = NonEmptyList
        .fromList(res)
        .map(nel => MismatchingTrigger(nel))
    } yield maybeError.map(_.toLeft).getOrElse(Right(()))

  def checkScheduled(cfg: AddonRunInsert): AddonRunConfigResult[Unit] =
    (cfg.isScheduled, cfg.schedule) match {
      case (true, None)     => MissingSchedule.toLeft[Unit]
      case (false, Some(_)) => ObsoleteSchedule.toLeft[Unit]
      case _                => ().asRight
    }
}
