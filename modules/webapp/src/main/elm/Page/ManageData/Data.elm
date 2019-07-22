module Page.ManageData.Data exposing (..)

import Comp.TagManage
import Comp.EquipmentManage
import Comp.OrgManage
import Comp.PersonManage

type alias Model =
    { currentTab: Maybe Tab
    , tagManageModel: Comp.TagManage.Model
    , equipManageModel: Comp.EquipmentManage.Model
    , orgManageModel: Comp.OrgManage.Model
    , personManageModel: Comp.PersonManage.Model
    }

emptyModel: Model
emptyModel =
    { currentTab = Nothing
    , tagManageModel = Comp.TagManage.emptyModel
    , equipManageModel = Comp.EquipmentManage.emptyModel
    , orgManageModel = Comp.OrgManage.emptyModel
    , personManageModel = Comp.PersonManage.emptyModel
    }

type Tab
    = TagTab
    | EquipTab
    | OrgTab
    | PersonTab

type Msg
    = SetTab Tab
    | TagManageMsg Comp.TagManage.Msg
    | EquipManageMsg Comp.EquipmentManage.Msg
    | OrgManageMsg Comp.OrgManage.Msg
    | PersonManageMsg Comp.PersonManage.Msg
