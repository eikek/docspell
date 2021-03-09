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
import Data.Flags exposing (Flags)
import Html exposing (..)
import Html.Attributes exposing (..)
import Html.Events exposing (onInput)
import Styles as S
import Util.Maybe


type alias Model =
    { equipment : Equipment
    , name : String
    , notes : Maybe String
    }


emptyModel : Model
emptyModel =
    { equipment = Api.Model.Equipment.empty
    , name = ""
    , notes = Nothing
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
    }


type Msg
    = SetName String
    | SetEquipment Equipment
    | SetNotes String


update : Flags -> Msg -> Model -> ( Model, Cmd Msg )
update _ msg model =
    case msg of
        SetEquipment t ->
            ( { model
                | equipment = t
                , name = t.name
                , notes = t.notes
              }
            , Cmd.none
            )

        SetName n ->
            ( { model | name = n }, Cmd.none )

        SetNotes str ->
            ( { model | notes = Util.Maybe.fromString str }, Cmd.none )



--- View2


view2 : Model -> Html Msg
view2 model =
    div [ class "flex flex-col" ]
        [ div [ class "mb-4" ]
            [ label
                [ for "equipname"
                , class S.inputLabel
                ]
                [ text "Name"
                , B.inputRequired
                ]
            , input
                [ type_ "text"
                , onInput SetName
                , placeholder "Name"
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
            [ h3 [ class S.header3 ]
                [ text "Notes"
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
