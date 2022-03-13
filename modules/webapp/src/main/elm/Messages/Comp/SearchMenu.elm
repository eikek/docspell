{-
   Copyright 2020 Eike K. & Contributors

   SPDX-License-Identifier: AGPL-3.0-or-later
-}


module Messages.Comp.SearchMenu exposing
    ( Texts
    , de
    , fr
    , gb
    )

import Data.Direction exposing (Direction)
import Messages.Basics
import Messages.Comp.BookmarkChooser
import Messages.Comp.CustomFieldMultiInput
import Messages.Comp.FolderSelect
import Messages.Comp.TagSelect
import Messages.Data.Direction


type alias Texts =
    { basics : Messages.Basics.Texts
    , customFieldMultiInput : Messages.Comp.CustomFieldMultiInput.Texts
    , tagSelect : Messages.Comp.TagSelect.Texts
    , folderSelect : Messages.Comp.FolderSelect.Texts
    , bookmarkChooser : Messages.Comp.BookmarkChooser.Texts
    , chooseDirection : String
    , choosePerson : String
    , chooseEquipment : String
    , inbox : String
    , fulltextSearch : String
    , searchInNames : String
    , switchSearchModes : String
    , contentSearch : String
    , searchInNamesPlaceholder : String
    , fulltextSearchInfo : String
    , nameSearchInfo : String
    , tagCategoryTab : String
    , chooseOrganization : String
    , createCustomFieldTitle : String
    , from : String
    , to : String
    , dueDateTab : String
    , dueFrom : String
    , dueTo : String
    , sourceTab : String
    , searchInItemSource : String
    , direction : Direction -> String
    , trashcan : String
    , bookmarks : String
    , selection : String
    , showSelection : String
    , clearSelection : String
    }


gb : Texts
gb =
    { basics = Messages.Basics.gb
    , customFieldMultiInput = Messages.Comp.CustomFieldMultiInput.gb
    , tagSelect = Messages.Comp.TagSelect.gb
    , folderSelect = Messages.Comp.FolderSelect.gb
    , bookmarkChooser = Messages.Comp.BookmarkChooser.gb
    , chooseDirection = "Choose a direction…"
    , choosePerson = "Choose a person"
    , chooseEquipment = "Choose an equipment"
    , inbox = "Inbox"
    , fulltextSearch = "Fulltext Search"
    , searchInNames = "Search in names"
    , switchSearchModes = "Switch between text search modes"
    , contentSearch = "Content search…"
    , searchInNamesPlaceholder = "Search in various names…"
    , fulltextSearchInfo = "Fulltext search in document contents and notes."
    , nameSearchInfo = "Looks in correspondents, concerned entities, item name and notes."
    , tagCategoryTab = "Tag Categories"
    , chooseOrganization = "Choose an organization"
    , createCustomFieldTitle = "Create a new custom field"
    , from = "From"
    , to = "To"
    , dueDateTab = "Due Date"
    , dueFrom = "Due From"
    , dueTo = "Due To"
    , sourceTab = "Source"
    , searchInItemSource = "Search in item source…"
    , direction = Messages.Data.Direction.gb
    , trashcan = "Trash"
    , bookmarks = "Bookmarks"
    , selection = "Selection"
    , showSelection = "Show selection"
    , clearSelection = "Clear selection"
    }


de : Texts
de =
    { basics = Messages.Basics.de
    , customFieldMultiInput = Messages.Comp.CustomFieldMultiInput.de
    , tagSelect = Messages.Comp.TagSelect.de
    , folderSelect = Messages.Comp.FolderSelect.de
    , bookmarkChooser = Messages.Comp.BookmarkChooser.de
    , chooseDirection = "Wähle eine Richtung…"
    , choosePerson = "Wähle eine Person…"
    , chooseEquipment = "Wähle eine Ausstattung"
    , inbox = "Eingang/Neu"
    , fulltextSearch = "Volltextsuche"
    , searchInNames = "Suche im Titel"
    , switchSearchModes = "Zwischen den Such-Modi wechseln"
    , contentSearch = "Volltextsuche…"
    , searchInNamesPlaceholder = "Suche in Titeln…"
    , fulltextSearchInfo = "Volltextsuche im Inhalt und in Notizen."
    , nameSearchInfo = "Sucht in Namen von Korrespondent/Betreffend, Dokumenten und Notizen."
    , tagCategoryTab = "Tag-Kategorien"
    , chooseOrganization = "Wähle eine Organisation"
    , createCustomFieldTitle = "Neues Benutzerfeld erstellen"
    , from = "Von"
    , to = "Zu"
    , dueDateTab = "Fälligkeitsdatum"
    , dueFrom = "Fällig von"
    , dueTo = "Fällig bis"
    , sourceTab = "Quelle"
    , searchInItemSource = "Suche in Dokumentquelle…"
    , direction = Messages.Data.Direction.de
    , trashcan = "Papierkorb"
    , bookmarks = "Bookmarks"
    , selection = "Auswahl"
    , showSelection = "Auswahl anzeigen"
    , clearSelection = "Auswahl aufheben"
    }


fr : Texts
fr =
    { basics = Messages.Basics.fr
    , customFieldMultiInput = Messages.Comp.CustomFieldMultiInput.fr
    , tagSelect = Messages.Comp.TagSelect.fr
    , folderSelect = Messages.Comp.FolderSelect.fr
    , bookmarkChooser = Messages.Comp.BookmarkChooser.fr
    , chooseDirection = "Choisir un sens..."
    , choosePerson = "Choisir une personne"
    , chooseEquipment = "Choisir un équipement"
    , inbox = "Boite de réception"
    , fulltextSearch = "Recherche  dans texte entier"
    , searchInNames = "Recherche dans les noms"
    , switchSearchModes = "Changer de mode de recherche de texte"
    , contentSearch = "Recherche de contenu..."
    , searchInNamesPlaceholder = "Chercher dans différents noms..."
    , fulltextSearchInfo = "Recherche en texte entier dans le contenu et les notes"
    , nameSearchInfo = "Regarde dans les correspondants, organisations, documents et notes."
    , tagCategoryTab = "Catégorie de tag"
    , chooseOrganization = "Choisir une organisation"
    , createCustomFieldTitle = "Créer un nouveau champs personnalisé"
    , from = "De"
    , to = "À"
    , dueDateTab = "Date d'échéance"
    , dueFrom = "Dû depuis"
    , dueTo = "Dû le"
    , sourceTab = "Source"
    , searchInItemSource = "Rechercher un document par la source..."
    , direction = Messages.Data.Direction.fr
    , trashcan = "Corbeille"
    , bookmarks = "Favoris"
    , selection = "Sélection"
    , showSelection = "Afficher la sélection"
    , clearSelection = "Effacer la sélection"
    }
