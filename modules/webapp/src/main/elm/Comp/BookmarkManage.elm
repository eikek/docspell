{-
   Copyright 2020 Eike K. & Contributors

   SPDX-License-Identifier: AGPL-3.0-or-later
-}


module Comp.BookmarkManage exposing (Model, Msg, init, loadBookmarks, update, view)

import Api
import Api.Model.BasicResult exposing (BasicResult)
import Comp.Basic as B
import Comp.BookmarkQueryForm
import Comp.BookmarkTable
import Comp.ItemDetail.Model exposing (Msg(..))
import Comp.MenuBar as MB
import Data.Bookmarks exposing (AllBookmarks)
import Data.Flags exposing (Flags)
import Data.UiSettings exposing (UiSettings)
import Html exposing (..)
import Html.Attributes exposing (..)
import Html.Events exposing (onClick)
import Http
import Messages.Comp.BookmarkManage exposing (Texts)
import Page exposing (Page(..))
import Styles as S


type FormError
    = FormErrorNone
    | FormErrorHttp Http.Error
    | FormErrorInvalid
    | FormErrorSubmit String


type ViewMode
    = Table
    | Form


type DeleteConfirm
    = DeleteConfirmOff
    | DeleteConfirmOn


type alias Model =
    { viewMode : ViewMode
    , bookmarks : AllBookmarks
    , formModel : Comp.BookmarkQueryForm.Model
    , loading : Bool
    , formError : FormError
    , deleteConfirm : DeleteConfirm
    }


init : Flags -> ( Model, Cmd Msg )
init flags =
    let
        ( fm, fc ) =
            Comp.BookmarkQueryForm.init
    in
    ( { viewMode = Table
      , bookmarks = Data.Bookmarks.empty
      , formModel = fm
      , loading = False
      , formError = FormErrorNone
      , deleteConfirm = DeleteConfirmOff
      }
    , Cmd.batch
        [ Cmd.map FormMsg fc
        , Api.getBookmarks flags LoadBookmarksResp
        ]
    )


type Msg
    = LoadBookmarks
    | TableMsg Comp.BookmarkTable.Msg
    | FormMsg Comp.BookmarkQueryForm.Msg
    | InitNewBookmark
    | SetViewMode ViewMode
    | Submit
    | RequestDelete
    | CancelDelete
    | DeleteBookmarkNow String
    | LoadBookmarksResp (Result Http.Error AllBookmarks)
    | AddBookmarkResp (Result Http.Error BasicResult)
    | UpdateBookmarkResp (Result Http.Error BasicResult)
    | DeleteBookmarkResp (Result Http.Error BasicResult)


loadBookmarks : Msg
loadBookmarks =
    LoadBookmarks



--- update


update : Flags -> Msg -> Model -> ( Model, Cmd Msg, Sub Msg )
update flags msg model =
    case msg of
        InitNewBookmark ->
            let
                ( bm, bc ) =
                    Comp.BookmarkQueryForm.init

                nm =
                    { model
                        | viewMode = Form
                        , formError = FormErrorNone
                        , formModel = bm
                    }
            in
            ( nm, Cmd.map FormMsg bc, Sub.none )

        SetViewMode vm ->
            ( { model | viewMode = vm, formError = FormErrorNone }
            , if vm == Table then
                Api.getBookmarks flags LoadBookmarksResp

              else
                Cmd.none
            , Sub.none
            )

        FormMsg lm ->
            let
                ( fm, fc, fs ) =
                    Comp.BookmarkQueryForm.update flags lm model.formModel
            in
            ( { model | formModel = fm, formError = FormErrorNone }
            , Cmd.map FormMsg fc
            , Sub.map FormMsg fs
            )

        TableMsg lm ->
            let
                action =
                    Comp.BookmarkTable.update lm
            in
            case action of
                Comp.BookmarkTable.Edit bookmark ->
                    let
                        ( bm, bc ) =
                            Comp.BookmarkQueryForm.initWith bookmark
                    in
                    ( { model
                        | viewMode = Form
                        , formError = FormErrorNone
                        , formModel = bm
                      }
                    , Cmd.map FormMsg bc
                    , Sub.none
                    )

        RequestDelete ->
            ( { model | deleteConfirm = DeleteConfirmOn }, Cmd.none, Sub.none )

        CancelDelete ->
            ( { model | deleteConfirm = DeleteConfirmOff }, Cmd.none, Sub.none )

        DeleteBookmarkNow id ->
            ( { model | deleteConfirm = DeleteConfirmOff, loading = True }
            , Api.deleteBookmark flags id DeleteBookmarkResp
            , Sub.none
            )

        LoadBookmarks ->
            ( { model | loading = True }
            , Api.getBookmarks flags LoadBookmarksResp
            , Sub.none
            )

        LoadBookmarksResp (Ok list) ->
            ( { model | loading = False, bookmarks = list, formError = FormErrorNone }
            , Cmd.none
            , Sub.none
            )

        LoadBookmarksResp (Err err) ->
            ( { model | loading = False, formError = FormErrorHttp err }, Cmd.none, Sub.none )

        Submit ->
            case Comp.BookmarkQueryForm.get model.formModel of
                Just data ->
                    if data.id /= "" then
                        ( { model | loading = True }, Api.updateBookmark flags data AddBookmarkResp, Sub.none )

                    else
                        ( { model | loading = True }, Api.addBookmark flags data AddBookmarkResp, Sub.none )

                Nothing ->
                    ( { model | formError = FormErrorInvalid }, Cmd.none, Sub.none )

        AddBookmarkResp (Ok res) ->
            if res.success then
                ( { model | loading = True, viewMode = Table }, Api.getBookmarks flags LoadBookmarksResp, Sub.none )

            else
                ( { model | loading = False, formError = FormErrorSubmit res.message }, Cmd.none, Sub.none )

        AddBookmarkResp (Err err) ->
            ( { model | loading = False, formError = FormErrorHttp err }, Cmd.none, Sub.none )

        UpdateBookmarkResp (Ok res) ->
            if res.success then
                ( model, Api.getBookmarks flags LoadBookmarksResp, Sub.none )

            else
                ( { model | loading = False, formError = FormErrorSubmit res.message }, Cmd.none, Sub.none )

        UpdateBookmarkResp (Err err) ->
            ( { model | loading = False, formError = FormErrorHttp err }, Cmd.none, Sub.none )

        DeleteBookmarkResp (Ok res) ->
            if res.success then
                update flags (SetViewMode Table) { model | loading = False }

            else
                ( { model | formError = FormErrorSubmit res.message, loading = False }, Cmd.none, Sub.none )

        DeleteBookmarkResp (Err err) ->
            ( { model | formError = FormErrorHttp err, loading = False }, Cmd.none, Sub.none )



