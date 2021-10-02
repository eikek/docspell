{-
   Copyright 2020 Eike K. & Contributors

   SPDX-License-Identifier: AGPL-3.0-or-later
-}


module Comp.ShareTable exposing
    ( Msg(..)
    , SelectAction(..)
    , update
    , view
    )

import Api.Model.ShareDetail exposing (ShareDetail)
import Comp.Basic as B
import Html exposing (..)
import Html.Attributes exposing (..)
import Messages.Comp.ShareTable exposing (Texts)
import Styles as S
import Util.Html
import Util.String


type Msg
    = Select ShareDetail


type SelectAction
    = Edit ShareDetail


update : Msg -> SelectAction
update msg =
    case msg of
        Select share ->
            Edit share



--- View


view : Texts -> List ShareDetail -> Html Msg
view texts shares =
    table [ class S.tableMain ]
        [ thead []
            [ tr []
                [ th [ class "" ] []
                , th [ class "text-left" ]
                    [ text texts.basics.id
                    ]
                , th [ class "text-left" ]
                    [ text texts.basics.name
                    ]
                , th [ class "text-center" ]
                    [ text texts.enabled
                    ]
                , th [ class "text-center" ]
                    [ text texts.publishUntil
                    ]
                ]
            ]
        , tbody []
            (List.map (renderShareLine texts) shares)
        ]


renderShareLine : Texts -> ShareDetail -> Html Msg
renderShareLine texts share =
    tr
        [ class S.tableRow
        ]
        [ B.editLinkTableCell texts.basics.edit (Select share)
        , td [ class "text-left py-4 md:py-2" ]
            [ text (Util.String.ellipsis 8 share.id)
            ]
        , td [ class "text-left py-4 md:py-2" ]
            [ text (Maybe.withDefault "-" share.name)
            ]
        , td [ class "w-px px-2 text-center" ]
            [ Util.Html.checkbox2 share.enabled
            ]
        , td [ class "hidden sm:table-cell text-center" ]
            [ texts.formatDateTime share.publishUntil |> text
            ]
        ]
