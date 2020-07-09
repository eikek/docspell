module Comp.SpaceTable exposing
    ( Action(..)
    , Model
    , Msg
    , init
    , update
    , view
    )

import Api.Model.SpaceItem exposing (SpaceItem)
import Html exposing (..)
import Html.Attributes exposing (..)
import Html.Events exposing (onClick)
import Util.Html
import Util.Time


type alias Model =
    {}


type Msg
    = EditItem SpaceItem


type Action
    = NoAction
    | EditAction SpaceItem


init : Model
init =
    {}


update : Msg -> Model -> ( Model, Action )
update msg model =
    case msg of
        EditItem item ->
            ( model, EditAction item )


view : Model -> List SpaceItem -> Html Msg
view _ items =
    div []
        [ table [ class "ui very basic center aligned table" ]
            [ thead []
                [ th [ class "collapsing" ] []
                , th [] [ text "Name" ]
                , th [] [ text "Owner" ]
                , th [] [ text "Owner or Member" ]
                , th [] [ text "#Member" ]
                , th [] [ text "Created" ]
                ]
            , tbody []
                (List.map viewItem items)
            ]
        ]


viewItem : SpaceItem -> Html Msg
viewItem item =
    tr []
        [ td [ class "collapsing" ]
            [ a
                [ href "#"
                , class "ui basic small blue label"
                , onClick (EditItem item)
                ]
                [ i [ class "edit icon" ] []
                , text "Edit"
                ]
            ]
        , td []
            [ text item.name
            ]
        , td []
            [ text item.owner.name
            ]
        , td []
            [ Util.Html.checkbox item.isMember
            ]
        , td []
            [ String.fromInt item.memberCount
                |> text
            ]
        , td []
            [ Util.Time.formatDateShort item.created
                |> text
            ]
        ]
