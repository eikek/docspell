{-
   Copyright 2020 Eike K. & Contributors

   SPDX-License-Identifier: AGPL-3.0-or-later
-}


module Messages.Comp.EquipmentManage exposing
    ( Texts
    , de
    , fr
    , ja
    , gb
    )

import Http
import Messages.Basics
import Messages.Comp.EquipmentForm
import Messages.Comp.EquipmentTable
import Messages.Comp.HttpError


type alias Texts =
    { basics : Messages.Basics.Texts
    , equipmentTable : Messages.Comp.EquipmentTable.Texts
    , equipmentForm : Messages.Comp.EquipmentForm.Texts
    , httpError : Http.Error -> String
    , createNewEquipment : String
    , newEquipment : String
    , reallyDeleteEquipment : String
    , deleteThisEquipment : String
    , correctFormErrors : String
    }


gb : Texts
gb =
    { basics = Messages.Basics.gb
    , equipmentTable = Messages.Comp.EquipmentTable.gb
    , equipmentForm = Messages.Comp.EquipmentForm.gb
    , httpError = Messages.Comp.HttpError.gb
    , createNewEquipment = "Create a new equipment"
    , newEquipment = "New Equipment"
    , reallyDeleteEquipment = "Really delete this equipment?"
    , deleteThisEquipment = "Delete this equipment"
    , correctFormErrors = "Please correct the errors in the form."
    }


de : Texts
de =
    { basics = Messages.Basics.de
    , equipmentTable = Messages.Comp.EquipmentTable.de
    , equipmentForm = Messages.Comp.EquipmentForm.de
    , httpError = Messages.Comp.HttpError.de
    , createNewEquipment = "Neue Ausstattung anlegen"
    , newEquipment = "Neue Ausstattung"
    , reallyDeleteEquipment = "Diese Ausstattung wirklich löschen?"
    , deleteThisEquipment = "Ausstattung löschen"
    , correctFormErrors = "Bitte korrigiere die Fehler im Formular."
    }


fr : Texts
fr =
    { basics = Messages.Basics.fr
    , equipmentTable = Messages.Comp.EquipmentTable.fr
    , equipmentForm = Messages.Comp.EquipmentForm.fr
    , httpError = Messages.Comp.HttpError.fr
    , createNewEquipment = "Créer un nouvel équipement"
    , newEquipment = "Nouvel équipement"
    , reallyDeleteEquipment = "Confirmer la suppression de l'équipement ?"
    , deleteThisEquipment = "Supprimer cet équipement"
    , correctFormErrors = "Veuillez corriger les erreurs du formulaire."
    }


ja : Texts
ja =
    { basics = Messages.Basics.ja
    , equipmentTable = Messages.Comp.EquipmentTable.ja
    , equipmentForm = Messages.Comp.EquipmentForm.ja
    , httpError = Messages.Comp.HttpError.ja
    , createNewEquipment = "新しい機器を作成する"
    , newEquipment = "新規機器"
    , reallyDeleteEquipment = "この機器を本当に削除しますか？"
    , deleteThisEquipment = "この機器を削除"
    , correctFormErrors = "フォームの誤りを修正してください。"
    }
