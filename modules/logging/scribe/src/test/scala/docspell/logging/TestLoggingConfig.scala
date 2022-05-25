/*
 * Copyright 2020 Eike K. & Contributors
 *
 * SPDX-License-Identifier: AGPL-3.0-or-later
 */

package docspell.logging

import docspell.logging.impl.ScribeConfigure

import munit.Suite

trait TestLoggingConfig extends Suite {
  def docspellLogConfig: LogConfig =
    LogConfig(rootMinimumLevel, LogConfig.Format.Fancy, Map.empty)

  def rootMinimumLevel: Level = Level.Error

  override def beforeAll(): Unit = {
    super.beforeAll()
    ScribeConfigure.unsafeConfigure(docspellLogConfig)
  }
}
