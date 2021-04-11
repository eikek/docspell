package docspell.store.queries

case class SearchSummary(
    count: Int,
    tags: List[TagCount],
    cats: List[CategoryCount],
    fields: List[FieldStats],
    folders: List[FolderCount]
)
