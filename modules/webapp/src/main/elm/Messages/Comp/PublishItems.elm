{-
   Copyright 2020 Eike K. & Contributors

   SPDX-License-Identifier: AGPL-3.0-or-later
-}


module Messages.Comp.PublishItems exposing
    ( Texts
    , de
    , gb
    )

import Http
import Messages.Basics
import Messages.Comp.HttpError
import Messages.Comp.ShareForm
import Messages.Comp.ShareView
import Messages.DateFormat
import Messages.UiLanguage


type alias Texts =
    { basics : Messages.Basics.Texts
    , httpError : Http.Error -> String
    , shareForm : Messages.Comp.ShareForm.Texts
    , shareView : Messages.Comp.ShareView.Texts
    , title : String
    , infoText : String
    , formatDateLong : Int -> String
    , formatDateShort : Int -> String
    , submitPublish : String
    , cancelPublish : String
    , submitPublishTitle : String
    , cancelPublishTitle : String
    , publishSuccessful : String
    , publishInProcess : String
    , correctFormErrors : String
    , doneLabel : String
    }


gb : Texts
gb =
    { basics = Messages.Basics.gb
    , httpError = Messages.Comp.HttpError.gb
    , shareForm = Messages.Comp.ShareForm.gb
    , shareView = Messages.Comp.ShareView.gb
    , title = "Publish Items"
    , infoText = "Publishing items creates a cryptic link, which can be used by everyone to see the selected documents. This link cannot be guessed, but is public! It exists for a certain amount of time and can be further protected using a password."
    , formatDateLong = Messages.DateFormat.formatDateLong Messages.UiLanguage.English
    , formatDateShort = Messages.DateFormat.formatDateShort Messages.UiLanguage.English
    , submitPublish = "Publish"
    , submitPublishTitle = "Publish the documents now"
    , cancelPublish = "Cancel"
    , cancelPublishTitle = "Back to select view"
    , publishSuccessful = "Items published successfully"
    , publishInProcess = "Items are published …"
    , correctFormErrors = "Please correct the errors in the form."
    , doneLabel = "Done"
    }


de : Texts
de =
    { basics = Messages.Basics.de
    , httpError = Messages.Comp.HttpError.de
    , shareForm = Messages.Comp.ShareForm.de
    , shareView = Messages.Comp.ShareView.de
    , title = "Dokumente publizieren"
    , infoText = "Beim Publizieren der Dokumente wird ein kryptischer Link erzeugt, mit welchem jeder die dahinter publizierten Dokumente einsehen kann. Dieser Link kann nicht erraten werden, ist aber öffentlich. Er ist zeitlich begrenzt und kann zusätzlich mit einem Passwort geschützt werden."
    , formatDateLong = Messages.DateFormat.formatDateLong Messages.UiLanguage.German
    , formatDateShort = Messages.DateFormat.formatDateShort Messages.UiLanguage.German
    , submitPublish = "Publizieren"
    , submitPublishTitle = "Dokumente jetzt publizieren"
    , cancelPublish = "Abbrechen"
    , cancelPublishTitle = "Zurück zur Auswahl"
    , publishSuccessful = "Die Dokumente wurden erfolgreich publiziert."
    , publishInProcess = "Dokumente werden publiziert…"
    , correctFormErrors = "Bitte korrigiere die Fehler im Formular."
    , doneLabel = "Fertig"
    }