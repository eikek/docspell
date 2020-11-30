module Comp.PersonTable exposing
    ( Model
    , Msg(..)
    , emptyModel
    , update
    , view
    )

import Api.Model.Person exposing (Person)
import Data.Flags exposing (Flags)
import Html exposing (..)
import Html.Attributes exposing (..)
import Html.Events exposing (onClick)
import Util.Address
import Util.Contact


type alias Model =
    { equips : List Person
    , selected : Maybe Person
    }


emptyModel : Model
emptyModel =
    { equips = []
    , selected = Nothing
    }


type Msg
    = SetPersons (List Person)
    | Select Person
    | Deselect


update : Flags -> Msg -> Model -> ( Model, Cmd Msg )
update _ msg model =
    case msg of
        SetPersons list ->
            ( { model | equips = list, selected = Nothing }, Cmd.none )

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
                , th [ class "collapsing center aligned" ] [ text "Concerning" ]
                , th [] [ text "Name" ]
                , th [] [ text "Organization" ]
                , th [] [ text "Address" ]
                , th [] [ text "Contact" ]
                ]
            ]
        , tbody []
            (List.map (renderPersonLine model) model.equips)
        ]


renderPersonLine : Model -> Person -> Html Msg
renderPersonLine model person =
    tr
        [ classList [ ( "active", model.selected == Just person ) ]
        ]
        [ td [ class "collapsing" ]
            [ a
                [ href "#"
                , class "ui basic small blue label"
                , onClick (Select person)
                ]
                [ i [ class "edit icon" ] []
                , text "Edit"
                ]
            ]
        , td [ class "center aligned" ]
            [ if person.concerning then
                i [ class "check square outline icon" ] []

              else
                i [ class "minus square outline icon" ] []
            ]
        , td []
            [ text person.name
            ]
        , td []
            [ Maybe.map .name person.organization
                |> Maybe.withDefault "-"
                |> text
            ]
        , td []
            [ Util.Address.toString person.address |> text
            ]
        , td []
            [ Util.Contact.toString person.contacts |> text
            ]
        ]
