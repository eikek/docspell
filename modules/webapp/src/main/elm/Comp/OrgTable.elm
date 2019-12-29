module Comp.OrgTable exposing
    ( Model
    , Msg(..)
    , emptyModel
    , update
    , view
    )

import Api.Model.Organization exposing (Organization)
import Data.Flags exposing (Flags)
import Html exposing (..)
import Html.Attributes exposing (..)
import Html.Events exposing (onClick)
import Util.Address
import Util.Contact


type alias Model =
    { equips : List Organization
    , selected : Maybe Organization
    }


emptyModel : Model
emptyModel =
    { equips = []
    , selected = Nothing
    }


type Msg
    = SetOrgs (List Organization)
    | Select Organization
    | Deselect


update : Flags -> Msg -> Model -> ( Model, Cmd Msg )
update flags msg model =
    case msg of
        SetOrgs list ->
            ( { model | equips = list, selected = Nothing }, Cmd.none )

        Select equip ->
            ( { model | selected = Just equip }, Cmd.none )

        Deselect ->
            ( { model | selected = Nothing }, Cmd.none )


view : Model -> Html Msg
view model =
    table [ class "ui selectable table" ]
        [ thead []
            [ tr []
                [ th [ class "collapsing" ] [ text "Name" ]
                , th [] [ text "Address" ]
                , th [] [ text "Contact" ]
                ]
            ]
        , tbody []
            (List.map (renderOrgLine model) model.equips)
        ]


renderOrgLine : Model -> Organization -> Html Msg
renderOrgLine model org =
    tr
        [ classList [ ( "active", model.selected == Just org ) ]
        , onClick (Select org)
        ]
        [ td [ class "collapsing" ]
            [ text org.name
            ]
        , td []
            [ Util.Address.toString org.address |> text
            ]
        , td []
            [ Util.Contact.toString org.contacts |> text
            ]
        ]
