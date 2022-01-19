{-
   Copyright 2020 Eike K. & Contributors

   SPDX-License-Identifier: AGPL-3.0-or-later
-}


module Comp.NotificationChannelTable exposing (..)

import Comp.Basic as B
import Data.ChannelType
import Data.Flags exposing (Flags)
import Data.NotificationChannel exposing (NotificationChannel)
import Html exposing (..)
import Html.Attributes exposing (..)
import Messages.Comp.NotificationChannelTable exposing (Texts)
import Styles as S


type alias Model =
    {}


type Action
    = NoAction
    | EditAction NotificationChannel


init : Model
init =
    {}


type Msg
    = Select NotificationChannel


update : Flags -> Msg -> Model -> ( Model, Action )
update _ msg model =
    case msg of
        Select channel ->
            ( model, EditAction channel )



--- View


view : Texts -> Model -> List NotificationChannel -> Html Msg
view texts model channels =
    table [ class S.tableMain ]
        [ thead []
            [ tr []
                [ th [ class "" ] []
                , th [ class "text-left" ]
                    [ text texts.basics.name
                    ]
                , th [ class "text-left" ]
                    [ text texts.channelType
                    ]
                ]
            ]
        , tbody []
            (List.map (renderNotificationChannelLine texts model) channels)
        ]


renderNotificationChannelLine : Texts -> Model -> NotificationChannel -> Html Msg
renderNotificationChannelLine texts _ channel =
    let
        ref =
            Data.NotificationChannel.getRef channel
    in
    tr
        [ class S.tableRow
        ]
        [ B.editLinkTableCell texts.basics.edit (Select channel)
        , td
            [ class "text-left "
            , classList [ ( "font-mono", ref.name == Nothing ) ]
            ]
            [ Maybe.withDefault (String.slice 0 10 ref.id) ref.name |> text
            ]
        , td [ class "text-left py-4 md:py-2" ]
            [ text ref.channelType
            ]
        ]
