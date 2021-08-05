{-
   Copyright 2020 Docspell Contributors

   SPDX-License-Identifier: GPL-3.0-or-later
-}


module Comp.CustomFieldInput exposing
    ( FieldResult(..)
    , Model
    , Msg
    , UpdateResult
    , init
    , initWith
    , update
    , updateSearch
    , view2
    )

import Api.Model.CustomField exposing (CustomField)
import Api.Model.ItemFieldValue exposing (ItemFieldValue)
import Comp.DatePicker
import Comp.MenuBar as MB
import Data.CustomFieldType exposing (CustomFieldType)
import Data.Icons as Icons
import Data.Money exposing (MoneyParseError(..))
import Date exposing (Date)
import DatePicker exposing (DatePicker)
import Html exposing (..)
import Html.Attributes exposing (..)
import Html.Events exposing (onClick, onInput)
import Messages.Comp.CustomFieldInput exposing (Texts)
import Styles as S
import Util.CustomField
import Util.Maybe


type alias Model =
    { fieldModel : FieldModel
    , field : CustomField
    }


type FieldError
    = NoValue
    | NotANumber String
    | NotMoney MoneyParseError


type alias FloatModel =
    { input : String
    , result : Result FieldError Float
    }


type FieldModel
    = TextField (Maybe String)
    | NumberField FloatModel
    | MoneyField FloatModel
    | BoolField Bool
    | DateField (Maybe Date) DatePicker


type Msg
    = NumberMsg String
    | MoneyMsg String
    | DateMsg DatePicker.Msg
    | SetText String
    | ToggleBool
    | Remove


fieldType : CustomField -> CustomFieldType
fieldType field =
    Data.CustomFieldType.fromString field.ftype
        |> Maybe.withDefault Data.CustomFieldType.Text


errorMsg : Texts -> Model -> Maybe String
errorMsg texts model =
    let
        parseMsg isMoneyField perr =
            case perr of
                NoValue ->
                    if isMoneyField then
                        Just <| texts.errorNoAmount

                    else
                        Just <| texts.errorNoNumber

                NotANumber str ->
                    Just <| texts.errorNotANumber str

                NotMoney (RequireTwoDigitsAfterDot _) ->
                    Just "Two digits required after the dot."

                NotMoney (NoOrTooManyPoints _) ->
                    Just "One single dot + digits required for money."
    in
    case model.fieldModel of
        NumberField fm ->
            case fm.result of
                Ok _ ->
                    Nothing

                Err parseError ->
                    parseMsg False parseError

        MoneyField fm ->
            case fm.result of
                Ok _ ->
                    Nothing

                Err parseError ->
                    parseMsg True parseError

        TextField mt ->
            if mt == Nothing then
                Just texts.errorNoValue

            else
                Nothing

        _ ->
            Nothing


init : CustomField -> ( Model, Cmd Msg )
init field =
    let
        ( dm, dc ) =
            Comp.DatePicker.init
    in
    ( { field = field
      , fieldModel =
            case fieldType field of
                Data.CustomFieldType.Text ->
                    TextField Nothing

                Data.CustomFieldType.Numeric ->
                    NumberField (FloatModel "" (Err NoValue))

                Data.CustomFieldType.Money ->
                    MoneyField (FloatModel "" (Err NoValue))

                Data.CustomFieldType.Boolean ->
                    BoolField False

                Data.CustomFieldType.Date ->
                    DateField Nothing dm
      }
    , if fieldType field == Data.CustomFieldType.Date then
        Cmd.map DateMsg dc

      else
        Cmd.none
    )


