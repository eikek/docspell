{-
   Copyright 2020 Eike K. & Contributors

   SPDX-License-Identifier: AGPL-3.0-or-later
-}


module Comp.DueItemsTaskList exposing
    ( Action(..)
    , Model
    , Msg
    , init
    , update
    , view2
    )

import Api.Model.PeriodicDueItemsSettings exposing (PeriodicDueItemsSettings)
import Comp.Basic as B
import Data.ChannelRef
import Data.ChannelType
import Html exposing (..)
import Html.Attributes exposing (..)
import Messages.Comp.DueItemsTaskList exposing (Texts)
import Styles as S
import Util.Html
import Util.List


type alias Model =
    {}


type Msg
    = EditSettings PeriodicDueItemsSettings


type Action
    = NoAction
    | EditAction PeriodicDueItemsSettings


init : Model
init =
    {}


update : Msg -> Model -> ( Model, Action )
update msg model =
    case msg of
        EditSettings settings ->
            ( model, EditAction settings )



--- View2


view2 : Texts -> Model -> List PeriodicDueItemsSettings -> Html Msg
view2 texts _ items =
    div []
        [ table [ class S.tableMain ]
            [ thead []
                [ tr []
                    [ th [ class "" ] []
                    , th [ class "text-center mr-2" ]
                        [ i [ class "fa fa-check" ] []
                        ]
                    , th [ class "text-left " ] [ text texts.summary ]
                    , th [ class "text-left hidden sm:table-cell mr-2" ]
                        [ text texts.schedule ]
                    , th [ class "text-left mr-2" ]
                        [ text texts.connection ]
                    ]
                ]
            , tbody []
                (List.map (viewItem2 texts) items)
            ]
        ]


viewItem2 : Texts -> PeriodicDueItemsSettings -> Html Msg
viewItem2 texts item =
    tr []
        [ B.editLinkTableCell texts.basics.edit (EditSettings item)
        , td [ class "w-px whitespace-nowrap px-2 text-center" ]
            [ Util.Html.checkbox2 item.enabled
            ]
        , td [ class "text-left" ]
            [ Maybe.withDefault "" item.summary
                |> text
            ]
        , td [ class "text-left hidden sm:table-cell mr-2" ]
            [ code [ class "font-mono text-sm" ]
                [ text item.schedule
                ]
            ]
        , td [ class "text-left mr-2" ]
            [ div [ class " space-x-1" ]
                (Data.ChannelRef.asDivs texts.channelType [ class "inline" ] item.channels)
            ]
        ]
