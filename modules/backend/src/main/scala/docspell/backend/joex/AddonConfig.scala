/*
 * Copyright 2020 Eike K. & Contributors
 *
 * SPDX-License-Identifier: AGPL-3.0-or-later
 */

package docspell.backend.joex

import docspell.common.exec.Env

/** Per-addon configuration for custom environment variables.
  * Matched by addon name (AddonMeta.Meta.name).
  */
final case class AddonConfig(
    name: String,
    enabled: Boolean = true,
    envs: List[AddonEnvVar] = Nil
) {

  /** Resolve all env vars to an Env map. Only applies when enabled. */
  def toEnv: Env =
    if (!enabled) Env.empty
    else envs.foldLeft(Env.empty) { (acc, ev) =>
      ev.resolve.fold(acc)(kv => acc.add(kv._1, kv._2))
    }
}

/** A single environment variable to inject, with either direct value or valueFrom. */
final case class AddonEnvVar(
    name: String,
    value: Option[String] = None,
    valueFrom: Option[AddonEnvVarFrom] = None
) {

  /** Resolve to Some((name, value)) or None if skipped. */
  def resolve: Option[(String, String)] =
    value match {
      case Some(v) => Some(name -> v)
      case None =>
        valueFrom.flatMap(_.env) match {
          case Some(envVar) =>
            val fromEnv = System.getenv(envVar)
            if (fromEnv != null) Some(name -> fromEnv)
            else if (valueFrom.exists(!_.optional)) Some(name -> "")
            else None
          case None => None
        }
    }
}

/** Kubernetes-style valueFrom: read value from another source (e.g. process env). */
final case class AddonEnvVarFrom(
    env: Option[String] = None,
    optional: Boolean = true
)
