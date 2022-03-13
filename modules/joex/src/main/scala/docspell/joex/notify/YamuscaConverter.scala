/*
 * Copyright 2020 Eike K. & Contributors
 *
 * SPDX-License-Identifier: AGPL-3.0-or-later
 */

package docspell.joex.notify

import docspell.common._

import yamusca.derive._
import yamusca.implicits._
import yamusca.imports._

trait YamuscaConverter {

  implicit val uriConverter: ValueConverter[LenientUri] =
    ValueConverter.of(uri => Value.fromString(uri.asString))

  implicit val timestamp: ValueConverter[Timestamp] =
    ValueConverter.of(ts => Value.fromString(ts.toUtcDate.toString))

  implicit val ident: ValueConverter[Ident] =
    ValueConverter.of(id => Value.fromString(id.id))

  implicit val account: ValueConverter[AccountId] =
    deriveValueConverter[AccountId]

}

object YamuscaConverter extends YamuscaConverter
