module Comp.FolderManage exposing
    ( Model
    , Msg
    , empty
    , init
    , update
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
import Http
import Messages.FolderManageComp exposing (Texts)
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

        UserListResp (Err _) ->
            ( model, Cmd.none )

        FolderListResp (Ok sl) ->
            ( { model | folders = sl.items }, Cmd.none )

        FolderListResp (Err _) ->
            ( model, Cmd.none )

        FolderDetailResp (Ok sd) ->
            ( { model | detailModel = Comp.FolderDetail.init model.users sd |> Just }
            , Cmd.none
            )

        FolderDetailResp (Err _) ->
            ( model, Cmd.none )

        InitNewFolder ->
            let
                sd =
                    Comp.FolderDetail.initEmpty model.users
            in
            ( { model | detailModel = Just sd }
            , Cmd.none
            )



--- View2


view2 : Texts -> Flags -> Model -> Html Msg
view2 texts flags model =
    case model.detailModel of
        Just dm ->
            viewDetail2 texts flags dm

        Nothing ->
            viewTable2 texts model


viewDetail2 : Texts -> Flags -> Comp.FolderDetail.Model -> Html Msg
viewDetail2 texts flags model =
    div []
        [ if model.folder.id == "" then
            h3 [ class S.header2 ]
                [ text texts.createNewFolder
                ]

          else
            h3 [ class S.header2 ]
                [ text model.folder.name
                , div [ class "opacity-50 text-sm" ]
                    [ text (texts.basics.id ++ ": ")
                    , text model.folder.id
                    ]
                ]
        , Html.map DetailMsg
            (Comp.FolderDetail.view2 texts.folderDetail
                flags
                model
            )
        ]


viewTable2 : Texts -> Model -> Html Msg
viewTable2 texts model =
    div [ class "flex flex-col" ]
        [ MB.view
            { start =
                [ MB.TextInput
                    { tagger = SetQuery
                    , value = model.query
                    , placeholder = texts.basics.searchPlaceholder
                    , icon = Just "fa fa-search"
                    }
                , MB.Checkbox
                    { tagger = \_ -> ToggleOwningOnly
                    , label = texts.showOwningFoldersOnly
                    , value = model.owningOnly
                    , id = "folder-toggle-owner"
                    }
                ]
            , end =
                [ MB.PrimaryButton
                    { tagger = InitNewFolder
                    , title = texts.createNewFolder
                    , icon = Just "fa fa-plus"
                    , label = texts.newFolder
                    }
                ]
            , rootClasses = "mb-4"
            }
        , Html.map TableMsg
            (Comp.FolderTable.view2
                texts.folderTable
                model.tableModel
                model.folders
            )
        , div
            [ classList
                [ ( "ui dimmer", True )
                , ( "active", model.loading )
                ]
            ]
            [ div [ class "ui loader" ] []
            ]
        ]
