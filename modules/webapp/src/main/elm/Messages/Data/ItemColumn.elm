{-
   Copyright 2020 Eike K. & Contributors

   SPDX-License-Identifier: AGPL-3.0-or-later
-}


module Messages.Data.ItemColumn exposing (Texts, de, gb)

import Data.ItemColumn exposing (ItemColumn(..))


type alias Texts =
    { header : ItemColumn -> String
    , label : ItemColumn -> String
    }


gb : Texts
gb =
    let
        headerName col =
            case col of
                Name ->
                    "Name"

                DateLong ->
                    "Date"

                DateShort ->
                    "Date"

                DueDateLong ->
                    "Due date"

                DueDateShort ->
                    "Due date"

                Folder ->
                    "Folder"

                Correspondent ->
                    "Correspondent"

                Concerning ->
                    "Concerning"

                Tags ->
                    "Tags"
    in
    { header = headerName
    , label =
        \col ->
            case col of
                DateShort ->
                    headerName col ++ " (short)"

                DateLong ->
                    headerName col ++ " (long)"

                DueDateShort ->
                    headerName col ++ " (short)"

                DueDateLong ->
                    headerName col ++ " (long)"

                _ ->
                    headerName col
    }


de : Texts
de =
    let
        headerName col =
            case col of
                Name ->
                    "Name"

                DateLong ->
                    "Datum"

                DateShort ->
                    "Datum"

                DueDateLong ->
                    "Fälligkeitsdatum"

                DueDateShort ->
                    "Fälligkeitsdatum"

                Folder ->
                    "Ordner"

                Correspondent ->
                    "Korrespondent"

                Concerning ->
                    "Betreffend"

                Tags ->
                    "Tags"
    in
    { header = headerName
    , label =
        \col ->
            case col of
                DateShort ->
                    headerName col ++ " (kurz)"

                DateLong ->
                    headerName col ++ " (lang)"

                DueDateShort ->
                    headerName col ++ " (kurz)"

                DueDateLong ->
                    headerName col ++ " (lang)"

                _ ->
                    headerName col
    }
