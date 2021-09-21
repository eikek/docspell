{-
   Copyright 2020 Eike K. & Contributors

   SPDX-License-Identifier: AGPL-3.0-or-later
-}


module Comp.PersonTable exposing
    ( Model
    , Msg(..)
    , emptyModel
    , update
    , view2
    )

import Api.Model.Person exposing (Person)
import Comp.Basic as B
import Data.Flags exposing (Flags)
import Data.PersonOrder exposing (PersonOrder)
import Data.PersonUse
import Html exposing (..)
import Html.Attributes exposing (..)
import Html.Events exposing (onClick)
import Messages.Comp.PersonTable exposing (Texts)
import Styles as S
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
    | ToggleOrder PersonOrder


update : Flags -> Msg -> Model -> ( Model, Cmd Msg, Maybe PersonOrder )
update _ msg model =
    case msg of
        SetPersons list ->
            ( { model | equips = list, selected = Nothing }, Cmd.none, Nothing )

        Select equip ->
            ( { model | selected = Just equip }, Cmd.none, Nothing )

        Deselect ->
            ( { model | selected = Nothing }, Cmd.none, Nothing )

        ToggleOrder order ->
            ( model, Cmd.none, Just order )


type Header
    = Name
    | Org


newOrder : Header -> PersonOrder -> PersonOrder
newOrder header current =
    case ( header, current ) of
        ( Name, Data.PersonOrder.NameAsc ) ->
            Data.PersonOrder.NameDesc

        ( Name, _ ) ->
            Data.PersonOrder.NameAsc

        ( Org, Data.PersonOrder.OrgAsc ) ->
            Data.PersonOrder.OrgDesc

        ( Org, _ ) ->
            Data.PersonOrder.OrgAsc



--- View2


view2 : Texts -> PersonOrder -> Model -> Html Msg
view2 texts order model =
    let
        nameSortIcon =
            case order of
                Data.PersonOrder.NameAsc ->
                    "fa fa-sort-alpha-up"

                Data.PersonOrder.NameDesc ->
                    "fa fa-sort-alpha-down-alt"

                _ ->
                    "invisible fa fa-sort-alpha-down-alt"

        orgSortIcon =
            case order of
                Data.PersonOrder.OrgAsc ->
                    "fa fa-sort-alpha-up"

                Data.PersonOrder.OrgDesc ->
                    "fa fa-sort-alpha-down-alt"

                _ ->
                    "invisible fa fa-sort-alpha-down-alt"
    in
    table [ class S.tableMain ]
        [ thead []
            [ tr []
                [ th [ class "w-px whitespace-nowrap" ] []
                , th [ class "text-left pr-1 md:px-2" ]
                    [ text texts.use
                    ]
                , th [ class "text-left" ]
                    [ a [ href "#", onClick (ToggleOrder <| newOrder Name order) ]
                        [ i [ class nameSortIcon, class "mr-1" ] []
                        , text texts.basics.name
                        ]
                    ]
                , th [ class "text-left hidden sm:table-cell" ]
                    [ a [ href "#", onClick (ToggleOrder <| newOrder Org order) ]
                        [ i [ class orgSortIcon, class "mr-1" ] []
                        , text texts.basics.organization
                        ]
                    ]
                , th [ class "text-left hidden md:table-cell" ] [ text texts.contact ]
                ]
            ]
        , tbody []
            (List.map (renderPersonLine2 texts model) model.equips)
        ]


renderPersonLine2 : Texts -> Model -> Person -> Html Msg
renderPersonLine2 texts model person =
    tr
        [ classList [ ( "active", model.selected == Just person ) ]
        , class S.tableRow
        ]
        [ B.editLinkTableCell texts.basics.edit (Select person)
        , td [ class "text-left pr-1 md:px-2" ]
            [ div [ class "label inline-flex text-sm" ]
                [ Data.PersonUse.fromString person.use
                    |> Maybe.withDefault Data.PersonUse.Both
                    |> texts.personUseLabel
                    |> text
                ]
            ]
        , td []
            [ text person.name
            ]
        , td [ class "hidden sm:table-cell" ]
            [ Maybe.map .name person.organization
                |> Maybe.withDefault "-"
                |> text
            ]
        , td [ class "hidden md:table-cell" ]
            [ Util.Contact.toString person.contacts |> text
            ]
        ]
