{-
   Copyright 2020 Eike K. & Contributors

   SPDX-License-Identifier: AGPL-3.0-or-later
-}


module Comp.DashboardManage exposing (Model, Msg, SubmitAction(..), UpdateResult, init, update, view)

import Api
import Api.Model.BasicResult exposing (BasicResult)
import Comp.Basic as B
import Comp.DashboardEdit
import Comp.MenuBar as MB
import Data.AccountScope exposing (AccountScope)
import Data.Dashboard exposing (Dashboard)
import Data.Flags exposing (Flags)
import Data.UiSettings exposing (UiSettings)
import Html exposing (Html, div, i, text)
import Html.Attributes exposing (class, classList)
import Http
import Messages.Comp.DashboardManage exposing (Texts)
import Styles as S


type alias Model =
    { edit : Comp.DashboardEdit.Model
    , initData : InitData
    , deleteRequested : Bool
    , formError : Maybe FormError
    }


type Msg
    = SaveDashboard
    | Cancel
    | DeleteDashboard
    | SetRequestDelete Bool
    | EditMsg Comp.DashboardEdit.Msg
    | DeleteResp (Result Http.Error BasicResult)
    | SaveResp String (Result Http.Error BasicResult)
    | CreateNew
    | CopyCurrent


type FormError
    = FormInvalid String
    | FormHttpError Http.Error
    | FormNameEmpty
    | FormNameExists


type alias InitData =
    { flags : Flags
    , dashboard : Dashboard
    , scope : AccountScope
    , isDefault : Bool
    }


init : InitData -> ( Model, Cmd Msg, Sub Msg )
init data =
    let
        ( em, ec, es ) =
            Comp.DashboardEdit.init data.flags data.dashboard data.scope data.isDefault

        model =
            { edit = em
            , initData = data
            , deleteRequested = False
            , formError = Nothing
            }
    in
    ( model, Cmd.map EditMsg ec, Sub.map EditMsg es )



--- Update


type SubmitAction
    = SubmitNone
    | SubmitCancel String
    | SubmitSaved String
    | SubmitDeleted


type alias UpdateResult =
    { model : Model
    , cmd : Cmd Msg
    , sub : Sub Msg
    , action : SubmitAction
    }


update : Flags -> (String -> Bool) -> Msg -> Model -> UpdateResult
update flags nameExists msg model =
    case msg of
        EditMsg lm ->
            let
                result =
                    Comp.DashboardEdit.update flags lm model.edit
            in
            { model = { model | edit = result.model }
            , cmd = Cmd.map EditMsg result.cmd
            , sub = Sub.map EditMsg result.sub
            , action = SubmitNone
            }

        CreateNew ->
            let
                initData =
                    { flags = flags
                    , dashboard = Data.Dashboard.empty
                    , scope = Data.AccountScope.User
                    , isDefault = False
                    }

                ( m, c, s ) =
                    init initData
            in
            UpdateResult m c s SubmitNone

        CopyCurrent ->
            let
                ( current, scope, isDefault ) =
                    Comp.DashboardEdit.getBoard model.edit

                initData =
                    { flags = flags
                    , dashboard = { current | name = "" }
                    , scope = scope
                    , isDefault = isDefault
                    }

                ( m, c, s ) =
                    init initData
            in
            UpdateResult m c s SubmitNone

        SetRequestDelete flag ->
            unit { model | deleteRequested = flag }

        SaveDashboard ->
            let
                ( tosave, scope, isDefault ) =
                    Comp.DashboardEdit.getBoard model.edit

                saveCmd =
                    Api.replaceDashboard flags
                        model.initData.dashboard.name
                        tosave
                        scope
                        isDefault
                        (SaveResp tosave.name)
            in
            if tosave.name == "" then
                unit { model | formError = Just FormNameEmpty }

            else if tosave.name /= model.initData.dashboard.name && nameExists tosave.name then
                unit { model | formError = Just FormNameExists }

            else
                UpdateResult model saveCmd Sub.none SubmitNone

        Cancel ->
            unitAction model (SubmitCancel model.initData.dashboard.name)

        DeleteDashboard ->
            let
                deleteCmd =
                    Api.deleteDashboard flags model.initData.dashboard.name model.initData.scope DeleteResp
            in
            UpdateResult model deleteCmd Sub.none SubmitNone

        SaveResp name (Ok result) ->
            if result.success then
                unitAction model (SubmitSaved name)

            else
                unit { model | formError = Just (FormInvalid result.message) }

        SaveResp _ (Err err) ->
            unit { model | formError = Just (FormHttpError err) }

        DeleteResp (Ok result) ->
            if result.success then
                unitAction model SubmitDeleted

            else
                unit { model | formError = Just (FormInvalid result.message) }

        DeleteResp (Err err) ->
            unit { model | formError = Just (FormHttpError err) }


