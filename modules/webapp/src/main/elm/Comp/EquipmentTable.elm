{-
  Copyright 2020 Docspell Contributors

  SPDX-License-Identifier: GPL-3.0-or-later
-}

module Comp.EquipmentTable exposing
    ( Model
    , Msg(..)
    , emptyModel
    , update
    , view2
    )

import Api.Model.Equipment exposing (Equipment)
import Comp.Basic as B
import Data.EquipmentUse
import Data.Flags exposing (Flags)
import Html exposing (..)
import Html.Attributes exposing (..)
import Messages.Comp.EquipmentTable exposing (Texts)
import Styles as S


type alias Model =
    { equips : List Equipment
    , selected : Maybe Equipment
    }


emptyModel : Model
emptyModel =
    { equips = []
    , selected = Nothing
    }


type Msg
    = SetEquipments (List Equipment)
    | Select Equipment
    | Deselect


update : Flags -> Msg -> Model -> ( Model, Cmd Msg )
update _ msg model =
    case msg of
        SetEquipments list ->
            ( { model | equips = list, selected = Nothing }, Cmd.none )

        Select equip ->
            ( { model | selected = Just equip }, Cmd.none )

        Deselect ->
            ( { model | selected = Nothing }, Cmd.none )



--- View2


view2 : Texts -> Model -> Html Msg
view2 texts model =
    table [ class S.tableMain ]
        [ thead []
            [ tr []
                [ th [ class "" ] []
                , th [ class "text-left pr-1 md:px-2 w-20" ]
                    [ text texts.use
                    ]
                , th [ class "text-left" ] [ text texts.basics.name ]
                ]
            ]
        , tbody []
            (List.map (renderEquipmentLine2 texts model) model.equips)
        ]


renderEquipmentLine2 : Texts -> Model -> Equipment -> Html Msg
renderEquipmentLine2 texts model equip =
    tr
        [ classList [ ( "active", model.selected == Just equip ) ]
        , class S.tableRow
        ]
        [ B.editLinkTableCell texts.basics.edit (Select equip)
        , td [ class "text-left pr-1 md:px-2" ]
            [ div [ class "label inline-flex text-sm" ]
                [ Data.EquipmentUse.fromString equip.use
                    |> Maybe.withDefault Data.EquipmentUse.Concerning
                    |> texts.equipmentUseLabel
                    |> text
                ]
            ]
        , td [ class "text-left" ]
            [ text equip.name
            ]
        ]
