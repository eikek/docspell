{-
   Copyright 2020 Eike K. & Contributors

   SPDX-License-Identifier: AGPL-3.0-or-later
-}


module Comp.IntField exposing
    ( Model
    , Msg
    , ViewSettings
    , init
    , update
    , view
    )

import Html exposing (..)
import Html.Attributes exposing (..)
import Html.Events exposing (onInput)
import Markdown
import Styles as S


type alias Model =
    { min : Maybe Int
    , max : Maybe Int
    , error : Maybe String
    , lastInput : String
    , optional : Bool
    }


type Msg
    = SetValue String


init : Maybe Int -> Maybe Int -> Bool -> Model
init min max opt =
    { min = min
    , max = max
    , error = Nothing
    , lastInput = ""
    , optional = opt
    }


tooLow : Model -> Int -> Bool
tooLow model n =
    Maybe.map ((<) n) model.min
        |> Maybe.withDefault False


tooHigh : Model -> Int -> Bool
tooHigh model n =
    Maybe.map ((>) n) model.max
        |> Maybe.withDefault False


update : Msg -> Model -> ( Model, Maybe Int )
update msg model =
    let
        tooHighError =
            Maybe.withDefault 0 model.max
                |> String.fromInt
                |> (++) "Number must be <= "

        tooLowError =
            Maybe.withDefault 0 model.min
                |> String.fromInt
                |> (++) "Number must be >= "
    in
    case msg of
        SetValue str ->
            let
                m =
                    { model | lastInput = str }
            in
            case String.toInt str of
                Just n ->
                    if tooLow model n then
                        ( { m | error = Just tooLowError }
                        , Nothing
                        )

                    else if tooHigh model n then
                        ( { m | error = Just tooHighError }
                        , Nothing
                        )

                    else
                        ( { m | error = Nothing }, Just n )

                Nothing ->
                    if model.optional && String.trim str == "" then
                        ( { m | error = Nothing }, Nothing )

                    else
                        ( { m | error = Just ("'" ++ str ++ "' is not a valid number!") }
                        , Nothing
                        )



--- View2


type alias ViewSettings =
    { label : String
    , info : String
    , number : Maybe Int
    , classes : String
    }


view : ViewSettings -> Model -> Html Msg
view cfg model =
    div
        [ classList
            [ ( cfg.classes, True )
            , ( "error", model.error /= Nothing )
            ]
        ]
        [ label [ class S.inputLabel ]
            [ text cfg.label
            ]
        , input
            [ type_ "text"
            , Maybe.map String.fromInt cfg.number
                |> Maybe.withDefault model.lastInput
                |> value
            , onInput SetValue
            , class S.textInput
            ]
            []
        , span
            [ classList
                [ ( "hidden", cfg.info == "" )
                ]
            , class "opacity-50 text-sm"
            ]
            [ Markdown.toHtml [] cfg.info
            ]
        , div
            [ classList
                [ ( "hidden", model.error == Nothing )
                ]
            , class S.errorMessage
            ]
            [ Maybe.withDefault "" model.error |> text
            ]
        ]


viewWithInfo2 : String -> String -> Maybe Int -> String -> Model -> Html Msg
viewWithInfo2 label info nval classes model =
    let
        cfg =
            { label = label
            , info = info
            , number = nval
            , classes = classes
            }
    in
    view cfg model
