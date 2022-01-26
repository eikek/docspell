{-
   Copyright 2020 Eike K. & Contributors

   SPDX-License-Identifier: AGPL-3.0-or-later
-}


module Messages.Comp.BoxQueryView exposing (Texts, de, gb)

import Data.ItemTemplate as IT
import Http
import Messages.Basics
import Messages.Comp.HttpError
import Messages.Data.Direction
import Messages.Data.ItemColumn
import Messages.DateFormat as DF
import Messages.UiLanguage


type alias Texts =
    { httpError : Http.Error -> String
    , errorOccurred : String
    , basics : Messages.Basics.Texts
    , noResults : String
    , templateCtx : IT.TemplateContext
    , itemColumn : Messages.Data.ItemColumn.Texts
    }


gb : Texts
gb =
    { httpError = Messages.Comp.HttpError.gb
    , errorOccurred = "Error retrieving data."
    , basics = Messages.Basics.gb
    , noResults = "No items found."
    , templateCtx =
        { dateFormatLong = DF.formatDateLong Messages.UiLanguage.English
        , dateFormatShort = DF.formatDateShort Messages.UiLanguage.English
        , directionLabel = Messages.Data.Direction.gb
        }
    , itemColumn = Messages.Data.ItemColumn.gb
    }


de : Texts
de =
    { httpError = Messages.Comp.HttpError.de
    , errorOccurred = "Fehler beim Laden der Daten."
    , basics = Messages.Basics.de
    , noResults = "Keine Dokumente gefunden."
    , templateCtx =
        { dateFormatLong = DF.formatDateLong Messages.UiLanguage.German
        , dateFormatShort = DF.formatDateShort Messages.UiLanguage.German
        , directionLabel = Messages.Data.Direction.de
        }
    , itemColumn = Messages.Data.ItemColumn.de
    }
