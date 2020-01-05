module Comp.IntField exposing (Model, Msg, init, update, view)

import Html exposing (..)
import Html.Attributes exposing (..)
import Html.Events exposing (onInput)


type alias Model =
    { min : Maybe Int
    , max : Maybe Int
    , label : String
    , error : Maybe String
    , lastInput : String
    }


type Msg
    = SetValue String


init : Maybe Int -> Maybe Int -> String -> Model
init min max label =
    { min = min
    , max = max
    , label = label
    , error = Nothing
    , lastInput = ""
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
                    ( { m | error = Just ("'" ++ str ++ "' is not a valid number!") }
                    , Nothing
                    )


view : Maybe Int -> Model -> Html Msg
view nval model =
    div
        [ classList
            [ ( "field", True )
            , ( "error", model.error /= Nothing )
            ]
        ]
        [ label [] [ text model.label ]
        , input
            [ type_ "text"
            , Maybe.map String.fromInt nval
                |> Maybe.withDefault model.lastInput
                |> value
            , onInput SetValue
            ]
            []
        , div
            [ classList
                [ ( "ui pointing red basic label", True )
                , ( "hidden", model.error == Nothing )
                ]
            ]
            [ Maybe.withDefault "" model.error |> text
            ]
        ]
