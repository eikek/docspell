/*
 * Copyright 2020 Eike K. & Contributors
 *
 * SPDX-License-Identifier: AGPL-3.0-or-later
 */

package docspell.store.records

import cats.data.NonEmptyList
import cats.syntax.all._
import fs2.Stream

import docspell.addons.AddonTriggerType
import docspell.common.{CollectiveId, Ident, Timestamp}
import docspell.store.qb.DSL._
import docspell.store.qb._

import doobie._

case class AddonRunConfigData(
    runConfig: RAddonRunConfig,
    addons: List[RAddonRunConfigAddon],
    triggers: List[RAddonRunConfigTrigger]
)

object AddonRunConfigData {

  def findAll(
      cid: CollectiveId,
      enabled: Option[Boolean] = None,
      trigger: Set[AddonTriggerType] = Set.empty,
      configIds: Set[Ident] = Set.empty
  ): ConnectionIO[List[AddonRunConfigData]] =
    for {
      runConfigs <- RAddonRunConfig.findByCollective(cid, enabled, trigger, configIds)
      addons <- runConfigs.traverse(t =>
        RAddonRunConfigAddon.findByRunConfig(t.id).map(as => t.id -> as)
      )
      addonMap = addons.toMap
      triggers <- runConfigs.traverse(t =>
        RAddonRunConfigTrigger.findByRunConfig(t.id).map(ts => t.id -> ts)
      )
      triggerMap = triggers.toMap
      result = runConfigs.map(t =>
        AddonRunConfigData(t, addonMap(t.id), triggerMap(t.id))
      )
    } yield result

  /** Inserts new, creating new identifiers */
  def insert(task: AddonRunConfigData): ConnectionIO[Ident] =
    for {
      tid <- Ident.randomId[ConnectionIO]
      now <- Timestamp.current[ConnectionIO]
      tr = task.runConfig.copy(id = tid, created = now)
      _ <- RAddonRunConfig.insert(tr)
      _ <- task.triggers.traverse { t =>
        Ident
          .randomId[ConnectionIO]
          .map(id => t.copy(id = id, runConfigId = tid))
          .flatMap(RAddonRunConfigTrigger.insert)
      }
      _ <- task.addons.traverse { a =>
        Ident
          .randomId[ConnectionIO]
          .map(id => a.copy(id = id, runConfigId = tid))
          .flatMap(RAddonRunConfigAddon.insert)
      }
    } yield tid

  /** Updates the task, keeping its id but replacing all related objects */
  def update(task: AddonRunConfigData): ConnectionIO[Int] =
    for {
      n1 <- RAddonRunConfig.update(task.runConfig)
      _ <- RAddonRunConfigTrigger.deleteAllForConfig(task.runConfig.id)
      _ <- RAddonRunConfigAddon.deleteAllForConfig(task.runConfig.id)
      tts <- task.triggers.traverse { t =>
        Ident
          .randomId[ConnectionIO]
          .map(id => t.copy(id = id, runConfigId = task.runConfig.id))
          .flatMap(RAddonRunConfigTrigger.insert)
      }
      tas <- task.addons.traverse { a =>
        Ident
          .randomId[ConnectionIO]
          .map(id => a.copy(id = id, runConfigId = task.runConfig.id))
          .flatMap(RAddonRunConfigAddon.insert)
      }
    } yield n1 + tts.sum + tas.sum

  def findEnabledRef(
      cid: CollectiveId,
      taskId: Ident
  ): ConnectionIO[List[(RAddonArchive, RAddonRunConfigAddon)]] = {
    val run = RAddonRunConfig.as("run")
    val aa = RAddonArchive.as("aa")
    val ta = RAddonRunConfigAddon.as("ta")

    Select(
      combineNel(select(aa.all), select(ta.all)),
      from(run)
        .innerJoin(ta, ta.runConfigId === run.id)
        .innerJoin(aa, aa.id === ta.addonId),
      run.cid === cid && run.enabled === true && run.id === taskId
    ).orderBy(ta.position.asc)
      .build
      .query[(RAddonArchive, RAddonRunConfigAddon)]
      .to[List]
  }

  def findEnabledRefs(
      cid: CollectiveId,
      trigger: AddonTriggerType,
      addonTaskIds: Set[Ident]
  ): Stream[ConnectionIO, (RAddonRunConfig, List[(RAddonArchive, String)])] = {
    val run = RAddonRunConfig.as("run")
    val aa = RAddonArchive.as("aa")
    val ta = RAddonRunConfigAddon.as("ta")
    val tt = RAddonRunConfigTrigger.as("tt")

    val taskIdFilter = NonEmptyList
      .fromList(addonTaskIds.toList)
      .map(nel => run.id.in(nel))
    val validTasks = TableDef("valid_task")
    val validTaskId = Column[Ident]("id", validTasks)
    val query =
      withCte(
        validTasks -> Select(
          select(run.all),
          from(run)
            .innerJoin(tt, tt.runConfigId === run.id),
          run.cid === cid && run.enabled === true && tt.trigger === trigger &&? taskIdFilter
        ).distinct
      )(
        Select(
          combineNel(
            select(run.all.map(_.copy(table = validTasks))),
            select(aa.all),
            select(ta.args)
          ),
          from(validTasks)
            .innerJoin(ta, ta.runConfigId === validTaskId)
            .innerJoin(aa, aa.id === ta.addonId)
        ).orderBy(validTaskId)
      ).build

    query
      .query[(RAddonRunConfig, RAddonArchive, String)]
      .stream
      .groupAdjacentBy(_._1.id)
      .map { case (_, chunk) =>
        val list = chunk.toList
        (list.head._1, list.map(e => (e._2, e._3)))
      }
  }
}
