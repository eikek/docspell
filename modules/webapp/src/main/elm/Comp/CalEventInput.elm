module Comp.CalEventInput exposing
    ( Model
    , Msg
    , init
    , initialSchedule
    , update
    , view
    )

import Api
import Api.Model.CalEventCheck exposing (CalEventCheck)
import Api.Model.CalEventCheckResult exposing (CalEventCheckResult)
import Data.Flags exposing (Flags)
import Html exposing (..)
import Html.Attributes exposing (..)
import Html.Events exposing (onInput)
import Http
import Util.Http
import Util.Maybe
import Util.Time


type alias Model =
    { year : String
    , month : String
    , day : String
    , hour : String
    , minute : String
    , weekday : Maybe String
    , event : Maybe String
    , checkResult : Maybe CalEventCheckResult
    }


type Msg
    = SetYear String
    | SetMonth String
    | SetDay String
    | SetHour String
    | SetMinute String
    | SetWeekday String
    | CheckInputMsg (Result Http.Error CalEventCheckResult)


initialSchedule : String
initialSchedule =
    "*-*-01 00:00"


init : Flags -> ( Model, Cmd Msg )
init flags =
    let
        model =
            { year = "*"
            , month = "*"
            , day = "1"
            , hour = "0"
            , minute = "0"
            , weekday = Nothing
            , event = Nothing
            , checkResult = Nothing
            }
    in
    ( model, checkInput flags model )


toEvent : Model -> String
toEvent model =
    let
        datetime =
            model.year
                ++ "-"
                ++ model.month
                ++ "-"
                ++ model.day
                ++ " "
                ++ model.hour
                ++ ":"
                ++ model.minute
    in
    case model.weekday of
        Just wd ->
            wd ++ " " ++ datetime

        Nothing ->
            datetime


checkInput : Flags -> Model -> Cmd Msg
checkInput flags model =
    let
        event =
            toEvent model

        input =
            CalEventCheck event
    in
    Api.checkCalEvent flags input CheckInputMsg


withCheckInput : Flags -> Model -> ( Model, Cmd Msg, Maybe String )
withCheckInput flags model =
    ( model, checkInput flags model, Nothing )


isCheckError : Model -> Bool
isCheckError model =
    Maybe.map .success model.checkResult
        |> Maybe.withDefault True
        |> not


update : Flags -> Msg -> Model -> ( Model, Cmd Msg, Maybe String )
update flags msg model =
    case msg of
        SetYear str ->
            withCheckInput flags { model | year = str }

        SetMonth str ->
            withCheckInput flags { model | month = str }

        SetDay str ->
            withCheckInput flags { model | day = str }

        SetHour str ->
            withCheckInput flags { model | hour = str }

        SetMinute str ->
            withCheckInput flags { model | minute = str }

        SetWeekday str ->
            withCheckInput flags { model | weekday = Util.Maybe.fromString str }

        CheckInputMsg (Ok res) ->
            let
                m =
                    { model
                        | event = res.event
                        , checkResult = Just res
                    }
            in
            ( m, Cmd.none, res.event )

        CheckInputMsg (Err err) ->
            let
                emptyResult =
                    Api.Model.CalEventCheckResult.empty

                m =
                    { model
                        | event = Nothing
                        , checkResult =
                            Just
                                { emptyResult
                                    | success = False
                                    , message = Util.Http.errorToString err
                                }
                    }
            in
            ( m, Cmd.none, Nothing )


view : String -> Model -> Html Msg
view extraClasses model =
    let
        yearLen =
            Basics.max 4 (String.length model.year)

        otherLen str =
            Basics.max 2 (String.length str)
    in
    div
        [ classList
            [ ( extraClasses, True )
            ]
        ]
        [ div [ class "calevent-input" ]
            [ div []
                [ label [] [ text "Weekday" ]
                , input
                    [ type_ "text"
                    , class "time-input"
                    , size
                        (Maybe.map otherLen model.weekday
                            |> Maybe.withDefault 4
                        )
                    , Maybe.withDefault "" model.weekday
                        |> value
                    , onInput SetWeekday
                    ]
                    []
                ]
            , div []
                [ label [] [ text "Year" ]
                , input
                    [ type_ "text"
                    , class "time-input"
                    , size yearLen
                    , value model.year
                    , onInput SetYear
                    ]
                    []
                ]
            , div [ class "date separator" ]
                [ text "–"
                ]
            , div []
                [ label [] [ text "Month" ]
                , input
                    [ type_ "text"
                    , class "time-input"
                    , size (otherLen model.month)
                    , value model.month
                    , onInput SetMonth
                    ]
                    []
                ]
            , div [ class "date separator" ]
                [ text "–"
                ]
            , div []
                [ label [] [ text "Day" ]
                , input
                    [ type_ "text"
                    , class "time-input"
                    , size (otherLen model.day)
                    , value model.day
                    , onInput SetDay
                    ]
                    []
                ]
            , div [ class "datetime separator" ]
                [ text "  "
                ]
            , div []
                [ label [] [ text "Hour" ]
                , input
                    [ type_ "text"
                    , class "time-input"
                    , size (otherLen model.hour)
                    , value model.hour
                    , onInput SetHour
                    ]
                    []
                ]
            , div [ class "time separator" ]
                [ text ":"
                ]
            , div []
                [ label [] [ text "Minute" ]
                , input
                    [ type_ "text"
                    , class "time-input"
                    , size (otherLen model.minute)
                    , value model.minute
                    , onInput SetMinute
                    ]
                    []
                ]
            ]
        , div
            [ classList
                [ ( "ui basic red pointing label", True )
                , ( "hidden invisible", not (isCheckError model) )
                ]
            ]
            [ text "Error: "
            , Maybe.map .message model.checkResult
                |> Maybe.withDefault ""
                |> text
            ]
        , div
            [ classList
                [ ( "ui  message", True )
                , ( "hidden invisible"
                  , model.checkResult == Nothing || isCheckError model
                  )
                ]
            ]
            [ dl []
                [ dt []
                    [ text "Schedule: "
                    ]
                , dd []
                    [ code []
                        [ Maybe.andThen .event model.checkResult
                            |> Maybe.withDefault ""
                            |> text
                        ]
                    ]
                , dt []
                    [ text "Next: "
                    ]
                , dd []
                    (Maybe.map .next model.checkResult
                        |> Maybe.withDefault []
                        |> List.map Util.Time.formatDateTime
                        |> List.map text
                        |> List.intersperse (br [] [])
                    )
                ]
            ]
        ]
