{-
   Copyright 2020 Eike K. & Contributors

   SPDX-License-Identifier: AGPL-3.0-or-later
-}


module Comp.AddonArchiveTable exposing (..)

import Api.Model.Addon exposing (Addon)
import Comp.Basic as B
import Html exposing (Html, div, table, tbody, td, text, th, thead, tr)
import Html.Attributes exposing (class)
import Messages.Comp.AddonArchiveTable exposing (Texts)
import Styles as S


type Msg
    = SelectAddon Addon


type TableAction
    = Selected Addon



--- Update


update : Msg -> TableAction
update msg =
    case msg of
        SelectAddon addon ->
            Selected addon



--- View


view : Texts -> List Addon -> Html Msg
view texts addons =
    table [ class S.tableMain ]
        [ thead []
            [ tr []
                [ th [ class "" ] []
                , th [ class "text-left" ]
                    [ text texts.basics.name
                    ]
                , th [ class "text-left" ]
                    [ text texts.version
                    ]
                ]
            ]
        , tbody []
            (List.map (renderAddonLine texts) addons)
        ]


renderAddonLine : Texts -> Addon -> Html Msg
renderAddonLine texts addon =
    tr
        [ class S.tableRow
        ]
        [ B.editLinkTableCell texts.basics.edit (SelectAddon addon)
        , td [ class "text-left py-4 md:py-2" ]
            [ text addon.name
            ]
        , td [ class "text-left" ]
            [ text addon.version
            ]
        ]
