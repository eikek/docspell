{-
   Copyright 2020 Eike K. & Contributors

   SPDX-License-Identifier: AGPL-3.0-or-later
-}


module Comp.Progress exposing
    ( progress2
    , smallIndicating
    , topAttachedIndicating
    )

import Html exposing (Html, div, text)
import Html.Attributes exposing (attribute, class, style)


progress2 : Int -> Html msg
progress2 percent =
    div [ class "shadow w-full h-full bg-gray-200 dark:bg-slate-600 rounded relative" ]
        [ div
            [ class "transition-duration-300 h-full bg-blue-500 dark:bg-light-blue-500 block text-xs text-center"
            , style "width" (String.fromInt percent ++ "%")
            ]
            []
        , div [ class "absolute left-1/2 -top-1 font-semibold" ]
            [ text (String.fromInt percent)
            , text "%"
            ]
        ]


smallIndicating : Int -> Html msg
smallIndicating percent =
    progress "small indicating active" percent Nothing Nothing


topAttachedIndicating : Int -> Html msg
topAttachedIndicating percent =
    progress "top attached indicating active" percent Nothing Nothing


progress : String -> Int -> Maybe String -> Maybe String -> Html msg
progress classes percent label barText =
    if percent <= 0 then
        div
            [ class ("ui progress " ++ classes)
            ]
            (div [ class "bar" ] (barDiv barText) :: labelDiv label)

    else
        div
            [ class ("ui progress " ++ classes)
            , attribute "data-percent" (String.fromInt percent)
            ]
            (div
                [ class "bar"
                , style "transition-duration" "300ms"
                , style "display" "block"
                , style "width" (String.fromInt percent ++ "%")
                ]
                (barDiv barText)
                :: labelDiv label
            )


labelDiv : Maybe String -> List (Html msg)
labelDiv label =
    case label of
        Just l ->
            [ div [ class "label" ] [ text l ]
            ]

        Nothing ->
            []


barDiv : Maybe String -> List (Html msg)
barDiv barText =
    case barText of
        Just t ->
            [ div [ class "progress" ] [ text t ]
            ]

        Nothing ->
            []
