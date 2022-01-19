{-
   Copyright 2020 Eike K. & Contributors

   SPDX-License-Identifier: AGPL-3.0-or-later
-}


module Data.ChannelRef exposing (..)

import Api.Model.NotificationChannelRef exposing (NotificationChannelRef)
import Data.ChannelType exposing (ChannelType)
import Html exposing (Attribute, Html, div, span, text)
import Html.Attributes exposing (class)
import Messages.Data.ChannelType as M
import Util.List


channelType : NotificationChannelRef -> Maybe ChannelType
channelType ref =
    Data.ChannelType.fromString ref.channelType


split : M.Texts -> NotificationChannelRef -> ( String, String )
split texts ref =
    let
        chStr =
            channelType ref
                |> Maybe.map texts
                |> Maybe.withDefault ref.channelType

        name =
            Maybe.withDefault (String.slice 0 6 ref.id) ref.name
    in
    ( chStr, name )


asString : M.Texts -> NotificationChannelRef -> String
asString texts ref =
    let
        ( chStr, name ) =
            split texts ref
    in
    chStr ++ " (" ++ name ++ ")"


asDiv : List (Attribute msg) -> M.Texts -> NotificationChannelRef -> Html msg
asDiv attrs texts ref =
    let
        ( chStr, name ) =
            split texts ref
    in
    div attrs
        [ text chStr
        , span [ class "ml-1 text-xs opacity-75" ]
            [ text ("(" ++ name ++ ")")
            ]
        ]


asStringJoined : M.Texts -> List NotificationChannelRef -> String
asStringJoined texts refs =
    List.map (asString texts) refs
        |> Util.List.distinct
        |> String.join ", "


asDivs : M.Texts -> List (Attribute msg) -> List NotificationChannelRef -> List (Html msg)
asDivs texts inner refs =
    List.map (asDiv inner texts) refs
