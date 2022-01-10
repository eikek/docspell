{-
   Copyright 2020 Eike K. & Contributors

   SPDX-License-Identifier: AGPL-3.0-or-later
-}


module Page.ManageData.Data exposing
    ( Model
    , Msg(..)
    , Tab(..)
    , init
    )

import Comp.BookmarkManage
import Comp.CustomFieldManage
import Comp.EquipmentManage
import Comp.FolderManage
import Comp.OrgManage
import Comp.PersonManage
import Comp.TagManage
import Data.Flags exposing (Flags)


type alias Model =
    { currentTab : Maybe Tab
    , tagManageModel : Comp.TagManage.Model
    , equipManageModel : Comp.EquipmentManage.Model
    , orgManageModel : Comp.OrgManage.Model
    , personManageModel : Comp.PersonManage.Model
    , folderManageModel : Comp.FolderManage.Model
    , fieldManageModel : Comp.CustomFieldManage.Model
    , bookmarkModel : Comp.BookmarkManage.Model
    }


init : Flags -> ( Model, Cmd Msg )
init flags =
    let
        ( m2, c2 ) =
            Comp.TagManage.update flags Comp.TagManage.LoadTags Comp.TagManage.emptyModel

        ( bm, bc ) =
            Comp.BookmarkManage.init flags
    in
    ( { currentTab = Just TagTab
      , tagManageModel = m2
      , equipManageModel = Comp.EquipmentManage.emptyModel
      , orgManageModel = Comp.OrgManage.emptyModel
      , personManageModel = Comp.PersonManage.emptyModel
      , folderManageModel = Comp.FolderManage.empty
      , fieldManageModel = Comp.CustomFieldManage.empty
      , bookmarkModel = bm
      }
    , Cmd.batch
        [ Cmd.map TagManageMsg c2
        , Cmd.map BookmarkMsg bc
        ]
    )


type Tab
    = TagTab
    | EquipTab
    | OrgTab
    | PersonTab
    | FolderTab
    | CustomFieldTab
    | BookmarkTab


type Msg
    = SetTab Tab
    | TagManageMsg Comp.TagManage.Msg
    | EquipManageMsg Comp.EquipmentManage.Msg
    | OrgManageMsg Comp.OrgManage.Msg
    | PersonManageMsg Comp.PersonManage.Msg
    | FolderMsg Comp.FolderManage.Msg
    | CustomFieldMsg Comp.CustomFieldManage.Msg
    | BookmarkMsg Comp.BookmarkManage.Msg
