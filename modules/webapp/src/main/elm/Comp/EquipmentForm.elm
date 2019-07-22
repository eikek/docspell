module Comp.EquipmentForm exposing ( Model
                             , emptyModel
                             , Msg(..)
                             , view
                             , update
                             , isValid
                             , getEquipment)

import Html exposing (..)
import Html.Attributes exposing (..)
import Html.Events exposing (onInput)
import Data.Flags exposing (Flags)
import Api.Model.Equipment exposing (Equipment)

type alias Model =
    { equipment: Equipment
    , name: String
    }

emptyModel: Model
emptyModel =
    { equipment = Api.Model.Equipment.empty
    , name = ""
    }

isValid: Model -> Bool
isValid model =
    model.name /= ""

getEquipment: Model -> Equipment
getEquipment model =
    Equipment model.equipment.id model.name model.equipment.created

type Msg
    = SetName String
    | SetEquipment Equipment

update: Flags -> Msg -> Model -> (Model, Cmd Msg)
update flags msg model =
    case msg of
        SetEquipment t ->
            ({model | equipment = t, name = t.name }, Cmd.none)

        SetName n ->
            ({model | name = n}, Cmd.none)


view: Model -> Html Msg
view model =
    div [class "ui form"]
        [div [classList [("field", True)
                        ,("error", not (isValid model))
                        ]
             ]
             [label [][text "Name*"]
             ,input [type_ "text"
                    ,onInput SetName
                    ,placeholder "Name"
                    ,value model.name
                    ][]
             ]
        ]
