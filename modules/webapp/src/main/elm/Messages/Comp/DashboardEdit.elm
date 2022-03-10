{-
   Copyright 2020 Eike K. & Contributors

   SPDX-License-Identifier: AGPL-3.0-or-later
-}


module Messages.Comp.DashboardEdit exposing (Texts, de, fr, gb)

import Messages.Basics
import Messages.Comp.BoxEdit
import Messages.Data.AccountScope
import Messages.Data.BoxContent


type alias Texts =
    { boxView : Messages.Comp.BoxEdit.Texts
    , boxContent : Messages.Data.BoxContent.Texts
    , basics : Messages.Basics.Texts
    , accountScope : Messages.Data.AccountScope.Texts
    , namePlaceholder : String
    , columns : String
    , dashboardBoxes : String
    , newBox : String
    , defaultDashboard : String
    , gap : String
    }


gb : Texts
gb =
    { boxView = Messages.Comp.BoxEdit.gb
    , boxContent = Messages.Data.BoxContent.gb
    , basics = Messages.Basics.gb
    , accountScope = Messages.Data.AccountScope.gb
    , namePlaceholder = "Dashboard name"
    , columns = "Columns"
    , dashboardBoxes = "Dashboard Boxes"
    , newBox = "New box"
    , defaultDashboard = "Default Dashboard"
    , gap = "Gap"
    }


de : Texts
de =
    { boxView = Messages.Comp.BoxEdit.de
    , boxContent = Messages.Data.BoxContent.de
    , basics = Messages.Basics.de
    , accountScope = Messages.Data.AccountScope.de
    , namePlaceholder = "Dashboardname"
    , columns = "Spalten"
    , dashboardBoxes = "Dashboard Kacheln"
    , newBox = "Neue Kachel"
    , defaultDashboard = "Standard Dashboard"
    , gap = "Abstand"
    }


fr : Texts
fr =
    { boxView = Messages.Comp.BoxEdit.fr
    , boxContent = Messages.Data.BoxContent.fr
    , basics = Messages.Basics.fr
    , accountScope = Messages.Data.AccountScope.fr
    , namePlaceholder = "Nom du  tableau de bord "
    , columns = "Colonnes"
    , dashboardBoxes = "Boites du tableau de bord"
    , newBox = "Nouvelle boite"
    , defaultDashboard = "Tableau de bord par défaut"
    , gap = "Espace"
    }
