{-
   Copyright 2020 Eike K. & Contributors

   SPDX-License-Identifier: AGPL-3.0-or-later
-}


module Messages.Comp.ItemDetail.ConfirmModal exposing
    ( Texts
    , de
    , fr
    , gb
    , pt
    )

import Messages.Basics


type alias Texts =
    { basics : Messages.Basics.Texts
    , confirmReprocessItem : String -> String
    , confirmReprocessFile : String -> String
    , confirmDeleteItem : String
    , confirmDeleteFile : String
    , confirmDeleteAllFiles : String
    }


gb : Texts
gb =
    { basics = Messages.Basics.gb
    , confirmReprocessItem =
        \state ->
            if state == "created" then
                "Reprocessing this item may change its metadata, "
                    ++ "since it is unconfirmed. Do you want to proceed?"

            else
                "Reprocessing this item will not change its metadata, "
                    ++ "since it has been confirmed. Do you want to proceed?"
    , confirmReprocessFile =
        \state ->
            if state == "created" then
                "Reprocessing this file may change metadata of "
                    ++ "this item, since it is unconfirmed. Do you want to proceed?"

            else
                "Reprocessing this file will not change metadata of "
                    ++ "this item, since it has been confirmed. Do you want to proceed?"
    , confirmDeleteItem =
        "Really trash this item? It can be resurrected from trash for some time."
    , confirmDeleteFile = "Really delete this file?"
    , confirmDeleteAllFiles = "Really delete these files?"
    }


de : Texts
de =
    { basics = Messages.Basics.de
    , confirmReprocessItem =
        \state ->
            if state == "created" then
                "Durch die Neuverarbeitung dieses Dokuments können sich die Metadaten ändern, "
                    ++ "da sie nicht bestätigt sind. Möchtest du fortfahren?"

            else
                "Die Neuverarbeitung dieses Dokuments wird dessen Metadaten nicht beeinflussen, "
                    ++ "da sie nicht bestätigt wurden. Möchtest du fortfahren?"
    , confirmReprocessFile =
        \state ->
            if state == "created" then
                "Durch die Neuverarbeitung dieses Anhangs können sich die Metadaten des Dokuments ändern, "
                    ++ " da sie nicht bestätigt sind. Möchtest du fortfahren?"

            else
                "Die Neuverarbeitung dieses Anhangs wird die Metadaten des Dokuments nicht beeinflussen, "
                    ++ "da sie bereits bestätigt sind. Möchtest du fortfahren?"
    , confirmDeleteItem =
        "Dieses Dokument wirklich löschen? Es kann für einige Zeit aus dem Papierkorb wiederhergestellt werden."
    , confirmDeleteFile = "Diese Datei wirklich löschen?"
    , confirmDeleteAllFiles = "Die gewählten Dateien wirklich löschen?"
    }


fr : Texts
fr =
    { basics = Messages.Basics.fr
    , confirmReprocessItem =
        \state ->
            if state == "created" then
                "Le retraitement du document peut affecter ses métadonnées,"
                    ++ " car il n'a pas été validé. Continuer ?"

            else
                "Le retraitement du document n'affectera pas ses métadonnées,"
                    ++ " car il a été validé. Continuer ?"
    , confirmReprocessFile =
        \state ->
            if state == "created" then
                "Le retraitement  de ce fichier peut affecter les métadonnées du document, "
                    ++ " car il n'a pas été validé.  Continuer ?"

            else
                "Le retraitement  de ce fichier n'affectera pas les métadonnées du document,  "
                    ++ " car il a été validé. Continuer ?"
    , confirmDeleteItem =
        "Confirmer la suppression du document ? Il pourra être récupéré via la corbeille pendant un temps."
    , confirmDeleteFile = "Confirmer la suppresion de ce fichier ?"
    , confirmDeleteAllFiles = "Confirmer la suppresion de tous ces fichiers ?"
    }


pt : Texts
pt =
    { basics = Messages.Basics.pt
    , confirmReprocessItem =
        \state ->
            if state == "created" then
                "Reprocessar este item pode alterar seus metadados, "
                    ++ "pois ele não está confirmado. Deseja prosseguir?"

            else
                "Reprocessar este item não alterará seus metadados, "
                    ++ "pois ele já foi confirmado. Deseja prosseguir?"
    , confirmReprocessFile =
        \state ->
            if state == "created" then
                "Reprocessar este arquivo pode alterar os metadados "
                    ++ "deste item, pois ele não está confirmado. Deseja prosseguir?"

            else
                "Reprocessar este arquivo não alterará os metadados "
                    ++ "deste item, pois ele já foi confirmado. Deseja prosseguir?"
    , confirmDeleteItem =
        "Deseja realmente mover este item para a lixeira? Ele poderá ser restaurado por algum tempo."
    , confirmDeleteFile = "Deseja realmente excluir este arquivo?"
    , confirmDeleteAllFiles = "Deseja realmente excluir estes arquivos?"
    }