initWith : ItemFieldValue -> ( Model, Cmd Msg )
initWith value =
    let
        field =
            CustomField value.id value.name value.label value.ftype 0 0

        ( dm, dc ) =
            Comp.DatePicker.init
    in
    ( { field = field
      , fieldModel =
            case fieldType field of
                Data.CustomFieldType.Text ->
                    TextField (Just value.value)

                Data.CustomFieldType.Numeric ->
                    let
                        ( fm, _ ) =
                            updateFloatModel False value.value string2Float identity
                    in
                    NumberField fm

                Data.CustomFieldType.Money ->
                    let
                        ( fm, _ ) =
                            updateFloatModel
                                False
                                value.value
                                (Data.Money.fromString >> Result.mapError NotMoney)
                                Data.Money.normalizeInput
                    in
                    MoneyField fm

                Data.CustomFieldType.Boolean ->
                    BoolField (value.value == "true")

                Data.CustomFieldType.Date ->
                    case Date.fromIsoString value.value of
                        Ok d ->
                            DateField (Just d) dm

                        Err _ ->
                            DateField Nothing dm
      }
    , if fieldType field == Data.CustomFieldType.Date then
        Cmd.map DateMsg dc

      else
        Cmd.none
    )



--- Update


type FieldResult
    = NoResult
    | RemoveField
    | Value String


type alias UpdateResult =
    { model : Model
    , cmd : Cmd Msg
    , result : FieldResult
    }


update : Msg -> Model -> UpdateResult
update =
    update1 False


updateSearch : Msg -> Model -> UpdateResult
updateSearch =
    update1 True


update1 : Bool -> Msg -> Model -> UpdateResult
update1 forSearch msg model =
    case ( msg, model.fieldModel ) of
        ( SetText str, TextField _ ) ->
            let
                newValue =
                    Util.Maybe.fromString str

                model_ =
                    { model | fieldModel = TextField newValue }
            in
            UpdateResult model_ Cmd.none (Maybe.map Value newValue |> Maybe.withDefault NoResult)

        ( NumberMsg str, NumberField _ ) ->
            let
                ( fm, res ) =
                    updateFloatModel forSearch str string2Float identity

                model_ =
                    { model | fieldModel = NumberField fm }
            in
            UpdateResult model_ Cmd.none res

        ( MoneyMsg str, MoneyField _ ) ->
            let
                ( fm, res ) =
                    updateFloatModel
                        forSearch
                        str
                        (Data.Money.fromString >> Result.mapError NotMoney)
                        Data.Money.normalizeInput

                model_ =
                    { model | fieldModel = MoneyField fm }
            in
            UpdateResult model_ Cmd.none res

        ( ToggleBool, BoolField b ) ->
            let
                model_ =
                    { model | fieldModel = BoolField (not b) }

                value =
                    Util.CustomField.boolValue (not b)
            in
            UpdateResult model_ Cmd.none (Value value)

        ( DateMsg lm, DateField old picker ) ->
            let
                ( picker_, event ) =
                    Comp.DatePicker.updateDefault lm picker

                ( newDate, value ) =
                    case event of
                        DatePicker.Picked date ->
                            ( Just date, Value (Date.toIsoString date) )

                        DatePicker.None ->
                            ( old, NoResult )

                        DatePicker.FailedInput (DatePicker.Invalid str) ->
                            if forSearch && hasWildCards str then
                                ( Nothing, Value str )

                            else
                                ( old, NoResult )

                        DatePicker.FailedInput _ ->
                            ( old, NoResult )

                model_ =
                    { model | fieldModel = DateField newDate picker_ }
            in
            UpdateResult model_ Cmd.none value

        ( Remove, _ ) ->
            UpdateResult model Cmd.none RemoveField

        -- no other possibilities, not well encoded here
        _ ->
            UpdateResult model Cmd.none NoResult


updateFloatModel :
    Bool
    -> String
    -> (String -> Result FieldError Float)
    -> (String -> String)
    -> ( FloatModel, FieldResult )
updateFloatModel forSearch msg parse normalize =
    if forSearch && hasWildCards msg then
        ( { input = normalize msg
          , result = Ok 0
          }
        , Value (normalize msg)
        )

    else
        case parse msg of
            Ok n ->
                ( { input = normalize msg
                  , result = Ok n
                  }
                , Value (normalize msg)
                )

            Err err ->
                ( { input = msg
                  , result = Err err
                  }
                , NoResult
                )


