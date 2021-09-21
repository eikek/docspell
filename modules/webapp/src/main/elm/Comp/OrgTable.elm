{-
   Copyright 2020 Eike K. & Contributors

   SPDX-License-Identifier: AGPL-3.0-or-later
-}


module Comp.OrgTable exposing
    ( Model
    , Msg(..)
    , emptyModel
    , update
    , view2
    )

import Api.Model.Organization exposing (Organization)
import Comp.Basic as B
import Data.Flags exposing (Flags)
import Data.OrgUse
import Data.OrganizationOrder exposing (OrganizationOrder)
import Html exposing (..)
import Html.Attributes exposing (..)
import Html.Events exposing (onClick)
import Messages.Comp.OrgTable exposing (Texts)
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
    | ToggleOrder OrganizationOrder


update : Flags -> Msg -> Model -> ( Model, Cmd Msg, Maybe OrganizationOrder )
update _ msg model =
    case msg of
        SetOrgs list ->
            ( { model | orgs = list, selected = Nothing }, Cmd.none, Nothing )

        Select equip ->
            ( { model | selected = Just equip }, Cmd.none, Nothing )

        Deselect ->
            ( { model | selected = Nothing }, Cmd.none, Nothing )

        ToggleOrder order ->
            ( model, Cmd.none, Just order )


newOrder : OrganizationOrder -> OrganizationOrder
newOrder current =
    case current of
        Data.OrganizationOrder.NameAsc ->
            Data.OrganizationOrder.NameDesc

        Data.OrganizationOrder.NameDesc ->
            Data.OrganizationOrder.NameAsc



--- View2


view2 : Texts -> OrganizationOrder -> Model -> Html Msg
view2 texts order model =
    let
        nameSortIcon =
            case order of
                Data.OrganizationOrder.NameAsc ->
                    "fa fa-sort-alpha-up"

                Data.OrganizationOrder.NameDesc ->
                    "fa fa-sort-alpha-down-alt"
    in
    table [ class S.tableMain ]
        [ thead []
            [ tr []
                [ th [ class "" ] []
                , th [ class "text-left pr-1 md:px-2" ]
                    [ text texts.use
                    ]
                , th [ class "text-left" ]
                    [ a [ href "#", onClick (ToggleOrder <| newOrder order) ]
                        [ i [ class nameSortIcon, class "mr-1" ] []
                        , text texts.basics.name
                        ]
                    ]
                , th [ class "text-left hidden md:table-cell" ]
                    [ text texts.address
                    ]
                , th [ class "text-left hidden sm:table-cell" ]
                    [ text texts.contact
                    ]
                ]
            ]
        , tbody []
            (List.map (renderOrgLine2 texts model) model.orgs)
        ]


renderOrgLine2 : Texts -> Model -> Organization -> Html Msg
renderOrgLine2 texts model org =
    tr
        [ classList [ ( "active", model.selected == Just org ) ]
        , class S.tableRow
        ]
        [ B.editLinkTableCell texts.basics.edit (Select org)
        , td [ class "text-left pr-1 md:px-2" ]
            [ div [ class "label inline-flex text-sm" ]
                [ Data.OrgUse.fromString org.use
                    |> Maybe.withDefault Data.OrgUse.Correspondent
                    |> texts.orgUseLabel
                    |> text
                ]
            ]
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
