{-
  Copyright 2020 Docspell Contributors

  SPDX-License-Identifier: GPL-3.0-or-later
-}

module Comp.PasswordInput exposing
    ( Model
    , Msg
    , init
    , update
    , view2
    )

import Html exposing (..)
import Html.Attributes exposing (..)
import Html.Events exposing (onClick, onInput)
import Styles as S
import Util.Maybe


type alias Model =
    { show : Bool
    }


init : Model
init =
    { show = False
    }


type Msg
    = ToggleShow (Maybe String)
    | SetPassword String


update : Msg -> Model -> ( Model, Maybe String )
update msg model =
    case msg of
        ToggleShow pw ->
            ( { model | show = not model.show }
            , pw
            )

        SetPassword str ->
            let
                pw =
                    Util.Maybe.fromString str
            in
            ( model, pw )



--- View2


type alias ViewSettings =
    { placeholder : String
    }


view2 : ViewSettings -> Maybe String -> Bool -> Model -> Html Msg
view2 cfg pw isError model =
    div [ class "relative" ]
        [ div [ class S.inputIcon ]
            [ i
                [ class "fa"
                , if model.show then
                    class "fa-lock-open"

                  else
                    class "fa-lock"
                ]
                []
            ]
        , input
            [ type_ <|
                if model.show then
                    "text"

                else
                    "password"
            , name "passw1"
            , autocomplete False
            , onInput SetPassword
            , Maybe.withDefault "" pw |> value
            , class ("pl-10 pr-10 py-2 rounded" ++ S.textInput)
            , class <|
                if isError then
                    S.inputErrorBorder

                else
                    ""
            , placeholder cfg.placeholder
            ]
            []
        , a
            [ class S.inputLeftIconLink
            , class <|
                if isError then
                    S.inputErrorBorder

                else
                    ""
            , onClick (ToggleShow pw)
            , href "#"
            ]
            [ i [ class "fa fa-eye" ] []
            ]
        ]
