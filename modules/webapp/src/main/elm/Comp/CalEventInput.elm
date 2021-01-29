module Comp.CalEventInput exposing
    ( Model
    , Msg
    , init
    , initDefault
    , update
    , view
    , view2
    )

import Api
import Api.Model.CalEventCheck exposing (CalEventCheck)
import Api.Model.CalEventCheckResult exposing (CalEventCheckResult)
import Data.CalEvent exposing (CalEvent)
import Data.Flags exposing (Flags)
import Data.Validated exposing (Validated(..))
import Html exposing (..)
import Html.Attributes exposing (..)
import Html.Events exposing (onInput)
import Http
import Styles as S
import Util.Http
import Util.Maybe
import Util.Time


type alias Model =
    { checkResult : Maybe CalEventCheckResult
    }


type Msg
    = SetYear String
    | SetMonth String
    | SetDay String
    | SetHour String
    | SetMinute String
    | SetWeekday String
    | CheckInputMsg CalEvent (Result Http.Error CalEventCheckResult)


initDefault : Model
initDefault =
    Model Nothing


init : Flags -> CalEvent -> ( Model, Cmd Msg )
init flags ev =
    ( Model Nothing, checkInput flags ev )


checkInput : Flags -> CalEvent -> Cmd Msg
checkInput flags ev =
    let
        eventStr =
            Data.CalEvent.makeEvent ev

        input =
            CalEventCheck eventStr
    in
    Api.checkCalEvent flags input (CheckInputMsg ev)


withCheckInput : Flags -> CalEvent -> Model -> ( Model, Cmd Msg, Validated CalEvent )
withCheckInput flags ev model =
    ( model, checkInput flags ev, Unknown ev )


isCheckError : Model -> Bool
isCheckError model =
    Maybe.map .success model.checkResult
        |> Maybe.withDefault True
        |> not


update : Flags -> CalEvent -> Msg -> Model -> ( Model, Cmd Msg, Validated CalEvent )
update flags ev msg model =
    case msg of
        SetYear str ->
            withCheckInput flags { ev | year = str } model

        SetMonth str ->
            withCheckInput flags { ev | month = str } model

        SetDay str ->
            withCheckInput flags { ev | day = str } model

        SetHour str ->
            withCheckInput flags { ev | hour = str } model

        SetMinute str ->
            withCheckInput flags { ev | minute = str } model

        SetWeekday str ->
            withCheckInput flags { ev | weekday = Util.Maybe.fromString str } model

        CheckInputMsg event (Ok res) ->
            let
                m =
                    { model | checkResult = Just res }
            in
            ( m
            , Cmd.none
            , if res.success then
                Valid event

              else
                Invalid [ res.message ] event
            )

        CheckInputMsg event (Err err) ->
            let
                emptyResult =
                    Api.Model.CalEventCheckResult.empty

                m =
                    { model
                        | checkResult =
                            Just
                                { emptyResult
                                    | success = False
                                    , message = Util.Http.errorToString err
                                }
                    }
            in
            ( m, Cmd.none, Unknown event )



--- View


view : String -> CalEvent -> Model -> Html Msg
view extraClasses ev model =
    let
        yearLen =
            Basics.max 4 (String.length ev.year)

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
                        (Maybe.map otherLen ev.weekday
                            |> Maybe.withDefault 4
                        )
                    , Maybe.withDefault "" ev.weekday
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
                    , value ev.year
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
                    , size (otherLen ev.month)
                    , value ev.month
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
                    , size (otherLen ev.day)
                    , value ev.day
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
                    , size (otherLen ev.hour)
                    , value ev.hour
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
                    , size (otherLen ev.minute)
                    , value ev.minute
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



--- View2


