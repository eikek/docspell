{-
   Copyright 2020 Eike K. & Contributors

   SPDX-License-Identifier: AGPL-3.0-or-later
-}


module Messages.Comp.PublishItems exposing
    ( Texts
    , de
    , gb
    , fr
    )

import Data.TimeZone exposing (TimeZone)
import Http
import Messages.Basics
import Messages.Comp.HttpError
import Messages.Comp.ShareForm
import Messages.Comp.ShareMail
import Messages.Comp.ShareView
import Messages.DateFormat
import Messages.UiLanguage


type alias Texts =
    { basics : Messages.Basics.Texts
    , httpError : Http.Error -> String
    , shareForm : Messages.Comp.ShareForm.Texts
    , shareView : Messages.Comp.ShareView.Texts
    , shareMail : Messages.Comp.ShareMail.Texts
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
    , sendViaMail : String
    }


gb : TimeZone -> Texts
gb tz =
    { basics = Messages.Basics.gb
    , httpError = Messages.Comp.HttpError.gb
    , shareForm = Messages.Comp.ShareForm.gb
    , shareView = Messages.Comp.ShareView.gb tz
    , shareMail = Messages.Comp.ShareMail.gb
    , title = "Publish Items"
    , infoText = "Publishing items creates a cryptic link, which can be used by everyone to see the selected documents. This link cannot be guessed, but is public! It exists for a certain amount of time and can be further protected using a password."
    , formatDateLong = Messages.DateFormat.formatDateLong Messages.UiLanguage.English tz
    , formatDateShort = Messages.DateFormat.formatDateShort Messages.UiLanguage.English tz
    , submitPublish = "Publish"
    , submitPublishTitle = "Publish the documents now"
    , cancelPublish = "Cancel"
    , cancelPublishTitle = "Back to select view"
    , publishSuccessful = "Items published successfully"
    , publishInProcess = "Items are published …"
    , correctFormErrors = "Please correct the errors in the form."
    , doneLabel = "Done"
    , sendViaMail = "Send via E-Mail"
    }


de : TimeZone -> Texts
de tz =
    { basics = Messages.Basics.de
    , httpError = Messages.Comp.HttpError.de
    , shareForm = Messages.Comp.ShareForm.de
    , shareView = Messages.Comp.ShareView.de tz
    , shareMail = Messages.Comp.ShareMail.de
    , title = "Dokumente publizieren"
    , infoText = "Beim Publizieren der Dokumente wird ein kryptischer Link erzeugt, mit welchem jeder die dahinter publizierten Dokumente einsehen kann. Dieser Link kann nicht erraten werden, ist aber öffentlich. Er ist zeitlich begrenzt und kann zusätzlich mit einem Passwort geschützt werden."
    , formatDateLong = Messages.DateFormat.formatDateLong Messages.UiLanguage.German tz
    , formatDateShort = Messages.DateFormat.formatDateShort Messages.UiLanguage.German tz
    , submitPublish = "Publizieren"
    , submitPublishTitle = "Dokumente jetzt publizieren"
    , cancelPublish = "Abbrechen"
    , cancelPublishTitle = "Zurück zur Auswahl"
    , publishSuccessful = "Die Dokumente wurden erfolgreich publiziert."
    , publishInProcess = "Dokumente werden publiziert…"
    , correctFormErrors = "Bitte korrigiere die Fehler im Formular."
    , doneLabel = "Fertig"
    , sendViaMail = "Per E-Mail versenden"
    }

fr : TimeZone -> Texts
fr tz =
    { basics = Messages.Basics.fr
    , httpError = Messages.Comp.HttpError.fr
    , shareForm = Messages.Comp.ShareForm.fr
    , shareView = Messages.Comp.ShareView.fr tz
    , shareMail = Messages.Comp.ShareMail.fr
    , title = "Publier les documents"
    , infoText = "La publication de documents crée un lien aléatoire, qui peut être utilisé par n'importe qui pour voir les documents. Ce lien ne peut  être deviné mais est public ! Il existe pour un certain temps et peut en plus être protégé par un mot de passe"
    , formatDateLong = Messages.DateFormat.formatDateLong Messages.UiLanguage.French tz
    , formatDateShort = Messages.DateFormat.formatDateShort Messages.UiLanguage.French tz
    , submitPublish = "Publier"
    , submitPublishTitle = "Publier les documents"
    , cancelPublish = "Annuler"
    , cancelPublishTitle = "Annuler la publication"
    , publishSuccessful = "Documents publiés avec succès"
    , publishInProcess = "Documents en cous de publication ..."
    , correctFormErrors = "Veuillez corriger les erreurs du formulaire"
    , doneLabel = "Terminé"
    , sendViaMail = "Envoyer par mail"
    }