--- view


view : Texts -> UiSettings -> Flags -> Model -> Html Msg
view texts settings flags model =
    if model.viewMode == Table then
        viewTable texts model

    else
        viewForm texts settings flags model


viewTable : Texts -> Model -> Html Msg
viewTable texts model =
    let
        ( user, coll ) =
            List.partition .personal model.bookmarks.bookmarks
    in
    div [ class "flex flex-col" ]
        [ MB.view
            { start =
                []
            , end =
                [ MB.PrimaryButton
                    { tagger = InitNewBookmark
                    , title = texts.createNewBookmark
                    , icon = Just "fa fa-plus"
                    , label = texts.newBookmark
                    }
                ]
            , rootClasses = "mb-4"
            }
        , div
            [ class "flex flex-col"
            , classList [ ( "hidden", user == [] ) ]
            ]
            [ h3 [ class S.header3 ]
                [ text texts.userBookmarks ]
            , Html.map TableMsg
                (Comp.BookmarkTable.view texts.bookmarkTable user)
            ]
        , div
            [ class "flex flex-col mt-3"
            , classList [ ( "hidden", coll == [] ) ]
            ]
            [ h3 [ class S.header3 ]
                [ text texts.collectiveBookmarks ]
            , Html.map TableMsg
                (Comp.BookmarkTable.view texts.bookmarkTable coll)
            ]
        , B.loadingDimmer
            { label = ""
            , active = model.loading
            }
        ]


viewForm : Texts -> UiSettings -> Flags -> Model -> Html Msg
viewForm texts _ _ model =
    let
        newBookmark =
            model.formModel.bookmark.id == ""

        isValid =
            Comp.BookmarkQueryForm.get model.formModel /= Nothing
    in
    div []
        [ Html.form []
            [ if newBookmark then
                h1 [ class S.header2 ]
                    [ text texts.createNewBookmark
                    ]

              else
                h1 [ class S.header2 ]
                    [ text (Maybe.withDefault "" model.formModel.name)
                    ]
            , MB.view
                { start =
                    [ MB.CustomElement <|
                        B.primaryButton
                            { handler = onClick Submit
                            , title = texts.basics.submitThisForm
                            , icon = "fa fa-save"
                            , label = texts.basics.submit
                            , disabled = not isValid
                            , attrs = [ href "#" ]
                            }
                    , MB.SecondaryButton
                        { tagger = SetViewMode Table
                        , title = texts.basics.backToList
                        , icon = Just "fa fa-arrow-left"
                        , label = texts.basics.cancel
                        }
                    ]
                , end =
                    if not newBookmark then
                        [ MB.DeleteButton
                            { tagger = RequestDelete
                            , title = texts.deleteThisBookmark
                            , icon = Just "fa fa-trash"
                            , label = texts.basics.delete
                            }
                        ]

                    else
                        []
                , rootClasses = "mb-4"
                }
            , div
                [ classList
                    [ ( "hidden", model.formError == FormErrorNone )
                    ]
                , class "my-2"
                , class S.errorMessage
                ]
                [ case model.formError of
                    FormErrorNone ->
                        text ""

                    FormErrorHttp err ->
                        text (texts.httpError err)

                    FormErrorInvalid ->
                        text texts.correctFormErrors

                    FormErrorSubmit m ->
                        text m
                ]
            , div []
                [ Html.map FormMsg (Comp.BookmarkQueryForm.view texts.bookmarkForm model.formModel)
                ]
            , B.loadingDimmer
                { active = model.loading
                , label = texts.basics.loading
                }
            , B.contentDimmer
                (model.deleteConfirm == DeleteConfirmOn)
                (div [ class "flex flex-col" ]
                    [ div [ class "text-lg" ]
                        [ i [ class "fa fa-info-circle mr-2" ] []
                        , text texts.reallyDeleteBookmark
                        ]
                    , div [ class "mt-4 flex flex-row items-center" ]
                        [ B.deleteButton
                            { label = texts.basics.yes
                            , icon = "fa fa-check"
                            , disabled = False
                            , handler = onClick (DeleteBookmarkNow model.formModel.bookmark.id)
                            , attrs = [ href "#" ]
                            }
                        , B.secondaryButton
                            { label = texts.basics.no
                            , icon = "fa fa-times"
                            , disabled = False
                            , handler = onClick CancelDelete
                            , attrs = [ href "#", class "ml-2" ]
                            }
                        ]
                    ]
                )
            ]
        ]
