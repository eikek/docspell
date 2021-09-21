{-
   Copyright 2020 Eike K. & Contributors

   SPDX-License-Identifier: AGPL-3.0-or-later
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
import Data.EquipmentOrder exposing (EquipmentOrder)
import Data.EquipmentUse
import Data.Flags exposing (Flags)
import Html exposing (..)
import Html.Attributes exposing (..)
import Html.Events exposing (onClick)
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
    | ToggleOrder EquipmentOrder


update : Flags -> Msg -> Model -> ( Model, Cmd Msg, Maybe EquipmentOrder )
update _ msg model =
    case msg of
        SetEquipments list ->
            ( { model | equips = list, selected = Nothing }, Cmd.none, Nothing )

        Select equip ->
            ( { model | selected = Just equip }, Cmd.none, Nothing )

        Deselect ->
            ( { model | selected = Nothing }, Cmd.none, Nothing )

        ToggleOrder order ->
            ( model, Cmd.none, Just order )


newOrder : EquipmentOrder -> EquipmentOrder
newOrder current =
    case current of
        Data.EquipmentOrder.NameAsc ->
            Data.EquipmentOrder.NameDesc

        Data.EquipmentOrder.NameDesc ->
            Data.EquipmentOrder.NameAsc



--- View2


view2 : Texts -> EquipmentOrder -> Model -> Html Msg
view2 texts order model =
    let
        nameSortIcon =
            case order of
                Data.EquipmentOrder.NameAsc ->
                    "fa fa-sort-alpha-up"

                Data.EquipmentOrder.NameDesc ->
                    "fa fa-sort-alpha-down-alt"
    in
    table [ class S.tableMain ]
        [ thead []
            [ tr []
                [ th [ class "" ] []
                , th [ class "text-left pr-1 md:px-2 w-20" ]
                    [ text texts.use
                    ]
                , th [ class "text-left" ]
                    [ a [ href "#", onClick (ToggleOrder <| newOrder order) ]
                        [ i [ class nameSortIcon, class "mr-1" ] []
                        , text texts.basics.name
                        ]
                    ]
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
