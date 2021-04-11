module Comp.EquipmentForm exposing
    ( Model
    , Msg(..)
    , emptyModel
    , getEquipment
    , isValid
    , update
    , view2
    )

import Api.Model.Equipment exposing (Equipment)
import Comp.Basic as B
import Comp.FixedDropdown
import Data.DropdownStyle as DS
import Data.EquipmentUse exposing (EquipmentUse)
import Data.Flags exposing (Flags)
import Html exposing (..)
import Html.Attributes exposing (..)
import Html.Events exposing (onInput)
import Messages.Comp.EquipmentForm exposing (Texts)
import Styles as S
import Util.Maybe


type alias Model =
    { equipment : Equipment
    , name : String
    , notes : Maybe String
    , use : EquipmentUse
    , useModel : Comp.FixedDropdown.Model EquipmentUse
    }


emptyModel : Model
emptyModel =
    { equipment = Api.Model.Equipment.empty
    , name = ""
    , notes = Nothing
    , use = Data.EquipmentUse.Concerning
    , useModel =
        Comp.FixedDropdown.init Data.EquipmentUse.all
    }


isValid : Model -> Bool
isValid model =
    model.name /= ""


getEquipment : Model -> Equipment
getEquipment model =
    { id = model.equipment.id
    , name = model.name
    , created = model.equipment.created
    , notes = model.notes
    , use = Data.EquipmentUse.asString model.use
    }


type Msg
    = SetName String
    | SetEquipment Equipment
    | SetNotes String
    | UseDropdownMsg (Comp.FixedDropdown.Msg EquipmentUse)


update : Flags -> Msg -> Model -> ( Model, Cmd Msg )
update _ msg model =
    case msg of
        SetEquipment t ->
            ( { model
                | equipment = t
                , name = t.name
                , notes = t.notes
                , use =
                    Data.EquipmentUse.fromString t.use
                        |> Maybe.withDefault Data.EquipmentUse.Concerning
              }
            , Cmd.none
            )

        SetName n ->
            ( { model | name = n }, Cmd.none )

        SetNotes str ->
            ( { model | notes = Util.Maybe.fromString str }, Cmd.none )

        UseDropdownMsg lm ->
            let
                ( nm, mu ) =
                    Comp.FixedDropdown.update lm model.useModel

                newUse =
                    Maybe.withDefault model.use mu
            in
            ( { model | useModel = nm, use = newUse }, Cmd.none )



--- View2


view2 : Texts -> Model -> Html Msg
view2 texts model =
    let
        equipUseCfg =
            { display = texts.equipmentUseLabel
            , icon = \_ -> Nothing
            , style = DS.mainStyle
            , selectPlaceholder = texts.basics.selectPlaceholder
            }
    in
    div [ class "flex flex-col" ]
        [ div [ class "mb-4" ]
            [ label
                [ for "equipname"
                , class S.inputLabel
                ]
                [ text texts.basics.name
                , B.inputRequired
                ]
            , input
                [ type_ "text"
                , onInput SetName
                , placeholder texts.basics.name
                , value model.name
                , name "equipname"
                , class S.textInput
                , classList
                    [ ( "border-red-600 dark:border-orange-600"
                      , not (isValid model)
                      )
                    ]
                ]
                []
            ]
        , div [ class "mb-4" ]
            [ label
                [ class S.inputLabel
                ]
                [ text texts.use ]
            , Html.map UseDropdownMsg
                (Comp.FixedDropdown.viewStyled2 equipUseCfg False (Just model.use) model.useModel)
            , span [ class "opacity-50 text-sm" ]
                [ case model.use of
                    Data.EquipmentUse.Concerning ->
                        text texts.useAsConcerning

                    Data.EquipmentUse.Disabled ->
                        text texts.useNotSuggestions
                ]
            ]
        , div [ class "mb-4" ]
            [ h3 [ class S.header3 ]
                [ text texts.notes
                ]
            , div [ class "" ]
                [ textarea
                    [ onInput SetNotes
                    , Maybe.withDefault "" model.notes |> value
                    , class S.textAreaInput
                    ]
                    []
                ]
            ]
        ]
