module Comp.EquipmentTable exposing
    ( Model
    , Msg(..)
    , emptyModel
    , update
    , view2
    )

import Api.Model.Equipment exposing (Equipment)
import Comp.Basic as B
import Data.Flags exposing (Flags)
import Html exposing (..)
import Html.Attributes exposing (..)
import Html.Events exposing (onClick)
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


view2 : Model -> Html Msg
view2 model =
    table [ class S.tableMain ]
        [ thead []
            [ tr []
                [ th [ class "" ] []
                , th [ class "text-left" ] [ text "Name" ]
                ]
            ]
        , tbody []
            (List.map (renderEquipmentLine2 model) model.equips)
        ]


renderEquipmentLine2 : Model -> Equipment -> Html Msg
renderEquipmentLine2 model equip =
    tr
        [ classList [ ( "active", model.selected == Just equip ) ]
        , class S.tableRow
        ]
        [ B.editLinkTableCell (Select equip)
        , td [ class "text-left" ]
            [ text equip.name
            ]
        ]
