{-
   Copyright 2020 Eike K. & Contributors

   SPDX-License-Identifier: AGPL-3.0-or-later
-}


module Messages.Comp.ItemSearchInput exposing (Texts, de, fr, gb, pt)

import Http
import Messages.Basics
import Messages.Comp.HttpError


type alias Texts =
    { noResults : String
    , placeholder : String
    , httpError : Http.Error -> String
    }


gb : Texts
gb =
    { noResults = "No results"
    , placeholder = Messages.Basics.gb.searchPlaceholder
    , httpError = Messages.Comp.HttpError.gb
    }


de : Texts
de =
    { noResults = "Keine Resultate"
    , placeholder = Messages.Basics.de.searchPlaceholder
    , httpError = Messages.Comp.HttpError.de
    }


fr : Texts
fr =
    { noResults = "Aucun document trouvé"
    , placeholder = Messages.Basics.fr.searchPlaceholder
    , httpError = Messages.Comp.HttpError.fr
    }


pt : Texts
pt =
    { noResults = "Nenhum resultado"
    , placeholder = Messages.Basics.pt.searchPlaceholder
    , httpError = Messages.Comp.HttpError.pt
    }