view2 : String -> CalEvent -> Model -> Html Msg
view2 extraClasses ev model =
    let
        yearLen =
            Basics.max 4 (String.length ev.year)

        otherLen str =
            Basics.max 2 (String.length str)

        styleInput =
            "border-0 border-b rounded-l-none rounded-r-none text-center px-1"
    in
    div
        [ classList
            [ ( extraClasses, True )
            ]
        , class "flex flex-col"
        ]
        [ div
            [ class "flex flex-row items-center border px-2 py-2 text-center"
            , class S.border
            ]
            [ div [ class "flex flex-col space-y-2 mr-2" ]
                [ label
                    [ class S.inputLabel
                    ]
                    [ text "Weekday" ]
                , input
                    [ type_ "text"
                    , class S.textInput
                    , class styleInput
                    , size
                        (Maybe.map otherLen ev.weekday
                            |> Maybe.withDefault 4
                        )
                    , Maybe.withDefault "" ev.weekday
                        |> value
                    , onInput SetWeekday
                    ]
                    []
                ]
            , div [ class "flex flex-col space-y-2 mr-2" ]
                [ label [ class S.inputLabel ]
                    [ text "Year" ]
                , input
                    [ type_ "text"
                    , class S.textInput
                    , class styleInput
                    , size yearLen
                    , value ev.year
                    , onInput SetYear
                    ]
                    []
                ]
            , div [ class "mt-6 mr-2" ]
                [ text "–"
                ]
            , div [ class "flex flex-col space-y-2 mr-2" ]
                [ label [ class S.inputLabel ]
                    [ text "Month" ]
                , input
                    [ type_ "text"
                    , class styleInput
                    , class S.textInput
                    , size (otherLen ev.month)
                    , value ev.month
                    , onInput SetMonth
                    ]
                    []
                ]
            , div [ class "mt-6" ]
                [ text "–"
                ]
            , div [ class "flex flex-col space-y-2 mr-4 mr-2" ]
                [ label [ class S.inputLabel ]
                    [ text "Day"
                    ]
                , input
                    [ type_ "text"
                    , class S.textInput
                    , class styleInput
                    , size (otherLen ev.day)
                    , value ev.day
                    , onInput SetDay
                    ]
                    []
                ]
            , div [ class "flex flex-col space-y-2 mr-2" ]
                [ label [ class S.inputLabel ]
                    [ text "Hour" ]
                , input
                    [ type_ "text"
                    , class styleInput
                    , class S.textInput
                    , size (otherLen ev.hour)
                    , value ev.hour
                    , onInput SetHour
                    ]
                    []
                ]
            , div [ class "mt-6 mr-2" ]
                [ text ":"
                ]
            , div [ class "flex flex-col space-y-2" ]
                [ label [ class S.inputLabel ]
                    [ text "Minute"
                    ]
                , input
                    [ type_ "text"
                    , class S.textInput
                    , class styleInput
                    , size (otherLen ev.minute)
                    , value ev.minute
                    , onInput SetMinute
                    ]
                    []
                ]
            ]
        , div
            [ classList
                [ ( "hidden invisible", not (isCheckError model) )
                ]
            , class S.errorMessage
            ]
            [ text "Error: "
            , Maybe.map .message model.checkResult
                |> Maybe.withDefault ""
                |> text
            ]
        , div
            [ classList
                [ ( "hidden1"
                  , model.checkResult == Nothing || isCheckError model
                  )
                ]
            , class "px-2 pt-4 pb-2 border-0 border-l border-b border-r bg-gray-50 dark:bg-bluegray-700"
            , class S.border
            ]
            [ div []
                [ div [ class S.inputLabel ]
                    [ text "Schedule: "
                    ]
                , div [ class "px-12 font-mono " ]
                    [ Maybe.andThen .event model.checkResult
                        |> Maybe.withDefault ""
                        |> text
                    ]
                , div [ class S.inputLabel ]
                    [ text "Next: "
                    ]
                , ul [ class "list-decimal list-inside text-sm" ]
                    (Maybe.map .next model.checkResult
                        |> Maybe.withDefault []
                        |> List.map Util.Time.formatDateTime
                        |> List.map (\s -> li [ class "" ] [ text s ])
                    )
                ]
            ]
        ]
