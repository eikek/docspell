{-
   Copyright 2020 Eike K. & Contributors

   SPDX-License-Identifier: AGPL-3.0-or-later
-}


module Comp.CustomFieldInput exposing
    ( FieldResult(..)
    , Model
    , Msg
    , UpdateResult
    , init
    , init1
    , initWith
    , initWith1
    , update
    , updateSearch
    , view2
    )

import Api.Model.CustomField exposing (CustomField)
import Api.Model.ItemFieldValue exposing (ItemFieldValue)
import Comp.DatePicker
import Comp.MenuBar as MB
import Comp.SimpleTextInput
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


type alias Model =
    { fieldModel : FieldModel
    , field : CustomField
    }


type FieldError
    = NoValue
    | NotANumber String
    | NotMoney MoneyParseError


type alias FloatModel =
    { input : Comp.SimpleTextInput.Model
    , result : Result FieldError Float
    }


type alias MoneyModel =
    { input : String
    , result : Result FieldError Float
    }


type FieldModel
    = TextField Comp.SimpleTextInput.Model
    | NumberField FloatModel
    | MoneyField MoneyModel
    | BoolField Bool
    | DateField (Maybe Date) DatePicker


type Msg
    = NumberMsg Comp.SimpleTextInput.Msg
    | MoneyMsg String
    | DateMsg DatePicker.Msg
    | SetTextMsg Comp.SimpleTextInput.Msg
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
            if Comp.SimpleTextInput.getValue mt == Nothing then
                Just texts.errorNoValue

            else
                Nothing

        _ ->
            Nothing


init : CustomField -> ( Model, Cmd Msg )
init =
    init1 Comp.SimpleTextInput.defaultConfig


init1 : Comp.SimpleTextInput.Config -> CustomField -> ( Model, Cmd Msg )
init1 cfg field =
    let
        ( dm, dc ) =
            Comp.DatePicker.init
    in
    ( { field = field
      , fieldModel =
            case fieldType field of
                Data.CustomFieldType.Text ->
                    TextField (Comp.SimpleTextInput.init cfg Nothing)

                Data.CustomFieldType.Numeric ->
                    NumberField (FloatModel (Comp.SimpleTextInput.init cfg Nothing) (Err NoValue))

                Data.CustomFieldType.Money ->
                    MoneyField (MoneyModel "" (Err NoValue))

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
initWith =
    initWith1 Comp.SimpleTextInput.defaultConfig


initWith1 : Comp.SimpleTextInput.Config -> ItemFieldValue -> ( Model, Cmd Msg )
initWith1 cfg value =
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
                    TextField (Comp.SimpleTextInput.init cfg <| Just value.value)

                Data.CustomFieldType.Numeric ->
                    let
                        fm =
                            Comp.SimpleTextInput.init cfg <| Just value.value

                        res =
                            string2Float value.value
                    in
                    NumberField { input = fm, result = res }

                Data.CustomFieldType.Money ->
                    let
                        ( fm, _ ) =
                            updateMoneyModel
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
    , sub : Sub Msg
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
        ( SetTextMsg lm, TextField tm ) ->
            let
                result =
                    Comp.SimpleTextInput.update lm tm

                model_ =
                    { model | fieldModel = TextField result.model }

                cmd =
                    Cmd.map SetTextMsg result.cmd

                sub =
                    Sub.map SetTextMsg result.sub

                fres =
                    case result.change of
                        Comp.SimpleTextInput.ValueUpdated v ->
                            Maybe.map Value v |> Maybe.withDefault NoResult

                        Comp.SimpleTextInput.ValueUnchanged ->
                            NoResult
            in
            UpdateResult model_ cmd fres sub

        ( NumberMsg lm, NumberField tm ) ->
            updateFloatModel forSearch model lm tm string2Float

        ( MoneyMsg str, MoneyField _ ) ->
            let
                ( fm, res ) =
                    updateMoneyModel
                        forSearch
                        str
                        (Data.Money.fromString >> Result.mapError NotMoney)
                        Data.Money.normalizeInput

                model_ =
                    { model | fieldModel = MoneyField fm }
            in
            UpdateResult model_ Cmd.none res Sub.none

        ( ToggleBool, BoolField b ) ->
            let
                model_ =
                    { model | fieldModel = BoolField (not b) }

                value =
                    Util.CustomField.boolValue (not b)
            in
            UpdateResult model_ Cmd.none (Value value) Sub.none

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
            UpdateResult model_ Cmd.none value Sub.none

        ( Remove, _ ) ->
            UpdateResult model Cmd.none RemoveField Sub.none

        -- no other possibilities, not well encoded here
        _ ->
            UpdateResult model Cmd.none NoResult Sub.none


updateMoneyModel :
    Bool
    -> String
    -> (String -> Result FieldError Float)
    -> (String -> String)
    -> ( MoneyModel, FieldResult )
updateMoneyModel forSearch msg parse normalize =
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


updateFloatModel :
    Bool
    -> Model
    -> Comp.SimpleTextInput.Msg
    -> FloatModel
    -> (String -> Result FieldError Float)
    -> UpdateResult
updateFloatModel forSearch model lm fm parse =
    let
        result =
            Comp.SimpleTextInput.update lm fm.input

        ( floatModel, fieldResult ) =
            case result.change of
                Comp.SimpleTextInput.ValueUnchanged ->
                    ( { fm | input = result.model }, NoResult )

                Comp.SimpleTextInput.ValueUpdated v ->
                    let
                        value =
                            Maybe.withDefault "" v
                    in
                    if forSearch && hasWildCards value then
                        ( { input = result.model
                          , result = Ok 0
                          }
                        , Value value
                        )

                    else
                        case parse value of
                            Ok n ->
                                ( { input = result.model
                                  , result = Ok n
                                  }
                                , Value value
                                )

                            Err err ->
                                ( { input = result.model
                                  , result = Err err
                                  }
                                , NoResult
                                )

        model_ =
            { model | fieldModel = NumberField floatModel }
    in
    UpdateResult model_ (Cmd.map NumberMsg result.cmd) fieldResult (Sub.map NumberMsg result.sub)


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
                [ Html.map SetTextMsg
                    (Comp.SimpleTextInput.view [ class S.textInputSidebar, class "pl-10 pr-10" ] v)
                , removeButton2 ""
                , i
                    [ class (iconOr <| Icons.customFieldType2 Data.CustomFieldType.Text)
                    , class S.dateInputIcon
                    ]
                    []
                ]

        NumberField nm ->
            div [ class "flex flex-row relative" ]
                [ Html.map NumberMsg
                    (Comp.SimpleTextInput.view [ class S.textInputSidebar, class "pl-10 pr-10" ] nm.input)
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
