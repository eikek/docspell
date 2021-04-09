module Messages.Page.ManageData exposing (..)

import Messages.Basics
import Messages.Comp.CustomFieldManage
import Messages.Comp.EquipmentManage
import Messages.Comp.FolderManage
import Messages.Comp.OrgManage
import Messages.Comp.PersonManage
import Messages.Comp.TagManage


type alias Texts =
    { basics : Messages.Basics.Texts
    , tagManage : Messages.Comp.TagManage.Texts
    , equipmentManage : Messages.Comp.EquipmentManage.Texts
    , orgManage : Messages.Comp.OrgManage.Texts
    , personManage : Messages.Comp.PersonManage.Texts
    , folderManage : Messages.Comp.FolderManage.Texts
    , customFieldManage : Messages.Comp.CustomFieldManage.Texts
    , manageData : String
    , equipment : String
    , organization : String
    , person : String
    , folder : String
    , customFields : String
    }


gb : Texts
gb =
    { basics = Messages.Basics.gb
    , tagManage = Messages.Comp.TagManage.gb
    , equipmentManage = Messages.Comp.EquipmentManage.gb
    , orgManage = Messages.Comp.OrgManage.gb
    , personManage = Messages.Comp.PersonManage.gb
    , folderManage = Messages.Comp.FolderManage.gb
    , customFieldManage = Messages.Comp.CustomFieldManage.gb
    , manageData = "Manage Data"
    , equipment = "Equipment"
    , organization = "Organization"
    , person = "Person"
    , folder = "Folder"
    , customFields = "Custom Fields"
    }


de : Texts
de =
    gb
