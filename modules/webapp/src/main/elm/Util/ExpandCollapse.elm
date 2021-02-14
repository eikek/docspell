module Util.ExpandCollapse exposing
    ( collapseToggle
    , collapseToggle2
    , expandToggle
    , expandToggle2
    )

import Html exposing (..)
import Html.Attributes exposing (..)
import Html.Events exposing (onClick)
import Styles as S


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



--- View2


expandToggle2 : Int -> Int -> msg -> List (Html msg)
expandToggle2 max all m =
    if max >= all then
        []

    else
        [ a
            [ class S.link
            , class "flex flex-row items-center"
            , onClick m
            , href "#"
            ]
            [ i [ class "fa fa-angle-down" ] []
            , div [ class "font-italics text-sm ml-2" ]
                [ text "Show More …"
                ]
            ]
        ]


collapseToggle2 : Int -> Int -> msg -> List (Html msg)
collapseToggle2 max all m =
    if max >= all then
        []

    else
        [ a
            [ class S.link
            , class "flex flex-row items-center"
            , onClick m
            , href "#"
            ]
            [ i [ class "fa fa-angle-up" ] []
            , div [ class "font-italics text-sm ml-2" ]
                [ text "Show Less …"
                ]
            ]
        ]