unit : Model -> UpdateResult
unit model =
    UpdateResult model Cmd.none Sub.none SubmitNone


unitAction : Model -> SubmitAction -> UpdateResult
unitAction model action =
    UpdateResult model Cmd.none Sub.none action



--- View


type alias ViewSettings =
    { showDeleteButton : Bool
    , showCopyButton : Bool
    }


view : Texts -> Flags -> ViewSettings -> UiSettings -> Model -> Html Msg
view texts flags cfg settings model =
    div []
        [ B.contentDimmer model.deleteRequested
            (div [ class "flex flex-col" ]
                [ div [ class "text-xl" ]
                    [ i [ class "fa fa-info-circle mr-2" ] []
                    , text texts.reallyDeleteDashboard
                    ]
                , div [ class "mt-4 flex flex-row items-center space-x-2" ]
                    [ MB.viewItem <|
                        MB.DeleteButton
                            { tagger = DeleteDashboard
                            , title = ""
                            , label = texts.basics.yes
                            , icon = Just "fa fa-check"
                            }
                    , MB.viewItem <|
                        MB.SecondaryButton
                            { tagger = SetRequestDelete False
                            , title = ""
                            , label = texts.basics.no
                            , icon = Just "fa fa-times"
                            }
                    ]
                ]
            )
        , MB.view
            { start =
                [ MB.PrimaryButton
                    { tagger = SaveDashboard
                    , title = texts.basics.submitThisForm
                    , icon = Just "fa fa-save"
                    , label = texts.basics.submit
                    }
                , MB.SecondaryButton
                    { tagger = Cancel
                    , title = texts.basics.cancel
                    , icon = Just "fa fa-times"
                    , label = texts.basics.cancel
                    }
                ]
            , end =
                [ MB.BasicButton
                    { tagger = CreateNew
                    , title = texts.createDashboard
                    , icon = Just "fa fa-plus"
                    , label = texts.createDashboard
                    }
                , MB.CustomButton
                    { tagger = CopyCurrent
                    , title = texts.copyDashboard
                    , icon = Just "fa fa-copy"
                    , label = texts.copyDashboard
                    , inputClass =
                        [ ( S.secondaryBasicButton, True )
                        , ( "hidden", not cfg.showCopyButton )
                        ]
                    }
                , MB.CustomButton
                    { tagger = SetRequestDelete True
                    , title = texts.basics.delete
                    , icon = Just "fa fa-times"
                    , label = texts.basics.delete
                    , inputClass =
                        [ ( S.deleteButton, True )
                        , ( "hidden", not cfg.showDeleteButton )
                        ]
                    }
                ]
            , rootClasses = ""
            }
        , div
            [ class S.errorMessage
            , class "mt-2"
            , classList [ ( "hidden", model.formError == Nothing ) ]
            ]
            [ errorMessage texts model
            ]
        , div []
            [ Html.map EditMsg
                (Comp.DashboardEdit.view texts.dashboardEdit flags settings model.edit)
            ]
        ]


errorMessage : Texts -> Model -> Html Msg
errorMessage texts model =
    case model.formError of
        Just (FormInvalid errMsg) ->
            text errMsg

        Just (FormHttpError err) ->
            text (texts.httpError err)

        Just FormNameEmpty ->
            text texts.nameEmpty

        Just FormNameExists ->
            text texts.nameExists

        Nothing ->
            text ""
