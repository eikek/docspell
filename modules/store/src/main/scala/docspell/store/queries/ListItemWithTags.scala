package docspell.store.queries

import docspell.store.records.RTag

case class ListItemWithTags(
    item: ListItem,
    tags: List[RTag],
    attachments: List[AttachmentLight],
    customfields: List[ItemFieldValue]
)
