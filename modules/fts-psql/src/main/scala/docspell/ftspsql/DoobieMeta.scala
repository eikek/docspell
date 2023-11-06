/*
 * Copyright 2020 Eike K. & Contributors
 *
 * SPDX-License-Identifier: AGPL-3.0-or-later
 */

package docspell.ftspsql

import docspell.common._

import doobie._

trait DoobieMeta {

  implicit val metaIdent: Meta[Ident] =
    Meta[String].timap(Ident.unsafe)(_.id)

  implicit val metaLanguage: Meta[Language] =
    Meta[String].timap(Language.unsafe)(_.iso3)

  implicit val metaCollectiveId: Meta[CollectiveId] =
    Meta[Long].timap(CollectiveId(_))(_.value)
}
