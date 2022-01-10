{-
   Copyright 2020 Eike K. & Contributors

   SPDX-License-Identifier: AGPL-3.0-or-later
-}


module Comp.BookmarkQueryManage exposing (..)

import Api
import Api.Model.BasicResult exposing (BasicResult)
import Api.Model.BookmarkedQuery exposing (BookmarkedQuery)
import Comp.Basic as B
import Comp.BookmarkQueryForm
import Data.Flags exposing (Flags)
import Html exposing (Html, div, text)
import Html.Attributes exposing (class, href)
import Html.Events exposing (onClick)
import Http
import Messages.Comp.BookmarkQueryManage exposing (Texts)
import Styles as S


type alias Model =
    { formModel : Comp.BookmarkQueryForm.Model
    , loading : Bool
    , formState : FormState
    }


type FormState
    = FormStateNone
    | FormStateError Http.Error
    | FormStateSaveError String
    | FormStateInvalid
    | FormStateSaved


init : String -> ( Model, Cmd Msg )
init query =
    let
        ( fm, fc ) =
            Comp.BookmarkQueryForm.initQuery query
    in
    ( { formModel = fm
      , loading = False
      , formState = FormStateNone
      }
    , Cmd.map FormMsg fc
    )


type Msg
    = Submit
    | Cancel
    | FormMsg Comp.BookmarkQueryForm.Msg
    | SaveResp (Result Http.Error BasicResult)



--- Update


type FormResult
    = Submitted BookmarkedQuery
    | Cancelled
    | Done
    | None


type alias UpdateResult =
    { model : Model
    , cmd : Cmd Msg
    , sub : Sub Msg
    , outcome : FormResult
    }


update : Flags -> Msg -> Model -> UpdateResult
update flags msg model =
    let
        empty =
            { model = model
            , cmd = Cmd.none
            , sub = Sub.none
            , outcome = None
            }
    in
    case msg of
        FormMsg lm ->
            let
                ( fm, fc, fs ) =
                    Comp.BookmarkQueryForm.update flags lm model.formModel
            in
            { model = { model | formModel = fm }
            , cmd = Cmd.map FormMsg fc
            , sub = Sub.map FormMsg fs
            , outcome = None
            }

        Submit ->
            case Comp.BookmarkQueryForm.get model.formModel of
                Just data ->
                    { empty | cmd = save flags data, outcome = Submitted data, model = { model | loading = True } }

                Nothing ->
                    { empty | model = { model | formState = FormStateInvalid } }

        Cancel ->
            { model = model
            , cmd = Cmd.none
            , sub = Sub.none
            , outcome = Cancelled
            }

        SaveResp (Ok res) ->
            if res.success then
                { empty | model = { model | loading = False, formState = FormStateSaved }, outcome = Done }

            else
                { empty | model = { model | loading = False, formState = FormStateSaveError res.message } }

        SaveResp (Err err) ->
            { empty | model = { model | loading = False, formState = FormStateError err } }


save : Flags -> BookmarkedQuery -> Cmd Msg
save flags model =
    Api.addBookmark flags model SaveResp



--- View


view : Texts -> Model -> Html Msg
view texts model =
    div [ class "relative" ]
        [ B.loadingDimmer { label = "", active = model.loading }
        , Html.map FormMsg (Comp.BookmarkQueryForm.view texts.form model.formModel)
        , case model.formState of
            FormStateNone ->
                div [ class "hidden" ] []

            FormStateError err ->
                div [ class S.errorMessage ]
                    [ text <| texts.httpError err
                    ]

            FormStateInvalid ->
                div [ class S.errorMessage ]
                    [ text texts.formInvalid
                    ]

            FormStateSaveError m ->
                div [ class S.errorMessage ]
                    [ text m
                    ]

            FormStateSaved ->
                div [ class S.successMessage ]
                    [ text texts.saved
                    ]
        , div [ class "flex flex-row space-x-2 py-2" ]
            [ B.primaryButton
                { label = texts.basics.submit
                , icon = "fa fa-save"
                , disabled = False
                , handler = onClick Submit
                , attrs = [ href "#" ]
                }
            , B.secondaryButton
                { label = texts.basics.cancel
                , icon = "fa fa-times"
                , disabled = False
                , handler = onClick Cancel
                , attrs = [ href "#" ]
                }
            ]
        ]
