module Comp.CustomFieldInput exposing
    ( FieldResult(..)
    , Model
    , Msg
    , UpdateResult
    , init
    , initWith
    , update
    , view
    )

import Api.Model.CustomField exposing (CustomField)
import Api.Model.ItemFieldValue exposing (ItemFieldValue)
import Comp.DatePicker
import Data.CustomFieldType exposing (CustomFieldType)
import Data.Money
import Date exposing (Date)
import DatePicker exposing (DatePicker)
import Html exposing (..)
import Html.Attributes exposing (..)
import Html.Events exposing (onCheck, onClick, onInput)


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
        floatModel =
            case model.fieldModel of
                NumberField fm ->
                    Just fm

                MoneyField fm ->
                    Just fm

                _ ->
                    Nothing

        getMsg res =
            case res of
                Ok _ ->
                    Nothing

                Err m ->
                    Just m
    in
    Maybe.andThen getMsg (Maybe.map .result floatModel)


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
                            updateFloatModel value.value string2Float
                    in
                    NumberField fm

                Data.CustomFieldType.Money ->
                    let
                        ( fm, _ ) =
                            updateFloatModel value.value Data.Money.fromString
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


type FieldResult
    = NoResult
    | RemoveField
    | Value String


type alias UpdateResult =
    { model : Model
    , cmd : Cmd Msg
    , result : FieldResult
    , subs : Sub Msg
    }


updateFloatModel : String -> (String -> Result String Float) -> ( FloatModel, FieldResult )
updateFloatModel msg parse =
    case parse msg of
        Ok n ->
            ( { input = msg
              , result = Ok n
              }
            , Value msg
            )

        Err err ->
            ( { input = msg
              , result = Err err
              }
            , NoResult
            )


string2Float : String -> Result String Float
string2Float str =
    case String.toFloat str of
        Just n ->
            Ok n

        Nothing ->
            Err ("Not a number: " ++ str)


update : Msg -> Model -> UpdateResult
update msg model =
    case ( msg, model.fieldModel ) of
        ( SetText str, TextField _ ) ->
            let
                model_ =
                    { model | fieldModel = TextField (Just str) }
            in
            UpdateResult model_ Cmd.none (Value str) Sub.none

        ( NumberMsg str, NumberField _ ) ->
            let
                ( fm, res ) =
                    updateFloatModel str string2Float

                model_ =
                    { model | fieldModel = NumberField fm }
            in
            UpdateResult model_ Cmd.none res Sub.none

        ( MoneyMsg str, MoneyField _ ) ->
            let
                ( fm, res ) =
                    updateFloatModel
                        str
                        Data.Money.fromString

                model_ =
                    { model | fieldModel = MoneyField fm }
            in
            UpdateResult model_ Cmd.none res Sub.none

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
            UpdateResult model_ Cmd.none (Value value) Sub.none

        ( DateMsg lm, DateField _ picker ) ->
            let
                ( picker_, event ) =
                    Comp.DatePicker.updateDefault lm picker

                ( newDate, value ) =
                    case event of
                        DatePicker.Picked date ->
                            ( Just date, Value (Date.toIsoString date) )

                        DatePicker.None ->
                            ( Nothing, NoResult )

                        DatePicker.FailedInput _ ->
                            ( Nothing, NoResult )

                model_ =
                    { model | fieldModel = DateField newDate picker_ }
            in
            UpdateResult model_ Cmd.none value Sub.none

        ( Remove, _ ) ->
            UpdateResult model Cmd.none RemoveField Sub.none

        -- no other possibilities, not well encoded here
        _ ->
            UpdateResult model Cmd.none NoResult Sub.none


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
                , i [ class (iconOr "pen icon") ] []
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
                , i [ class (iconOr "hashtag icon") ] []
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
                , i [ class (iconOr "money bill icon") ] []
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
                [ Html.map DateMsg (Comp.DatePicker.view v Comp.DatePicker.defaultSettings dp)
                , removeButton ""
                , i [ class (iconOr "calendar icon") ] []
                ]
