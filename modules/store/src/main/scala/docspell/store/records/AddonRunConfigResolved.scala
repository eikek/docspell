/*
 * Copyright 2020 Eike K. & Contributors
 *
 * SPDX-License-Identifier: AGPL-3.0-or-later
 */

package docspell.store.records

import cats.data.OptionT
import cats.syntax.all._

import docspell.addons.AddonTriggerType
import docspell.common._
import docspell.store.qb.DSL._
import docspell.store.qb._
import docspell.store.records.AddonRunConfigResolved.AddonRef

import doobie._
import doobie.implicits._

final case class AddonRunConfigResolved(
    config: RAddonRunConfig,
    refs: List[AddonRef],
    trigger: List[RAddonRunConfigTrigger]
) {}

object AddonRunConfigResolved {

  case class AddonRef(archive: RAddonArchive, ref: RAddonRunConfigAddon)

  def findAddonRefs(configId: Ident): ConnectionIO[List[AddonRef]] = {
    val ca = RAddonRunConfigAddon.as("ca")
    val aa = RAddonArchive.as("aa")
    Select(
      select(combineNel(aa.all, ca.all)),
      from(ca)
        .innerJoin(aa, aa.id === ca.addonId),
      ca.runConfigId === configId
    ).build.query[AddonRef].to[List]
  }

  def getRefsAndTrigger(
      configId: Ident
  ): ConnectionIO[(List[AddonRef], List[RAddonRunConfigTrigger])] =
    (findAddonRefs(configId), RAddonRunConfigTrigger.findByRunConfig(configId)).tupled

  def findById(
      configId: Ident,
      collective: CollectiveId,
      enabled: Option[Boolean]
  ): ConnectionIO[Option[AddonRunConfigResolved]] =
    (for {
      cfg <- OptionT(RAddonRunConfig.findById(collective, configId))
        .filter(c => enabled.isEmpty || enabled == c.enabled.some)
      (refs, tri) <- OptionT.liftF(getRefsAndTrigger(configId))
    } yield AddonRunConfigResolved(cfg, refs, tri)).value

  def findAllForCollective(
      cid: CollectiveId,
      enabled: Option[Boolean],
      trigger: Set[AddonTriggerType],
      configIds: Set[Ident]
  ): ConnectionIO[List[AddonRunConfigResolved]] =
    for {
      cfgs <- RAddonRunConfig.findByCollective(cid, enabled, trigger, configIds)
      result <- cfgs.traverse(ac =>
        getRefsAndTrigger(ac.id).map { case (refs, tri) =>
          AddonRunConfigResolved(ac, refs, tri)
        }
      )
    } yield result
}
