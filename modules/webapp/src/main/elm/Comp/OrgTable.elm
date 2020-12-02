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
    { orgs : List Organization
    , selected : Maybe Organization
    }


emptyModel : Model
emptyModel =
    { orgs = []
    , selected = Nothing
    }


type Msg
    = SetOrgs (List Organization)
    | Select Organization
    | Deselect


update : Flags -> Msg -> Model -> ( Model, Cmd Msg )
update _ msg model =
    case msg of
        SetOrgs list ->
            ( { model | orgs = list, selected = Nothing }, Cmd.none )

        Select equip ->
            ( { model | selected = Just equip }, Cmd.none )

        Deselect ->
            ( { model | selected = Nothing }, Cmd.none )


view : Model -> Html Msg
view model =
    table [ class "ui very basic aligned table" ]
        [ thead []
            [ tr []
                [ th [ class "collapsing" ] []
                , th [ class "collapsing" ] [ text "Name" ]
                , th [] [ text "Address" ]
                , th [] [ text "Contact" ]
                ]
            ]
        , tbody []
            (List.map (renderOrgLine model) model.orgs)
        ]


renderOrgLine : Model -> Organization -> Html Msg
renderOrgLine model org =
    tr
        [ classList [ ( "active", model.selected == Just org ) ]
        ]
        [ td [ class "collapsing" ]
            [ a
                [ href "#"
                , class "ui basic small blue label"
                , onClick (Select org)
                ]
                [ i [ class "edit icon" ] []
                , text "Edit"
                ]
            ]
        , td [ class "collapsing" ]
            [ text org.name
            ]
        , td []
            [ Util.Address.toString org.address |> text
            ]
        , td []
            [ Util.Contact.toString org.contacts |> text
            ]
        ]
