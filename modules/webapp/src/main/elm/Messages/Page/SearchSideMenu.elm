{-
   Copyright 2020 Eike K. & Contributors

   SPDX-License-Identifier: AGPL-3.0-or-later
-}


module Messages.Page.SearchSideMenu exposing
    ( Texts
    , de
    , fr
    , gb
    , pt
    )

import Messages.Comp.ItemDetail.MultiEditMenu
import Messages.Comp.SearchMenu


type alias Texts =
    { searchMenu : Messages.Comp.SearchMenu.Texts
    , multiEdit : Messages.Comp.ItemDetail.MultiEditMenu.Texts
    , editMode : String
    , resetSearchForm : String
    , multiEditHeader : String
    , multiEditInfo : String
    , close : String
    }


gb : Texts
gb =
    { searchMenu = Messages.Comp.SearchMenu.gb
    , multiEdit = Messages.Comp.ItemDetail.MultiEditMenu.gb
    , editMode = "Edit Mode"
    , resetSearchForm = "Reset search form"
    , multiEditHeader = "Multi-Edit"
    , multiEditInfo = "Note that a change here immediatly affects all selected items on the right!"
    , close = "Close"
    }


de : Texts
de =
    { searchMenu = Messages.Comp.SearchMenu.de
    , multiEdit = Messages.Comp.ItemDetail.MultiEditMenu.de
    , editMode = "Änderungsmodus"
    , resetSearchForm = "Suchformular zurücksetzen"
    , multiEditHeader = "Mehrere Dokumente ändern"
    , multiEditInfo = "Beachte, dass eine Änderung hier direkt auf alle gewählten Dokumente angwendet wird!"
    , close = "Schließen"
    }


fr : Texts
fr =
    { searchMenu = Messages.Comp.SearchMenu.fr
    , multiEdit = Messages.Comp.ItemDetail.MultiEditMenu.fr
    , editMode = "Mode édition"
    , resetSearchForm = "Réinitialiser le formulaire de recherche"
    , multiEditHeader = "Multi-Edit"
    , multiEditInfo = "Veuillez noter qu'un changement ici, affecte immédiatement tous les documents sélectionnés à droite !"
    , close = "Fermer"
    }


pt : Texts
pt =
    { searchMenu = Messages.Comp.SearchMenu.pt
    , multiEdit = Messages.Comp.ItemDetail.MultiEditMenu.pt
    , editMode = "Modo de edição"
    , resetSearchForm = "Redefinir formulário de busca"
    , multiEditHeader = "Edição múltipla"
    , multiEditInfo = "Note que uma alteração aqui afeta imediatamente todos os itens selecionados à direita!"
    , close = "Fechar"
    }
