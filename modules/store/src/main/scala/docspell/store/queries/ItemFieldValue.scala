/*
 * Copyright 2020 Docspell Contributors
 *
 * SPDX-License-Identifier: GPL-3.0-or-later
 */

package docspell.store.queries

import docspell.common._

case class ItemFieldValue(
    fieldId: Ident,
    fieldName: Ident,
    fieldLabel: Option[String],
    fieldType: CustomFieldType,
    value: String
)
