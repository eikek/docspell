/*
 * Copyright 2020 Eike K. & Contributors
 *
 * SPDX-License-Identifier: AGPL-3.0-or-later
 */

package docspell.backend.joex

/** Per-addon configuration for custom environment variables.
  * Matched by addon name (AddonMeta.Meta.name).
  */
final case class AddonConfig(
    name: String,
    enabled: Boolean = true,
    envs: List[AddonEnvVar] = Nil
)

/** A single environment variable to inject, with either direct value or valueFrom. */
final case class AddonEnvVar(
    name: String,
    value: Option[String] = None,
    valueFrom: Option[AddonEnvVarFrom] = None
)

/** Kubernetes-style valueFrom: read value from another source (e.g. process env). */
final case class AddonEnvVarFrom(
    env: Option[String] = None,
    optional: Boolean = true
)
