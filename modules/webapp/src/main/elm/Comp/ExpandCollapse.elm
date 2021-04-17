module Comp.ExpandCollapse exposing
    ( collapseToggle
    , expandToggle
    )

import Html exposing (..)
import Html.Attributes exposing (..)
import Html.Events exposing (onClick)
import Messages.Comp.ExpandCollapse exposing (Texts)
import Styles as S


type alias Model =
    { max : Int
    , all : Int
    }



--- View2


expandToggle : Texts -> Model -> msg -> List (Html msg)
expandToggle texts model m =
    if model.max >= model.all then
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
                [ text texts.showMoreLabel
                ]
            ]
        ]


collapseToggle : Texts -> Model -> msg -> List (Html msg)
collapseToggle texts model m =
    if model.max >= model.all then
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
                [ text texts.showLessLabel
                ]
            ]
        ]
