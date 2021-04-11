module Messages.Comp.OrgManage exposing (Texts, gb)

import Messages.Basics
import Messages.Comp.OrgForm
import Messages.Comp.OrgTable


type alias Texts =
    { basics : Messages.Basics.Texts
    , orgForm : Messages.Comp.OrgForm.Texts
    , orgTable : Messages.Comp.OrgTable.Texts
    , newOrganization : String
    , createNewOrganization : String
    , reallyDeleteOrg : String
    , deleteThisOrg : String
    }


gb : Texts
gb =
    { basics = Messages.Basics.gb
    , orgForm = Messages.Comp.OrgForm.gb
    , orgTable = Messages.Comp.OrgTable.gb
    , newOrganization = "New Organization"
    , createNewOrganization = "Create a new organization"
    , reallyDeleteOrg = "Really delete this organization?"
    , deleteThisOrg = "Delete this organization"
    }