hasWildCards : String -> Bool
hasWildCards msg =
    String.startsWith "*" msg || String.endsWith "*" msg



--- View2


view2 : Texts -> String -> Maybe String -> Model -> Html Msg
view2 texts classes icon model =
    let
        error =
            errorMsg texts model
    in
    div
        [ class classes
        ]
        [ label [ class S.inputLabel ]
            [ mkLabel model |> text
            ]
        , makeInput2 icon model
        , div
            [ class S.errorMessage
            , class "text-sm px-2 py-1 mt-1"
            , classList
                [ ( "hidden", error == Nothing )
                ]
            ]
            [ Maybe.withDefault "" error |> text
            ]
        ]


removeButton2 : String -> Html Msg
removeButton2 classes =
    a
        [ class classes
        , class S.inputLeftIconLinkSidebar
        , href "#"
        , title "Remove this value"
        , onClick Remove
        ]
        [ i [ class "fa fa-trash-alt font-thin" ] []
        ]


makeInput2 : Maybe String -> Model -> Html Msg
makeInput2 icon model =
    let
        iconOr c =
            Maybe.withDefault c icon
    in
    case model.fieldModel of
        TextField v ->
            div [ class "flex flex-row relative" ]
                [ input
                    [ type_ "text"
                    , Maybe.withDefault "" v |> value
                    , onInput SetText
                    , class S.textInputSidebar
                    , class "pl-10 pr-10"
                    ]
                    []
                , removeButton2 ""
                , i
                    [ class (iconOr <| Icons.customFieldType2 Data.CustomFieldType.Text)
                    , class S.dateInputIcon
                    ]
                    []
                ]

        NumberField nm ->
            div [ class "flex flex-row relative" ]
                [ input
                    [ type_ "text"
                    , value nm.input
                    , onInput NumberMsg
                    , class S.textInputSidebar
                    , class "pl-10 pr-10"
                    ]
                    []
                , removeButton2 ""
                , i
                    [ class (iconOr <| Icons.customFieldType2 Data.CustomFieldType.Numeric)
                    , class S.dateInputIcon
                    ]
                    []
                ]

        MoneyField nm ->
            div [ class "flex flex-row relative" ]
                [ input
                    [ type_ "text"
                    , value nm.input
                    , class S.textInputSidebar
                    , class "pl-10 pr-10"
                    , onInput MoneyMsg
                    ]
                    []
                , removeButton2 ""
                , i
                    [ class (iconOr <| Icons.customFieldType2 Data.CustomFieldType.Money)
                    , class S.dateInputIcon
                    ]
                    []
                ]

        BoolField b ->
            div [ class "flex flex-row items-center" ]
                [ MB.viewItem <|
                    MB.Checkbox
                        { id = "customfield-flag-" ++ model.field.name
                        , tagger = \_ -> ToggleBool
                        , label = mkLabel model
                        , value = b
                        }
                , div [ class "flex-grow" ] []
                , a
                    [ class S.secondaryButton
                    , class "shadow-none"
                    , href "#"
                    , title "Remove this value"
                    , onClick Remove
                    ]
                    [ i [ class "fa fa-trash-alt font-thin" ] []
                    ]
                ]

        DateField v dp ->
            div [ class "flex flex-row relative" ]
                [ Html.map DateMsg
                    (Comp.DatePicker.view v Comp.DatePicker.defaultSettings dp)
                , removeButton2 ""
                , i
                    [ class (iconOr <| Icons.customFieldType2 Data.CustomFieldType.Date)
                    , class S.dateInputIcon
                    ]
                    []
                ]



--- Helper


mkLabel : Model -> String
mkLabel model =
    Maybe.withDefault model.field.name model.field.label


string2Float : String -> Result FieldError Float
string2Float str =
    case String.toFloat str of
        Just n ->
            Ok n

        Nothing ->
            Err (NotANumber str)
