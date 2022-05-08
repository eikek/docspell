{-
   Copyright 2020 Eike K. & Contributors

   SPDX-License-Identifier: AGPL-3.0-or-later
-}


module Comp.AddonRunConfigTable exposing (..)

import Api.Model.AddonRunConfig exposing (AddonRunConfig)
import Comp.Basic as B
import Html exposing (Html, div, table, tbody, td, text, th, thead, tr)
import Html.Attributes exposing (class)
import Messages.Comp.AddonRunConfigTable exposing (Texts)
import Styles as S
import Util.Html


type Msg
    = SelectRunConfig AddonRunConfig


type TableAction
    = Selected AddonRunConfig



--- Update


update : Msg -> TableAction
update msg =
    case msg of
        SelectRunConfig cfg ->
            Selected cfg



--- View


view : Texts -> List AddonRunConfig -> Html Msg
view texts addons =
    table [ class S.tableMain ]
        [ thead []
            [ tr []
                [ th [ class "" ] []
                , th [ class "text-left" ]
                    [ text texts.basics.name
                    ]
                , th [ class "px-2 text-center" ] [ text texts.enabled ]
                , th [ class "px-2 text-left" ] [ text texts.trigger ]
                , th [ class "px-2 text-center" ] [ text "# Addons" ]
                ]
            ]
        , tbody []
            (List.map (renderRunConfigLine texts) addons)
        ]


renderRunConfigLine : Texts -> AddonRunConfig -> Html Msg
renderRunConfigLine texts cfg =
    tr
        [ class S.tableRow
        ]
        [ B.editLinkTableCell texts.basics.edit (SelectRunConfig cfg)
        , td [ class "text-left py-4 md:py-2" ]
            [ text cfg.name
            ]
        , td [ class "w-px whitespace-nowrap px-2 text-center" ]
            [ Util.Html.checkbox2 cfg.enabled
            ]
        , td [ class "px-2 text-left" ]
            [ text (String.join ", " cfg.trigger)
            ]
        , td [ class "px-2 text-center" ]
            [ text (String.fromInt <| List.length cfg.addons)
            ]
        ]
