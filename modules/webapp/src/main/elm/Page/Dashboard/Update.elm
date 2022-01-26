{-
   Copyright 2020 Eike K. & Contributors

   SPDX-License-Identifier: AGPL-3.0-or-later
-}


module Page.Dashboard.Update exposing (update)

import Comp.BookmarkChooser
import Comp.EquipmentManage
import Comp.FolderManage
import Comp.NotificationHookManage
import Comp.OrgManage
import Comp.PeriodicQueryTaskManage
import Comp.PersonManage
import Comp.ShareManage
import Comp.SourceManage
import Comp.TagManage
import Data.Flags exposing (Flags)
import Messages.Page.Dashboard exposing (Texts)
import Page.Dashboard.Data exposing (..)


update : Texts -> Flags -> Msg -> Model -> ( Model, Cmd Msg, Sub Msg )
update texts flags msg model =
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
            in
            ( { model | sideMenu = { sideMenu | bookmarkChooser = bm } }
            , Cmd.none
            , Sub.none
            )

        InitDashboard ->
            ( { model | content = NoContent }, Cmd.none, Sub.none )

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


unit : Model -> ( Model, Cmd Msg, Sub Msg )
unit m =
    ( m, Cmd.none, Sub.none )
