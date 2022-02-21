/*
 * Copyright 2020 Eike K. & Contributors
 *
 * SPDX-License-Identifier: AGPL-3.0-or-later
 */

package docspell

import cats.Id
import cats.effect._

import docspell.logging.impl.ScribeWrapper

import sourcecode.Enclosing

package object logging {

  def unsafeLogger(name: String): Logger[Id] =
    new ScribeWrapper.ImplUnsafe(scribe.Logger(name))

  def unsafeLogger(implicit e: Enclosing): Logger[Id] =
    unsafeLogger(e.value)

  def getLogger[F[_]: Sync](implicit e: Enclosing): Logger[F] =
    getLogger(e.value)

  def getLogger[F[_]: Sync](name: String): Logger[F] =
    new ScribeWrapper.Impl[F](scribe.Logger(name))

  def getLogger[F[_]: Sync](clazz: Class[_]): Logger[F] =
    new ScribeWrapper.Impl[F](scribe.Logger(clazz.getName))

}
