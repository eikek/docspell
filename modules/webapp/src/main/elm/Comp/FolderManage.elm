module Comp.FolderManage exposing
    ( Model
    , Msg
    , empty
    , init
    , update
    , view
    , view2
    )

import Api
import Api.Model.FolderDetail exposing (FolderDetail)
import Api.Model.FolderItem exposing (FolderItem)
import Api.Model.FolderList exposing (FolderList)
import Api.Model.User exposing (User)
import Api.Model.UserList exposing (UserList)
import Comp.FolderDetail
import Comp.FolderTable
import Comp.MenuBar as MB
import Data.Flags exposing (Flags)
import Html exposing (..)
import Html.Attributes exposing (..)
import Html.Events exposing (onCheck, onClick, onInput)
import Http
import Styles as S


type alias Model =
    { tableModel : Comp.FolderTable.Model
    , detailModel : Maybe Comp.FolderDetail.Model
    , folders : List FolderItem
    , users : List User
    , query : String
    , owningOnly : Bool
    , loading : Bool
    }


type Msg
    = TableMsg Comp.FolderTable.Msg
    | DetailMsg Comp.FolderDetail.Msg
    | UserListResp (Result Http.Error UserList)
    | FolderListResp (Result Http.Error FolderList)
    | FolderDetailResp (Result Http.Error FolderDetail)
    | SetQuery String
    | InitNewFolder
    | ToggleOwningOnly


empty : Model
empty =
    { tableModel = Comp.FolderTable.init
    , detailModel = Nothing
    , folders = []
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
        , Api.getFolders flags empty.query empty.owningOnly FolderListResp
        ]
    )



--- Update


update : Flags -> Msg -> Model -> ( Model, Cmd Msg )
update flags msg model =
    case msg of
        TableMsg lm ->
            let
                ( tm, action ) =
                    Comp.FolderTable.update lm model.tableModel

                cmd =
                    case action of
                        Comp.FolderTable.EditAction item ->
                            Api.getFolderDetail flags item.id FolderDetailResp

                        Comp.FolderTable.NoAction ->
                            Cmd.none
            in
            ( { model | tableModel = tm }, cmd )

        DetailMsg lm ->
            case model.detailModel of
                Just detail ->
                    let
                        ( dm, dc, back ) =
                            Comp.FolderDetail.update flags lm detail

                        cmd =
                            if back then
                                Api.getFolders flags model.query model.owningOnly FolderListResp

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
            , Api.getFolders flags str model.owningOnly FolderListResp
            )

        ToggleOwningOnly ->
            let
                newOwning =
                    not model.owningOnly
            in
            ( { model | owningOnly = newOwning }
            , Api.getFolders flags model.query newOwning FolderListResp
            )

        UserListResp (Ok ul) ->
            ( { model | users = ul.items }, Cmd.none )

        UserListResp (Err err) ->
            ( model, Cmd.none )

        FolderListResp (Ok sl) ->
            ( { model | folders = sl.items }, Cmd.none )

        FolderListResp (Err err) ->
            ( model, Cmd.none )

        FolderDetailResp (Ok sd) ->
            ( { model | detailModel = Comp.FolderDetail.init model.users sd |> Just }
            , Cmd.none
            )

        FolderDetailResp (Err err) ->
            ( model, Cmd.none )

        InitNewFolder ->
            let
                sd =
                    Comp.FolderDetail.initEmpty model.users
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


viewDetail : Flags -> Comp.FolderDetail.Model -> Html Msg
viewDetail flags detailModel =
    div []
        [ Html.map DetailMsg (Comp.FolderDetail.view flags detailModel)
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
                    , label [] [ text "Show owning folders only" ]
                    ]
                ]
            , div [ class "right menu" ]
                [ div [ class "item" ]
                    [ a
                        [ class "ui primary button"
                        , href "#"
                        , onClick InitNewFolder
                        ]
                        [ i [ class "plus icon" ] []
                        , text "New Folder"
                        ]
                    ]
                ]
            ]
        , Html.map TableMsg (Comp.FolderTable.view model.tableModel model.folders)
        , div
            [ classList
                [ ( "ui dimmer", True )
                , ( "active", model.loading )
                ]
            ]
            [ div [ class "ui loader" ] []
            ]
        ]



--- View2


view2 : Flags -> Model -> Html Msg
view2 flags model =
    case model.detailModel of
        Just dm ->
            viewDetail2 flags dm

        Nothing ->
            viewTable2 model


viewDetail2 : Flags -> Comp.FolderDetail.Model -> Html Msg
viewDetail2 flags model =
    div []
        [ if model.folder.id == "" then
            h3 [ class S.header2 ]
                [ text "Create new Folder"
                ]

          else
            h3 [ class S.header2 ]
                [ text model.folder.name
                , div [ class "opacity-50 text-sm" ]
                    [ text "Id: "
                    , text model.folder.id
                    ]
                ]
        , Html.map DetailMsg (Comp.FolderDetail.view2 flags model)
        ]


viewTable2 : Model -> Html Msg
viewTable2 model =
    div [ class "flex flex-col" ]
        [ MB.view
            { start =
                [ MB.TextInput
                    { tagger = SetQuery
                    , value = model.query
                    , placeholder = "Search…"
                    , icon = Just "fa fa-search"
                    }
                , MB.Checkbox
                    { tagger = \_ -> ToggleOwningOnly
                    , label = "Show owning folders only"
                    , value = model.owningOnly
                    , id = "folder-toggle-owner"
                    }
                ]
            , end =
                [ MB.PrimaryButton
                    { tagger = InitNewFolder
                    , title = "Create a new folder"
                    , icon = Just "fa fa-plus"
                    , label = "New Folder"
                    }
                ]
            , rootClasses = "mb-4"
            }
        , Html.map TableMsg (Comp.FolderTable.view2 model.tableModel model.folders)
        , div
            [ classList
                [ ( "ui dimmer", True )
                , ( "active", model.loading )
                ]
            ]
            [ div [ class "ui loader" ] []
            ]
        ]
