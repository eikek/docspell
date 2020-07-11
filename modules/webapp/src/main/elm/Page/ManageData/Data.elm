module Page.ManageData.Data exposing
    ( Model
    , Msg(..)
    , Tab(..)
    , init
    )

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
    }


init : Flags -> ( Model, Cmd Msg )
init _ =
    ( { currentTab = Nothing
      , tagManageModel = Comp.TagManage.emptyModel
      , equipManageModel = Comp.EquipmentManage.emptyModel
      , orgManageModel = Comp.OrgManage.emptyModel
      , personManageModel = Comp.PersonManage.emptyModel
      , folderManageModel = Comp.FolderManage.empty
      }
    , Cmd.none
    )


type Tab
    = TagTab
    | EquipTab
    | OrgTab
    | PersonTab
    | FolderTab


type Msg
    = SetTab Tab
    | TagManageMsg Comp.TagManage.Msg
    | EquipManageMsg Comp.EquipmentManage.Msg
    | OrgManageMsg Comp.OrgManage.Msg
    | PersonManageMsg Comp.PersonManage.Msg
    | FolderMsg Comp.FolderManage.Msg
