{-
   Copyright 2020 Eike K. & Contributors

   SPDX-License-Identifier: AGPL-3.0-or-later
-}


module Page.Dashboard.Update exposing (update)

import Browser.Navigation as Nav
import Comp.BookmarkChooser
import Comp.DashboardEdit
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
import Data.Flags exposing (Flags)
import Data.UiSettings exposing (UiSettings)
import Messages.Page.Dashboard exposing (Texts)
import Page exposing (Page(..))
import Page.Dashboard.Data exposing (..)
import Page.Dashboard.DefaultDashboard
import Set


update : Texts -> UiSettings -> Nav.Key -> Flags -> Msg -> Model -> ( Model, Cmd Msg, Sub Msg )
update texts settings navKey flags msg model =
    case msg of
        GetBookmarksResp list ->
            let
                sideMenu =
                    model.sideMenu
            in
            unit
                { model | sideMenu = { sideMenu | bookmarkChooser = Comp.BookmarkChooser.init list } }

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

        InitDashboard ->
            case model.content of
                Home _ ->
                    update texts settings navKey flags ReloadDashboardData model

                _ ->
                    update texts settings navKey flags ReloadDashboard model

        ReloadDashboard ->
            let
                board =
                    Page.Dashboard.DefaultDashboard.getDefaultDashboard flags settings

                ( dm, dc ) =
                    Comp.DashboardView.init flags board
            in
            ( { model | content = Home dm }, Cmd.map DashboardMsg dc, Sub.none )

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
                        ( dm, dc, ds ) =
                            Comp.DashboardEdit.init flags m.dashboard
                    in
                    ( { model | content = Edit dm }
                    , Cmd.map DashboardEditMsg dc
                    , Sub.map DashboardEditMsg ds
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

        DashboardEditMsg lm ->
            case model.content of
                Edit m ->
                    let
                        result =
                            Comp.DashboardEdit.update flags lm m
                    in
                    case result.action of
                        Comp.DashboardEdit.SubmitNone ->
                            ( { model | content = Edit result.model }
                            , Cmd.map DashboardEditMsg result.cmd
                            , Sub.map DashboardEditMsg result.sub
                            )

                        Comp.DashboardEdit.SubmitSave board ->
                            let
                                ( dm, dc ) =
                                    Comp.DashboardView.init flags board
                            in
                            ( { model | content = Home dm }, Cmd.map DashboardMsg dc, Sub.none )

                        Comp.DashboardEdit.SubmitCancel ->
                            update texts settings navKey flags ReloadDashboard model

                        Comp.DashboardEdit.SubmitDelete _ ->
                            ( { model | content = Edit result.model }
                            , Cmd.map DashboardEditMsg result.cmd
                            , Sub.map DashboardEditMsg result.sub
                            )

                _ ->
                    unit model

        ReloadDashboardData ->
            let
                lm =
                    DashboardMsg Comp.DashboardView.reloadData
            in
            update texts settings navKey flags lm model


unit : Model -> ( Model, Cmd Msg, Sub Msg )
unit m =
    ( m, Cmd.none, Sub.none )
