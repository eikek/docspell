module Messages.OrgManageComp exposing (..)

import Messages.Basics
import Messages.OrgFormComp
import Messages.OrgTableComp


type alias Texts =
    { basics : Messages.Basics.Texts
    , orgForm : Messages.OrgFormComp.Texts
    , orgTable : Messages.OrgTableComp.Texts
    , newOrganization : String
    , createNewOrganization : String
    , reallyDeleteOrg : String
    , deleteThisOrg : String
    }


gb : Texts
gb =
    { basics = Messages.Basics.gb
    , orgForm = Messages.OrgFormComp.gb
    , orgTable = Messages.OrgTableComp.gb
    , newOrganization = "New Organization"
    , createNewOrganization = "Create a new organization"
    , reallyDeleteOrg = "Really delete this organization?"
    , deleteThisOrg = "Delete this organization"
    }
