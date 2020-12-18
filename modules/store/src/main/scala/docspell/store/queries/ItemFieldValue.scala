package docspell.store.queries

import docspell.common._

case class ItemFieldValue(
    fieldId: Ident,
    fieldName: Ident,
    fieldLabel: Option[String],
    fieldType: CustomFieldType,
    value: String
)
