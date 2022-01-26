{-
   Copyright 2020 Eike K. & Contributors

   SPDX-License-Identifier: AGPL-3.0-or-later
-}


module Page.Dashboard.Update exposing (update)

import Api
import Browser.Navigation as Nav
import Comp.BookmarkChooser
import Comp.DashboardManage
import Comp.DashboardView
import Comp.EquipmentManage
import Comp.FolderManage
import Comp.NotificationHookManage
import Comp.OrgManage
import Comp.PeriodicQueryTaskManage
import Comp.PersonManage
import Comp.ShareManage
import Comp.SourceManage
import Comp.TagManage
import Comp.UploadForm
import Data.AccountScope
import Data.Dashboards
import Data.Flags exposing (Flags)
import Data.UiSettings exposing (UiSettings)
import Messages.Page.Dashboard exposing (Texts)
import Page exposing (Page(..))
import Page.Dashboard.Data exposing (..)
import Page.Dashboard.DefaultDashboard
import Set


update : Texts -> UiSettings -> Nav.Key -> Flags -> Msg -> Model -> ( Model, Cmd Msg, Sub Msg )
update texts settings navKey flags msg model =
    let
        nextRun amsg =
            nextRunModel amsg model

        nextRunModel amsg amodel =
            update texts settings navKey flags amsg amodel
    in
    case msg of
        GetBookmarksResp list ->
            let
                sideMenu =
                    model.sideMenu
            in
            unit
                { model | sideMenu = { sideMenu | bookmarkChooser = Comp.BookmarkChooser.init list } }

        GetAllDashboardsResp next (Ok boards) ->
            let
                nextModel =
                    if Data.Dashboards.isEmptyAll boards then
                        { model
                            | dashboards =
                                Data.Dashboards.singletonAll <|
                                    Page.Dashboard.DefaultDashboard.value texts.defaultDashboard
                            , isPredefined = True
                            , pageError = Nothing
                        }

                    else
                        { model | dashboards = boards, isPredefined = False, pageError = Nothing }
            in
            case next of
                Just nextMsg ->
                    nextRunModel nextMsg nextModel

                Nothing ->
                    unit nextModel

        GetAllDashboardsResp _ (Err err) ->
            unit { model | pageError = Just <| PageErrorHttp err }

        BookmarkMsg lm ->
            let
                sideMenu =
                    model.sideMenu

                ( bm, sel ) =
                    Comp.BookmarkChooser.update
                        lm
                        sideMenu.bookmarkChooser
                        Comp.BookmarkChooser.emptySelection

                bmId =
                    Set.toList sel.bookmarks |> List.head
            in
            ( { model | sideMenu = { sideMenu | bookmarkChooser = bm } }
            , Page.set navKey (SearchPage bmId)
            , Sub.none
            )

        ReloadDashboardData ->
            let
                lm =
                    DashboardMsg Comp.DashboardView.reloadData
            in
            update texts settings navKey flags lm model

        HardReloadDashboard ->
            case model.content of
                Home dm ->
                    let
                        board =
                            dm.dashboard

                        ( dm_, dc ) =
                            Comp.DashboardView.init flags board
                    in
                    ( { model | content = Home dm_ }, Cmd.map DashboardMsg dc, Sub.none )

                _ ->
                    unit model

        SetDashboard db ->
            let
                isVisible =
                    case model.content of
                        Home dm ->
                            dm.dashboard.name == db.name

                        _ ->
                            False
            in
            if isVisible then
                update texts settings navKey flags ReloadDashboardData model

            else
                let
                    ( dbm, dbc ) =
                        Comp.DashboardView.init flags db
                in
                ( { model | content = Home dbm, pageError = Nothing }
                , Cmd.map DashboardMsg dbc
                , Sub.none
                )

        SetDefaultDashboard ->
            case Data.Dashboards.getAllDefault model.dashboards of
                Just db ->
                    nextRun (SetDashboard db)

                Nothing ->
                    unit model

        SetDashboardByName name ->
            case Data.Dashboards.findInAll name model.dashboards of
                Just db ->
                    nextRun (SetDashboard db)

                Nothing ->
                    unit model

        InitNotificationHook ->
            let
                ( nhm, nhc ) =
                    Comp.NotificationHookManage.init flags
            in
            ( { model | content = Webhook nhm }, Cmd.map NotificationHookMsg nhc, Sub.none )

        InitPeriodicQuery ->
            let
                ( pqm, pqc ) =
                    Comp.PeriodicQueryTaskManage.init flags
            in
            ( { model | content = PeriodicQuery pqm }, Cmd.map PeriodicQueryMsg pqc, Sub.none )

        InitSource ->
            let
                ( sm, sc ) =
                    Comp.SourceManage.init flags
            in
            ( { model | content = Source sm }, Cmd.map SourceMsg sc, Sub.none )

        InitShare ->
            let
                ( sm, sc ) =
                    Comp.ShareManage.init flags
            in
            ( { model | content = Share sm }, Cmd.map ShareMsg sc, Sub.none )

        InitOrganization ->
            let
                ( om, oc ) =
                    Comp.OrgManage.init flags
            in
            ( { model | content = Organization om }, Cmd.map OrganizationMsg oc, Sub.none )

        InitPerson ->
            let
                ( pm, pc ) =
                    Comp.PersonManage.init flags
            in
            ( { model | content = Person pm }, Cmd.map PersonMsg pc, Sub.none )

        InitEquipment ->
            let
                ( em, ec ) =
                    Comp.EquipmentManage.init flags
            in
            ( { model | content = Equipment em }, Cmd.map EquipmentMsg ec, Sub.none )

        InitTags ->
            let
                ( tm, tc ) =
                    Comp.TagManage.init flags
            in
            ( { model | content = Tags tm }, Cmd.map TagMsg tc, Sub.none )

        InitFolder ->
            let
                ( fm, fc ) =
                    Comp.FolderManage.init flags
            in
            ( { model | content = Folder fm }, Cmd.map FolderMsg fc, Sub.none )

        InitUpload ->
            let
                um =
                    Comp.UploadForm.init
            in
            ( { model | content = Upload um }, Cmd.none, Sub.none )

        InitEditDashboard ->
            case model.content of
                Home m ->
                    let
                        default =
                            Data.Dashboards.isDefaultAll m.dashboard.name model.dashboards

                        scope =
                            Data.Dashboards.getScope m.dashboard.name model.dashboards
                                |> Maybe.withDefault Data.AccountScope.User

                        ( dm, dc, ds ) =
                            Comp.DashboardManage.init
                                { flags = flags
                                , dashboard = m.dashboard
                                , scope = scope
                                , isDefault = default
                                }
                    in
                    ( { model | content = Edit dm }
                    , Cmd.map DashboardManageMsg dc
                    , Sub.map DashboardManageMsg ds
                    )

                _ ->
                    unit model

        NotificationHookMsg lm ->
            case model.content of
                Webhook nhm ->
                    let
                        ( nhm_, nhc ) =
                            Comp.NotificationHookManage.update flags lm nhm
                    in
                    ( { model | content = Webhook nhm_ }, Cmd.map NotificationHookMsg nhc, Sub.none )

                _ ->
                    unit model

        PeriodicQueryMsg lm ->
            case model.content of
                PeriodicQuery pqm ->
                    let
                        ( pqm_, pqc, pqs ) =
                            Comp.PeriodicQueryTaskManage.update flags lm pqm
                    in
                    ( { model | content = PeriodicQuery pqm_ }
                    , Cmd.map PeriodicQueryMsg pqc
                    , Sub.map PeriodicQueryMsg pqs
                    )

                _ ->
                    unit model

        SourceMsg lm ->
            case model.content of
                Source m ->
                    let
                        ( sm, sc ) =
                            Comp.SourceManage.update flags lm m
                    in
                    ( { model | content = Source sm }, Cmd.map SourceMsg sc, Sub.none )

                _ ->
                    unit model

        ShareMsg lm ->
            case model.content of
                Share m ->
                    let
                        ( sm, sc, subs ) =
                            Comp.ShareManage.update texts.shareManage flags lm m
                    in
                    ( { model | content = Share sm }
                    , Cmd.map ShareMsg sc
                    , Sub.map ShareMsg subs
                    )

                _ ->
                    unit model

        OrganizationMsg lm ->
            case model.content of
                Organization m ->
                    let
                        ( om, oc ) =
                            Comp.OrgManage.update flags lm m
                    in
                    ( { model | content = Organization om }, Cmd.map OrganizationMsg oc, Sub.none )

                _ ->
                    unit model

        PersonMsg lm ->
            case model.content of
                Person m ->
                    let
                        ( pm, pc ) =
                            Comp.PersonManage.update flags lm m
                    in
                    ( { model | content = Person pm }, Cmd.map PersonMsg pc, Sub.none )

                _ ->
                    unit model

        EquipmentMsg lm ->
            case model.content of
                Equipment m ->
                    let
                        ( em, ec ) =
                            Comp.EquipmentManage.update flags lm m
                    in
                    ( { model | content = Equipment em }, Cmd.map EquipmentMsg ec, Sub.none )

                _ ->
                    unit model

        TagMsg lm ->
            case model.content of
                Tags m ->
                    let
                        ( tm, tc ) =
                            Comp.TagManage.update flags lm m
                    in
                    ( { model | content = Tags tm }, Cmd.map TagMsg tc, Sub.none )

                _ ->
                    unit model

        FolderMsg lm ->
            case model.content of
                Folder m ->
                    let
                        ( fm, fc ) =
                            Comp.FolderManage.update flags lm m
                    in
                    ( { model | content = Folder fm }, Cmd.map FolderMsg fc, Sub.none )

                _ ->
                    unit model

        UploadMsg lm ->
            case model.content of
                Upload m ->
                    let
                        ( um, uc, us ) =
                            Comp.UploadForm.update Nothing flags lm m
                    in
                    ( { model | content = Upload um }, Cmd.map UploadMsg uc, Sub.map UploadMsg us )

                _ ->
                    unit model

        DashboardMsg lm ->
            case model.content of
                Home m ->
                    let
                        ( dm, dc, ds ) =
                            Comp.DashboardView.update flags lm m
                    in
                    ( { model | content = Home dm }, Cmd.map DashboardMsg dc, Sub.map DashboardMsg ds )

                _ ->
                    unit model

        DashboardManageMsg lm ->
            case model.content of
                Edit m ->
                    let
                        nameExists name =
                            Data.Dashboards.existsAll name model.dashboards

                        result =
                            Comp.DashboardManage.update flags nameExists lm m
                    in
                    case result.action of
                        Comp.DashboardManage.SubmitNone ->
                            ( { model | content = Edit result.model }
                            , Cmd.map DashboardManageMsg result.cmd
                            , Sub.map DashboardManageMsg result.sub
                            )

                        Comp.DashboardManage.SubmitSaved name ->
                            ( { model | content = Edit result.model }
                            , Cmd.batch
                                [ Cmd.map DashboardManageMsg result.cmd
                                , getDashboards flags (Just <| SetDashboardByName name)
                                ]
                            , Sub.map DashboardManageMsg result.sub
                            )

                        Comp.DashboardManage.SubmitCancel name ->
                            case Data.Dashboards.findInAll name model.dashboards of
                                Just db ->
                                    update texts settings navKey flags (SetDashboard db) model

                                Nothing ->
                                    ( { model | content = Edit result.model }
                                    , Cmd.map DashboardManageMsg result.cmd
                                    , Sub.map DashboardManageMsg result.sub
                                    )

                        Comp.DashboardManage.SubmitDeleted ->
                            ( { model | content = Edit result.model }
                            , Cmd.batch
                                [ Cmd.map DashboardManageMsg result.cmd
                                , getDashboards flags (Just SetDefaultDashboard)
                                ]
                            , Sub.map DashboardManageMsg result.sub
                            )

                _ ->
                    unit model


unit : Model -> ( Model, Cmd Msg, Sub Msg )
unit m =
    ( m, Cmd.none, Sub.none )


getDashboards : Flags -> Maybe Msg -> Cmd Msg
getDashboards flags nextMsg =
    Api.getAllDashboards flags (GetAllDashboardsResp nextMsg)
