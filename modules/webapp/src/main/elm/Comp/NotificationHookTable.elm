{-
   Copyright 2020 Eike K. & Contributors

   SPDX-License-Identifier: AGPL-3.0-or-later
-}


module Comp.NotificationHookTable exposing
    ( Action(..)
    , Model
    , Msg(..)
    , init
    , update
    , view
    )

import Comp.Basic as B
import Data.ChannelType
import Data.EventType
import Data.Flags exposing (Flags)
import Data.NotificationChannel
import Data.NotificationHook exposing (NotificationHook)
import Html exposing (..)
import Html.Attributes exposing (..)
import Html.Events exposing (onClick)
import Messages.Comp.NotificationHookTable exposing (Texts)
import Styles as S
import Util.Html


type alias Model =
    {}


type Action
    = NoAction
    | EditAction NotificationHook


init : Model
init =
    {}


type Msg
    = Select NotificationHook


update : Flags -> Msg -> Model -> ( Model, Action )
update _ msg model =
    case msg of
        Select hook ->
            ( model, EditAction hook )



--- View


view : Texts -> Model -> List NotificationHook -> Html Msg
view texts model hooks =
    table [ class S.tableMain ]
        [ thead []
            [ tr []
                [ th [ class "" ] []
                , th [ class "text-center mr-2" ]
                    [ i [ class "fa fa-check" ] []
                    ]
                , th [ class "text-left" ]
                    [ text texts.channel
                    ]
                , th [ class "text-left hidden sm:table-cell" ]
                    [ text texts.events
                    ]
                ]
            ]
        , tbody []
            (List.map (renderNotificationHookLine texts model) hooks)
        ]


renderNotificationHookLine : Texts -> Model -> NotificationHook -> Html Msg
renderNotificationHookLine texts model hook =
    let
        eventName =
            texts.eventType >> .name
    in
    tr
        [ class S.tableRow
        ]
        [ B.editLinkTableCell texts.basics.edit (Select hook)
        , td [ class "w-px whitespace-nowrap px-2 text-center" ]
            [ Util.Html.checkbox2 hook.enabled
            ]
        , td [ class "text-left py-4 md:py-2" ]
            [ Data.NotificationChannel.channelType hook.channel
                |> Maybe.map Data.ChannelType.asString
                |> Maybe.withDefault "-"
                |> text
            ]
        , td [ class "text-left hidden sm:table-cell" ]
            [ List.map eventName hook.events
                |> String.join ", "
                |> text
            ]
        ]
