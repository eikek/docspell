module Comp.SpaceManage exposing
    ( Model
    , Msg
    , empty
    , init
    , update
    , view
    )

import Api
import Api.Model.SpaceDetail exposing (SpaceDetail)
import Api.Model.SpaceItem exposing (SpaceItem)
import Api.Model.SpaceList exposing (SpaceList)
import Api.Model.User exposing (User)
import Api.Model.UserList exposing (UserList)
import Comp.SpaceDetail
import Comp.SpaceTable
import Data.Flags exposing (Flags)
import Html exposing (..)
import Html.Attributes exposing (..)
import Html.Events exposing (onCheck, onClick, onInput)
import Http


type alias Model =
    { tableModel : Comp.SpaceTable.Model
    , detailModel : Maybe Comp.SpaceDetail.Model
    , spaces : List SpaceItem
    , users : List User
    , query : String
    , owningOnly : Bool
    , loading : Bool
    }


type Msg
    = TableMsg Comp.SpaceTable.Msg
    | DetailMsg Comp.SpaceDetail.Msg
    | UserListResp (Result Http.Error UserList)
    | SpaceListResp (Result Http.Error SpaceList)
    | SpaceDetailResp (Result Http.Error SpaceDetail)
    | SetQuery String
    | InitNewSpace
    | ToggleOwningOnly


empty : Model
empty =
    { tableModel = Comp.SpaceTable.init
    , detailModel = Nothing
    , spaces = []
    , users = []
    , query = ""
    , owningOnly = True
    , loading = False
    }


init : Flags -> ( Model, Cmd Msg )
init flags =
    ( empty
    , Cmd.batch
        [ Api.getUsers flags UserListResp
        , Api.getSpaces flags empty.query empty.owningOnly SpaceListResp
        ]
    )



--- Update


update : Flags -> Msg -> Model -> ( Model, Cmd Msg )
update flags msg model =
    case msg of
        TableMsg lm ->
            let
                ( tm, action ) =
                    Comp.SpaceTable.update lm model.tableModel

                cmd =
                    case action of
                        Comp.SpaceTable.EditAction item ->
                            Api.getSpaceDetail flags item.id SpaceDetailResp

                        Comp.SpaceTable.NoAction ->
                            Cmd.none
            in
            ( { model | tableModel = tm }, cmd )

        DetailMsg lm ->
            case model.detailModel of
                Just detail ->
                    let
                        ( dm, dc, back ) =
                            Comp.SpaceDetail.update flags lm detail

                        cmd =
                            if back then
                                Api.getSpaces flags model.query model.owningOnly SpaceListResp

                            else
                                Cmd.none
                    in
                    ( { model
                        | detailModel =
                            if back then
                                Nothing

                            else
                                Just dm
                      }
                    , Cmd.batch
                        [ Cmd.map DetailMsg dc
                        , cmd
                        ]
                    )

                Nothing ->
                    ( model, Cmd.none )

        SetQuery str ->
            ( { model | query = str }
            , Api.getSpaces flags str model.owningOnly SpaceListResp
            )

        ToggleOwningOnly ->
            let
                newOwning =
                    not model.owningOnly
            in
            ( { model | owningOnly = newOwning }
            , Api.getSpaces flags model.query newOwning SpaceListResp
            )

        UserListResp (Ok ul) ->
            ( { model | users = ul.items }, Cmd.none )

        UserListResp (Err err) ->
            ( model, Cmd.none )

        SpaceListResp (Ok sl) ->
            ( { model | spaces = sl.items }, Cmd.none )

        SpaceListResp (Err err) ->
            ( model, Cmd.none )

        SpaceDetailResp (Ok sd) ->
            ( { model | detailModel = Comp.SpaceDetail.init model.users sd |> Just }
            , Cmd.none
            )

        SpaceDetailResp (Err err) ->
            ( model, Cmd.none )

        InitNewSpace ->
            let
                sd =
                    Comp.SpaceDetail.initEmpty model.users
            in
            ( { model | detailModel = Just sd }
            , Cmd.none
            )



--- View


view : Flags -> Model -> Html Msg
view flags model =
    case model.detailModel of
        Just dm ->
            viewDetail flags dm

        Nothing ->
            viewTable model


viewDetail : Flags -> Comp.SpaceDetail.Model -> Html Msg
viewDetail flags detailModel =
    div []
        [ Html.map DetailMsg (Comp.SpaceDetail.view flags detailModel)
        ]


viewTable : Model -> Html Msg
viewTable model =
    div []
        [ div [ class "ui secondary menu" ]
            [ div [ class "horizontally fitted item" ]
                [ div [ class "ui icon input" ]
                    [ input
                        [ type_ "text"
                        , onInput SetQuery
                        , value model.query
                        , placeholder "Search…"
                        ]
                        []
                    , i [ class "ui search icon" ]
                        []
                    ]
                ]
            , div [ class "item" ]
                [ div [ class "ui checkbox" ]
                    [ input
                        [ type_ "checkbox"
                        , onCheck (\_ -> ToggleOwningOnly)
                        , checked model.owningOnly
                        ]
                        []
                    , label [] [ text "Show owning spaces only" ]
                    ]
                ]
            , div [ class "right menu" ]
                [ div [ class "item" ]
                    [ a
                        [ class "ui primary button"
                        , href "#"
                        , onClick InitNewSpace
                        ]
                        [ i [ class "plus icon" ] []
                        , text "New Space"
                        ]
                    ]
                ]
            ]
        , Html.map TableMsg (Comp.SpaceTable.view model.tableModel model.spaces)
        , div
            [ classList
                [ ( "ui dimmer", True )
                , ( "active", model.loading )
                ]
            ]
            [ div [ class "ui loader" ] []
            ]
        ]
