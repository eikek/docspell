{-
   Copyright 2020 Docspell Contributors

   SPDX-License-Identifier: GPL-3.0-or-later
-}


module Comp.YesNoDimmer exposing
    ( Model
    , Msg(..)
    , Settings
    , activate
    , defaultSettings
    , disable
    , emptyModel
    , initActive
    , initInactive
    , update
    , viewN
    )

import Html exposing (..)
import Html.Attributes exposing (..)
import Html.Events exposing (onClick)
import Styles as S


type alias Model =
    { active : Bool
    }


emptyModel : Model
emptyModel =
    { active = False
    }


initInactive : Model
initInactive =
    { active = False
    }


initActive : Model
initActive =
    { active = True
    }


type Msg
    = Activate
    | Disable
    | ConfirmDelete


type alias Settings =
    { message : String
    , headerIcon : String
    , headerClass : String
    , confirmButton : String
    , cancelButton : String
    , extraClass : String
    }


defaultSettings : String -> String -> String -> Settings
defaultSettings msg yesLabel noLabel =
    { message = msg
    , headerIcon = "fa fa-exclamation-circle mr-3"
    , headerClass = "text-2xl font-bold text-center w-full"
    , confirmButton = yesLabel
    , cancelButton = noLabel
    , extraClass = ""
    }


activate : Msg
activate =
    Activate


disable : Msg
disable =
    Disable


update : Msg -> Model -> ( Model, Bool )
update msg model =
    case msg of
        Activate ->
            ( { model | active = True }, False )

        Disable ->
            ( { model | active = False }, False )

        ConfirmDelete ->
            ( { model | active = False }, True )



--- View2


viewN : Bool -> Settings -> Model -> Html Msg
viewN active settings model =
    div
        [ class S.dimmer
        , class settings.extraClass
        , classList
            [ ( "hidden", not active || not model.active )
            ]
        ]
        [ div [ class settings.headerClass ]
            [ i
                [ class settings.headerIcon
                , class "text-gray-200 font-semibold"
                , classList [ ( "hidden", settings.headerClass == "" ) ]
                ]
                []
            , span [ class "text-gray-200 font-semibold" ]
                [ text settings.message
                ]
            ]
        , div [ class "flex flex-row space-x-2 text-xs mt-2" ]
            [ a
                [ class (S.primaryButton ++ "block font-semibold")
                , href "#"
                , onClick ConfirmDelete
                ]
                [ text settings.confirmButton
                ]
            , a
                [ class (S.secondaryButton ++ "block font-semibold")
                , href "#"
                , onClick Disable
                ]
                [ text settings.cancelButton
                ]
            ]
        ]
