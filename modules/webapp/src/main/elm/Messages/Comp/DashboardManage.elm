{-
   Copyright 2020 Eike K. & Contributors

   SPDX-License-Identifier: AGPL-3.0-or-later
-}


module Messages.Comp.DashboardManage exposing (Texts, de, fr, gb)

import Http
import Messages.Basics
import Messages.Comp.DashboardEdit
import Messages.Comp.HttpError


type alias Texts =
    { basics : Messages.Basics.Texts
    , dashboardEdit : Messages.Comp.DashboardEdit.Texts
    , httpError : Http.Error -> String
    , reallyDeleteDashboard : String
    , nameEmpty : String
    , nameExists : String
    , createDashboard : String
    , copyDashboard : String
    }


gb : Texts
gb =
    { basics = Messages.Basics.gb
    , dashboardEdit = Messages.Comp.DashboardEdit.gb
    , httpError = Messages.Comp.HttpError.gb
    , reallyDeleteDashboard = "Really delete this dashboard?"
    , nameEmpty = "The name must not be empty."
    , nameExists = "The name is already in use."
    , createDashboard = "New"
    , copyDashboard = "Copy"
    }


de : Texts
de =
    { basics = Messages.Basics.de
    , dashboardEdit = Messages.Comp.DashboardEdit.de
    , httpError = Messages.Comp.HttpError.de
    , reallyDeleteDashboard = "Das Dashboard wirklich entfernen?"
    , nameEmpty = "Ein Name muss angegeben werden."
    , nameExists = "Der Name wird bereits verwendet."
    , createDashboard = "Neu"
    , copyDashboard = "Kopie"
    }


fr : Texts
fr =
    { basics = Messages.Basics.fr
    , dashboardEdit = Messages.Comp.DashboardEdit.fr
    , httpError = Messages.Comp.HttpError.fr
    , reallyDeleteDashboard = "Confirmer la suppression de ce tableau de bord ?"
    , nameEmpty = "Le nom ne peut être vide."
    , nameExists = "Ce nom est déjà utilisé."
    , createDashboard = "Nouveau"
    , copyDashboard = "Copier"
    }
