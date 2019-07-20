module Page.Home.View exposing (view)

import Html exposing (..)
import Html.Attributes exposing (..)
import Html.Events exposing (onClick)

import Page exposing (Page(..))
import Page.Home.Data exposing (..)
import Data.Flags

view: Model -> Html Msg
view model =
    div [class "home-page ui fluid grid"]
        [div [class "three wide column"]
             [h3 [][text "Menu"]
             ]
        ,div [class "seven wide column", style "border-left" "1px solid"]
             [h3 [][text "List"]
             ]
        ,div [class "six wide column", style "border-left" "1px solid", style "height" "100vh"]
             [h3 [][text "DocView"]
             ]
        ]
