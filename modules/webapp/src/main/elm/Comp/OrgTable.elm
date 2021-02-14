module Comp.OrgTable exposing
    ( Model
    , Msg(..)
    , emptyModel
    , update
    , view
    , view2
    )

import Api.Model.Organization exposing (Organization)
import Comp.Basic as B
import Data.Flags exposing (Flags)
import Html exposing (..)
import Html.Attributes exposing (..)
import Html.Events exposing (onClick)
import Styles as S
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



--- View2


view2 : Model -> Html Msg
view2 model =
    table [ class S.tableMain ]
        [ thead []
            [ tr []
                [ th [ class "" ] []
                , th [ class "text-left" ] [ text "Name" ]
                , th [ class "text-left hidden md:table-cell" ] [ text "Address" ]
                , th [ class "text-left hidden sm:table-cell" ] [ text "Contact" ]
                ]
            ]
        , tbody []
            (List.map (renderOrgLine2 model) model.orgs)
        ]


renderOrgLine2 : Model -> Organization -> Html Msg
renderOrgLine2 model org =
    tr
        [ classList [ ( "active", model.selected == Just org ) ]
        , class S.tableRow
        ]
        [ B.editLinkTableCell (Select org)
        , td [ class "py-4 sm:py-2 pr-2 md:pr-4" ]
            [ text org.name
            ]
        , td [ class "py-4 sm:py-2 pr-4 hidden md:table-cell" ]
            [ Util.Address.toString org.address |> text
            ]
        , td [ class "py-4 sm:py-2 sm:py-2 pr-2 md:pr-4 hidden sm:table-cell" ]
            [ Util.Contact.toString org.contacts |> text
            ]
        ]
