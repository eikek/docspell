/*
 * Copyright 2020 Eike K. & Contributors
 *
 * SPDX-License-Identifier: AGPL-3.0-or-later
 */

package docspell.ftssolr

import docspell.common._

final case class DocIdResult(ids: List[Ident]) {

  def toSetFolder(folder: Option[Ident]): List[SetFolder] =
    ids.map(id => SetFolder(id, folder))
}
