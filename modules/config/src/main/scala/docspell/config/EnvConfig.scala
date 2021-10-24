/*
 * Copyright 2020 Eike K. & Contributors
 *
 * SPDX-License-Identifier: AGPL-3.0-or-later
 */

package docspell.config

import java.util.Properties

import scala.collection.{MapView, mutable}
import scala.jdk.CollectionConverters._

import com.typesafe.config.{Config, ConfigFactory}

/** Creates a config from environment variables.
  *
  * The env variables are expected to be in same form as the config keys with the
  * following mangling: a dot is replaced by an underscore character, because this is the
  * standard separator for env variables. In order to represent dashes, two underscores
  * are needed (and for one underscore use three underscores in the env variable).
  *
  * For example, the config key
  * {{{
  *   docspell.server.app-name
  * }}}
  * can be given as env variable
  * {{{
  *   DOCSPELL_SERVER_APP__NAME
  * }}}
  */
object EnvConfig {

  /** The config from current environment. */
  lazy val get: Config =
    loadFrom(System.getenv().asScala.view)

  def loadFrom(env: MapView[String, String]): Config = {
    val cfg = new Properties()
    for (key <- env.keySet if key.startsWith("DOCSPELL_"))
      cfg.setProperty(envToProp(key), env(key))

    ConfigFactory
      .parseProperties(cfg)
      .withFallback(ConfigFactory.defaultReference())
      .resolve()
  }

  /** Docspell has all lowercase key names and uses snake case.
    *
    * So this converts to lowercase and then replaces underscores (like
    * [[com.typesafe.config.ConfigFactory.systemEnvironmentOverrides()]]
    *
    *   - 3 underscores -> `_` (underscore)
    *   - 2 underscores -> `-` (dash)
    *   - 1 underscore -> `.` (dot)
    */
  private[config] def envToProp(v: String): String = {
    val len = v.length
    val buffer = new mutable.StringBuilder()
    val underscoreMapping = Map(3 -> '_', 2 -> '-', 1 -> '.').withDefault(_ => '_')
    @annotation.tailrec
    def go(current: Int, underscores: Int): String =
      if (current >= len) buffer.toString()
      else
        v.charAt(current) match {
          case '_' => go(current + 1, underscores + 1)
          case c =>
            if (underscores > 0) {
              buffer.append(underscoreMapping(underscores))
            }
            buffer.append(c.toLower)
            go(current + 1, 0)
        }

    go(0, 0)
  }
}
