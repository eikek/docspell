module Util.ExpandCollapse exposing
    ( collapseToggle
    , expandToggle
    )

import Html exposing (..)
import Html.Attributes exposing (..)
import Html.Events exposing (onClick)


expandToggle : Int -> Int -> msg -> List (Html msg)
expandToggle max all m =
    if max >= all then
        []

    else
        [ a
            [ class "item"
            , onClick m
            , href "#"
            ]
            [ i [ class "angle down icon" ] []
            , div [ class "content" ]
                [ div [ class "description" ]
                    [ em [] [ text "Show More …" ]
                    ]
                ]
            ]
        ]


collapseToggle : Int -> Int -> msg -> List (Html msg)
collapseToggle max all m =
    if max >= all then
        []

    else
        [ a
            [ class "item"
            , onClick m
            , href "#"
            ]
            [ i [ class "angle up icon" ] []
            , div [ class "content" ]
                [ div [ class "description" ]
                    [ em [] [ text "Show Less …" ]
                    ]
                ]
            ]
        ]
