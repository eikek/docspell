module Messages.ManageDataPage exposing (..)

import Messages.Basics
import Messages.CustomFieldManageComp
import Messages.EquipmentManageComp
import Messages.FolderManageComp
import Messages.OrgManageComp
import Messages.PersonManageComp
import Messages.TagManageComp


type alias Texts =
    { basics : Messages.Basics.Texts
    , tagManage : Messages.TagManageComp.Texts
    , equipmentManage : Messages.EquipmentManageComp.Texts
    , orgManage : Messages.OrgManageComp.Texts
    , personManage : Messages.PersonManageComp.Texts
    , folderManage : Messages.FolderManageComp.Texts
    , customFieldManage : Messages.CustomFieldManageComp.Texts
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
    , tagManage = Messages.TagManageComp.gb
    , equipmentManage = Messages.EquipmentManageComp.gb
    , orgManage = Messages.OrgManageComp.gb
    , personManage = Messages.PersonManageComp.gb
    , folderManage = Messages.FolderManageComp.gb
    , customFieldManage = Messages.CustomFieldManageComp.gb
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
