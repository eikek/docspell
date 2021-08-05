{-
   Copyright 2020 Docspell Contributors

   SPDX-License-Identifier: GPL-3.0-or-later
-}


module Page.ManageData.Data exposing
    ( Model
    , Msg(..)
    , Tab(..)
    , init
    )

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
    }


init : Flags -> ( Model, Cmd Msg )
init flags =
    let
        ( m2, c2 ) =
            Comp.TagManage.update flags Comp.TagManage.LoadTags Comp.TagManage.emptyModel
    in
    ( { currentTab = Just TagTab
      , tagManageModel = m2
      , equipManageModel = Comp.EquipmentManage.emptyModel
      , orgManageModel = Comp.OrgManage.emptyModel
      , personManageModel = Comp.PersonManage.emptyModel
      , folderManageModel = Comp.FolderManage.empty
      , fieldManageModel = Comp.CustomFieldManage.empty
      }
    , Cmd.map TagManageMsg c2
    )


type Tab
    = TagTab
    | EquipTab
    | OrgTab
    | PersonTab
    | FolderTab
    | CustomFieldTab


type Msg
    = SetTab Tab
    | TagManageMsg Comp.TagManage.Msg
    | EquipManageMsg Comp.EquipmentManage.Msg
    | OrgManageMsg Comp.OrgManage.Msg
    | PersonManageMsg Comp.PersonManage.Msg
    | FolderMsg Comp.FolderManage.Msg
    | CustomFieldMsg Comp.CustomFieldManage.Msg
