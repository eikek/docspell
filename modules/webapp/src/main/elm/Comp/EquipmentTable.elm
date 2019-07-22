module Comp.EquipmentTable exposing ( Model
                              , emptyModel
                              , Msg(..)
                              , view
                              , update)

import Html exposing (..)
import Html.Attributes exposing (..)
import Html.Events exposing (onClick)
import Data.Flags exposing (Flags)
import Api.Model.Equipment exposing (Equipment)

type alias Model =
    { equips: List Equipment
    , selected: Maybe Equipment
    }

emptyModel: Model
emptyModel =
    { equips = []
    , selected = Nothing
    }

type Msg
    = SetEquipments (List Equipment)
    | Select Equipment
    | Deselect

update: Flags -> Msg -> Model -> (Model, Cmd Msg)
update flags msg model =
    case msg of
        SetEquipments list ->
            ({model | equips = list, selected = Nothing }, Cmd.none)

        Select equip ->
            ({model | selected = Just equip}, Cmd.none)

        Deselect ->
            ({model | selected = Nothing}, Cmd.none)


view: Model -> Html Msg
view model =
    table [class "ui selectable table"]
        [thead []
             [tr []
                  [th [][text "Name"]
                  ]
             ]
        ,tbody []
            (List.map (renderEquipmentLine model) model.equips)
        ]

renderEquipmentLine: Model -> Equipment -> Html Msg
renderEquipmentLine model equip =
    tr [classList [("active", model.selected == Just equip)]
       ,onClick (Select equip)
       ]
        [td []
             [text equip.name
             ]
        ]
