module Messages.Comp.BoxSearchQueryInput exposing (Texts, de, gb)

import Messages.Comp.BookmarkDropdown


type alias Texts =
    { bookmarkDropdown : Messages.Comp.BookmarkDropdown.Texts
    , switchToBookmark : String
    , switchToQuery : String
    , searchPlaceholder : String
    }


gb : Texts
gb =
    { bookmarkDropdown = Messages.Comp.BookmarkDropdown.gb
    , switchToBookmark = "Bookmarks"
    , switchToQuery = "Search query"
    , searchPlaceholder = "Search…"
    }


de : Texts
de =
    { bookmarkDropdown = Messages.Comp.BookmarkDropdown.de
    , switchToBookmark = "Bookmarks"
    , switchToQuery = "Suchabfrage"
    , searchPlaceholder = "Abfrage…"
    }
