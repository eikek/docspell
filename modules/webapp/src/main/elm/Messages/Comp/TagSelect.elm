{-
   Copyright 2020 Eike K. & Contributors

   SPDX-License-Identifier: AGPL-3.0-or-later
-}


module Messages.Comp.TagSelect exposing
    ( Texts
    , de
    , fr
    , ja
    , gb
    )

import Messages.Comp.ExpandCollapse


type alias Texts =
    { expandCollapse : Messages.Comp.ExpandCollapse.Texts
    , hideEmpty : String
    , showEmpty : String
    , filterPlaceholder : String
    }


gb : Texts
gb =
    { expandCollapse = Messages.Comp.ExpandCollapse.gb
    , hideEmpty = "Hide empty"
    , showEmpty = "Show empty"
    , filterPlaceholder = "Filter …"
    }


de : Texts
de =
    { expandCollapse = Messages.Comp.ExpandCollapse.de
    , hideEmpty = "Leere ausblenden"
    , showEmpty = "Leere anzeigen"
    , filterPlaceholder = "Filter …"
    }


fr : Texts
fr =
    { expandCollapse = Messages.Comp.ExpandCollapse.fr
    , hideEmpty = "Cacher si vide"
    , showEmpty = "Montrer si vide"
    , filterPlaceholder = "Filtrer …"
    }


ja : Texts
ja =
    { expandCollapse = Messages.Comp.ExpandCollapse.ja
    , hideEmpty = "空の項目を非表示"
    , showEmpty = "空の項目を表示"
    , filterPlaceholder = "フィルター…"
    }
