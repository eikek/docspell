{-
   Copyright 2020 Eike K. & Contributors

   SPDX-License-Identifier: AGPL-3.0-or-later
-}


module Messages.Comp.ItemDetail.ConfirmModal exposing
    ( Texts
    , de
    , fr
    , gb
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
