module Comp.Progress exposing
    ( smallIndicating
    , topAttachedIndicating
    )

import Html exposing (Html, div, text)
import Html.Attributes exposing (attribute, class, style)


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
