{-
   Copyright 2020 Eike K. & Contributors

   SPDX-License-Identifier: AGPL-3.0-or-later
-}


module Messages.Comp.ItemDetail.MultiEditMenu exposing
    ( Texts
    , de
    , fr
    , gb
    )

import Data.Direction exposing (Direction)
import Messages.Basics
import Messages.Comp.CustomFieldMultiInput
import Messages.Comp.TagDropdown
import Messages.Data.Direction


type alias Texts =
    { basics : Messages.Basics.Texts
    , customFieldMultiInput : Messages.Comp.CustomFieldMultiInput.Texts
    , tagDropdown : Messages.Comp.TagDropdown.Texts
    , tagModeAddInfo : String
    , tagModeRemoveInfo : String
    , tagModeReplaceInfo : String
    , chooseDirection : String
    , confirmUnconfirm : String
    , confirm : String
    , unconfirm : String
    , changeTagMode : String
    , dueDateTab : String
    , direction : Direction -> String
    }


gb : Texts
gb =
    { basics = Messages.Basics.gb
    , customFieldMultiInput = Messages.Comp.CustomFieldMultiInput.gb
    , tagDropdown = Messages.Comp.TagDropdown.gb
    , tagModeAddInfo = "Tags chosen here are *added* to all selected items."
    , tagModeRemoveInfo = "Tags chosen here are *removed* from all selected items."
    , tagModeReplaceInfo = "Tags chosen here *replace* those on selected items."
    , chooseDirection = "Choose a direction…"
    , confirmUnconfirm = "Confirm/Unconfirm metadata"
    , confirm = "Confirm"
    , unconfirm = "Unconfirm"
    , changeTagMode = "Change tag edit mode"
    , dueDateTab = "Due Date"
    , direction = Messages.Data.Direction.gb
    }


de : Texts
de =
    { basics = Messages.Basics.de
    , customFieldMultiInput = Messages.Comp.CustomFieldMultiInput.de
    , tagDropdown = Messages.Comp.TagDropdown.de
    , tagModeAddInfo = "Tags werden zu gewählten Dokumenten *hinzugefügt*."
    , tagModeRemoveInfo = "Tags werden von gewählten Dokumenten *entfernt*."
    , tagModeReplaceInfo = "Tags *ersetzen* die der gewählten Dokumente."
    , chooseDirection = "Wähle eine Richtung…"
    , confirmUnconfirm = "Bestätige/Widerrufe Metadaten"
    , confirm = "Bestätige"
    , unconfirm = "Widerrufe Bestätigung"
    , changeTagMode = "Wechsel den Änderungsmodus für Tags"
    , dueDateTab = "Fälligkeitsdatum"
    , direction = Messages.Data.Direction.de
    }


fr : Texts
fr =
    { basics = Messages.Basics.fr
    , customFieldMultiInput = Messages.Comp.CustomFieldMultiInput.fr
    , tagDropdown = Messages.Comp.TagDropdown.fr
    , tagModeAddInfo = "Les tags choisis ici sont *attribués* aux documents sélectionnés"
    , tagModeRemoveInfo = "Les tags choisis ici sont *supprimés* des documents sélectionnés"
    , tagModeReplaceInfo = "Les tags choisis ici *remplacent* ceux des documents sélectionnés"
    , chooseDirection = "Choisir un sens"
    , confirmUnconfirm = "Valider/Invalider les métadonnées"
    , confirm = "Valider"
    , unconfirm = "Invalider"
    , changeTagMode = "Changer le mode d'édition des tags"
    , dueDateTab = "Date d'échéance"
    , direction = Messages.Data.Direction.fr
    }
