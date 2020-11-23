module Comp.CustomFieldInput exposing
    ( FieldResult(..)
    , Model
    , Msg
    , UpdateResult
    , init
    , initWith
    , update
    , updateSearch
    , view
    )

import Api.Model.CustomField exposing (CustomField)
import Api.Model.ItemFieldValue exposing (ItemFieldValue)
import Comp.DatePicker
import Data.CustomFieldType exposing (CustomFieldType)
import Data.Icons as Icons
import Data.Money
import Date exposing (Date)
import DatePicker exposing (DatePicker)
import Html exposing (..)
import Html.Attributes exposing (..)
import Html.Events exposing (onCheck, onClick, onInput)
import Util.Maybe


type alias Model =
    { fieldModel : FieldModel
    , field : CustomField
    }


type alias FloatModel =
    { input : String
    , result : Result String Float
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


errorMsg : Model -> Maybe String
errorMsg model =
    let
        getMsg res =
            case res of
                Ok _ ->
                    Nothing

                Err m ->
                    Just m
    in
    case model.fieldModel of
        NumberField fm ->
            getMsg fm.result

        MoneyField fm ->
            getMsg fm.result

        TextField mt ->
            if mt == Nothing then
                Just "Please fill in some value"

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
                    NumberField (FloatModel "" (Err "No number given"))

                Data.CustomFieldType.Money ->
                    MoneyField (FloatModel "" (Err "No amount given"))

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
                                Data.Money.fromString
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
                        Data.Money.fromString
                        Data.Money.normalizeInput

                model_ =
                    { model | fieldModel = MoneyField fm }
            in
            UpdateResult model_ Cmd.none res

        ( ToggleBool, BoolField b ) ->
            let
                notb =
                    not b

                model_ =
                    { model | fieldModel = BoolField notb }

                value =
                    if notb then
                        "true"

                    else
                        "false"
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
    -> (String -> Result String Float)
    -> (String -> String)
    -> ( FloatModel, FieldResult )
updateFloatModel forSearch msg parse normalize =
    let
        hasWildCards =
            String.startsWith "*" msg || String.endsWith "*" msg
    in
    if forSearch && hasWildCards then
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



--- View


mkLabel : Model -> String
mkLabel model =
    Maybe.withDefault model.field.name model.field.label


removeButton : String -> Html Msg
removeButton classes =
    a
        [ class "ui icon button"
        , class classes
        , href "#"
        , title "Remove this value"
        , onClick Remove
        ]
        [ i [ class "trash alternate outline icon" ] []
        ]


view : String -> Maybe String -> Model -> Html Msg
view classes icon model =
    let
        error =
            errorMsg model
    in
    div
        [ class classes
        , classList
            [ ( "error", error /= Nothing )
            ]
        ]
        [ label []
            [ mkLabel model |> text
            ]
        , makeInput icon model
        , div
            [ class "ui red pointing basic label"
            , classList
                [ ( "invisible hidden", error == Nothing )
                ]
            ]
            [ Maybe.withDefault "" error |> text
            ]
        ]


makeInput : Maybe String -> Model -> Html Msg
makeInput icon model =
    let
        iconOr c =
            Maybe.withDefault c icon
    in
    case model.fieldModel of
        TextField v ->
            div [ class "ui action left icon input" ]
                [ input
                    [ type_ "text"
                    , Maybe.withDefault "" v |> value
                    , onInput SetText
                    ]
                    []
                , removeButton ""
                , i [ class (iconOr <| Icons.customFieldType Data.CustomFieldType.Text) ] []
                ]

        NumberField nm ->
            div [ class "ui action left icon input" ]
                [ input
                    [ type_ "text"
                    , value nm.input
                    , onInput NumberMsg
                    ]
                    []
                , removeButton ""
                , i [ class (iconOr <| Icons.customFieldType Data.CustomFieldType.Numeric) ] []
                ]

        MoneyField nm ->
            div [ class "ui action left icon input" ]
                [ input
                    [ type_ "text"
                    , value nm.input
                    , onInput MoneyMsg
                    ]
                    []
                , removeButton ""
                , i [ class (iconOr <| Icons.customFieldType Data.CustomFieldType.Money) ] []
                ]

        BoolField b ->
            div [ class "ui container" ]
                [ div [ class "ui checkbox" ]
                    [ input
                        [ type_ "checkbox"
                        , onCheck (\_ -> ToggleBool)
                        , checked b
                        ]
                        []
                    , label []
                        [ text (mkLabel model)
                        ]
                    ]
                , removeButton "right floated"
                ]

        DateField v dp ->
            div [ class "ui action left icon input" ]
                [ Html.map DateMsg
                    (Comp.DatePicker.view v Comp.DatePicker.defaultSettings dp)
                , removeButton ""
                , i [ class (iconOr <| Icons.customFieldType Data.CustomFieldType.Date) ] []
                ]



--- Helper


string2Float : String -> Result String Float
string2Float str =
    case String.toFloat str of
        Just n ->
            Ok n

        Nothing ->
            Err ("Not a number: " ++ str)
