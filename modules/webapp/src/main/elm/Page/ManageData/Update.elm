{-
   Copyright 2020 Eike K. & Contributors

   SPDX-License-Identifier: AGPL-3.0-or-later
-}


module Page.ManageData.Update exposing (update)

import Comp.BookmarkManage
import Comp.CustomFieldManage
import Comp.EquipmentManage
import Comp.FolderManage
import Comp.OrgManage
import Comp.PersonManage
import Comp.TagManage
import Data.Flags exposing (Flags)
import Page.ManageData.Data exposing (..)


update : Flags -> Msg -> Model -> ( Model, Cmd Msg, Sub Msg )
update flags msg model =
    case msg of
        SetTab t ->
            let
                m =
                    { model | currentTab = Just t }
            in
            case t of
                TagTab ->
                    update flags (TagManageMsg Comp.TagManage.LoadTags) m

                EquipTab ->
                    update flags (EquipManageMsg Comp.EquipmentManage.LoadEquipments) m

                OrgTab ->
                    update flags (OrgManageMsg Comp.OrgManage.LoadOrgs) m

                PersonTab ->
                    update flags (PersonManageMsg Comp.PersonManage.LoadPersons) m

                FolderTab ->
                    let
                        ( sm, sc ) =
                            Comp.FolderManage.init flags
                    in
                    ( { m | folderManageModel = sm }, Cmd.map FolderMsg sc, Sub.none )

                CustomFieldTab ->
                    let
                        ( cm, cc ) =
                            Comp.CustomFieldManage.init flags
                    in
                    ( { m | fieldManageModel = cm }, Cmd.map CustomFieldMsg cc, Sub.none )

                BookmarkTab ->
                    let
                        ( bm, bc ) =
                            Comp.BookmarkManage.init flags
                    in
                    ( { m | bookmarkModel = bm }, Cmd.map BookmarkMsg bc, Sub.none )

        TagManageMsg m ->
            let
                ( m2, c2 ) =
                    Comp.TagManage.update flags m model.tagManageModel
            in
            ( { model | tagManageModel = m2 }, Cmd.map TagManageMsg c2, Sub.none )

        EquipManageMsg m ->
            let
                ( m2, c2 ) =
                    Comp.EquipmentManage.update flags m model.equipManageModel
            in
            ( { model | equipManageModel = m2 }, Cmd.map EquipManageMsg c2, Sub.none )

        OrgManageMsg m ->
            let
                ( m2, c2 ) =
                    Comp.OrgManage.update flags m model.orgManageModel
            in
            ( { model | orgManageModel = m2 }, Cmd.map OrgManageMsg c2, Sub.none )

        PersonManageMsg m ->
            let
                ( m2, c2 ) =
                    Comp.PersonManage.update flags m model.personManageModel
            in
            ( { model | personManageModel = m2 }, Cmd.map PersonManageMsg c2, Sub.none )

        FolderMsg lm ->
            let
                ( m2, c2 ) =
                    Comp.FolderManage.update flags lm model.folderManageModel
            in
            ( { model | folderManageModel = m2 }
            , Cmd.map FolderMsg c2
            , Sub.none
            )

        CustomFieldMsg lm ->
            let
                ( m2, c2 ) =
                    Comp.CustomFieldManage.update flags lm model.fieldManageModel
            in
            ( { model | fieldManageModel = m2 }
            , Cmd.map CustomFieldMsg c2
            , Sub.none
            )

        BookmarkMsg lm ->
            let
                ( m2, c2, s2 ) =
                    Comp.BookmarkManage.update flags lm model.bookmarkModel
            in
            ( { model | bookmarkModel = m2 }
            , Cmd.map BookmarkMsg c2
            , Sub.map BookmarkMsg s2
            )
