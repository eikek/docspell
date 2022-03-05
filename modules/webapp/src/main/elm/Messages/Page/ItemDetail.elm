{-
   Copyright 2020 Eike K. & Contributors

   SPDX-License-Identifier: AGPL-3.0-or-later
-}


module Messages.Page.ItemDetail exposing
    ( Texts
    , de
    , gb
    , fr
    )

import Data.TimeZone exposing (TimeZone)
import Messages.Comp.ItemDetail
import Messages.Comp.ItemDetail.EditForm


type alias Texts =
    { itemDetail : Messages.Comp.ItemDetail.Texts
    , editForm : Messages.Comp.ItemDetail.EditForm.Texts
    , editMetadata : String
    , collapseExpand : String
    }


gb : TimeZone -> Texts
gb tz =
    { itemDetail = Messages.Comp.ItemDetail.gb tz
    , editForm = Messages.Comp.ItemDetail.EditForm.gb tz
    , editMetadata = "Edit Metadata"
    , collapseExpand = "Collapse/Expand"
    }


de : TimeZone -> Texts
de tz =
    { itemDetail = Messages.Comp.ItemDetail.de tz
    , editForm = Messages.Comp.ItemDetail.EditForm.de tz
    , editMetadata = "Metadaten ändern"
    , collapseExpand = "Aus-/Einklappen"
    }


fr : TimeZone -> Texts
fr tz =
    { itemDetail = Messages.Comp.ItemDetail.fr tz
    , editForm = Messages.Comp.ItemDetail.EditForm.fr tz
    , editMetadata = "Editer les métadonnées"
    , collapseExpand = "Réduire/Etendre"
    }
