module Messages.Page.ItemDetail exposing (Texts, gb)

import Messages.Comp.ItemDetail
import Messages.Comp.ItemDetail.EditForm


type alias Texts =
    { itemDetail : Messages.Comp.ItemDetail.Texts
    , editForm : Messages.Comp.ItemDetail.EditForm.Texts
    , editMetadata : String
    , collapseExpand : String
    }


gb : Texts
gb =
    { itemDetail = Messages.Comp.ItemDetail.gb
    , editForm = Messages.Comp.ItemDetail.EditForm.gb
    , editMetadata = "Edit Metadata"
    , collapseExpand = "Collapse/Expand"
    }
