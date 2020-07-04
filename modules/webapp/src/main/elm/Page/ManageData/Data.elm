module Page.ManageData.Data exposing
    ( Model
    , Msg(..)
    , Tab(..)
    , init
    )

import Comp.EquipmentManage
import Comp.OrgManage
import Comp.PersonManage
import Comp.SpaceManage
import Comp.TagManage
import Data.Flags exposing (Flags)


type alias Model =
    { currentTab : Maybe Tab
    , tagManageModel : Comp.TagManage.Model
    , equipManageModel : Comp.EquipmentManage.Model
    , orgManageModel : Comp.OrgManage.Model
    , personManageModel : Comp.PersonManage.Model
    , spaceManageModel : Comp.SpaceManage.Model
    }


init : Flags -> ( Model, Cmd Msg )
init _ =
    ( { currentTab = Nothing
      , tagManageModel = Comp.TagManage.emptyModel
      , equipManageModel = Comp.EquipmentManage.emptyModel
      , orgManageModel = Comp.OrgManage.emptyModel
      , personManageModel = Comp.PersonManage.emptyModel
      , spaceManageModel = Comp.SpaceManage.empty
      }
    , Cmd.none
    )


type Tab
    = TagTab
    | EquipTab
    | OrgTab
    | PersonTab
    | SpaceTab


type Msg
    = SetTab Tab
    | TagManageMsg Comp.TagManage.Msg
    | EquipManageMsg Comp.EquipmentManage.Msg
    | OrgManageMsg Comp.OrgManage.Msg
    | PersonManageMsg Comp.PersonManage.Msg
    | SpaceMsg Comp.SpaceManage.Msg
