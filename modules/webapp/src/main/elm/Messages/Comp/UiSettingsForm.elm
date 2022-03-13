{-
   Copyright 2020 Eike K. & Contributors

   SPDX-License-Identifier: AGPL-3.0-or-later
-}


module Messages.Comp.UiSettingsForm exposing
    ( Texts
    , de
    , fr
    , gb
    )

import Data.Color exposing (Color)
import Data.Fields exposing (Field)
import Data.Pdf exposing (PdfMode)
import Messages.Basics
import Messages.Data.Color
import Messages.Data.Fields
import Messages.Data.PdfMode


type alias Texts =
    { basics : Messages.Basics.Texts
    , general : String
    , showSideMenuByDefault : String
    , uiLanguage : String
    , itemSearch : String
    , maxResultsPerPageInfo : Int -> String
    , maxResultsPerPage : String
    , showBasicSearchStatsByDefault : String
    , enablePowerSearch : String
    , itemCards : String
    , maxNoteSize : String
    , maxNoteSizeInfo : Int -> String
    , sizeOfItemPreview : String
    , cardTitlePattern : String
    , togglePatternHelpText : String
    , cardSubtitlePattern : String
    , searchMenu : String
    , searchMenuTagCount : String
    , searchMenuTagCountInfo : String
    , searchMenuCatCount : String
    , searchMenuCatCountInfo : String
    , searchMenuFolderCount : String
    , searchMenuFolderCountInfo : String
    , itemDetail : String
    , browserNativePdfView : String
    , keyboardShortcutLabel : String
    , tagCategoryColors : String
    , colorLabel : Color -> String
    , chooseTagColorLabel : String
    , tagColorDescription : String
    , fields : String
    , fieldsInfo : String
    , fieldLabel : Field -> String
    , templateHelpMessage : String
    , pdfMode : PdfMode -> String
    , resetLabel : String
    }


gb : Texts
gb =
    { basics = Messages.Basics.gb
    , general = "General"
    , showSideMenuByDefault = "Show side menu by default"
    , uiLanguage = "UI Language"
    , itemSearch = "Item Search"
    , maxResultsPerPageInfo =
        \max ->
            "Maximum results in one page when searching items. At most "
                ++ String.fromInt max
                ++ "."
    , maxResultsPerPage = "Page size"
    , showBasicSearchStatsByDefault = "Show basic search statistics by default"
    , enablePowerSearch = "Enable power-user search bar"
    , itemCards = "Item Cards"
    , maxNoteSize = "Max. Note Length"
    , maxNoteSizeInfo =
        \max ->
            "Maximum size of the item notes to display in card view. Between 0 - "
                ++ String.fromInt max
                ++ "."
    , sizeOfItemPreview = "Size of item preview"
    , cardTitlePattern = "Card Title Pattern"
    , togglePatternHelpText = "Toggle pattern help text"
    , cardSubtitlePattern = "Card Subtitle Pattern"
    , searchMenu = "Search Menu"
    , searchMenuTagCount = "Number of tags in search menu"
    , searchMenuTagCountInfo = "How many tags to display in search menu at once. Others can be expanded. Use 0 to always show all."
    , searchMenuCatCount = "Number of categories in search menu"
    , searchMenuCatCountInfo = "How many categories to display in search menu at once. Others can be expanded. Use 0 to always show all."
    , searchMenuFolderCount = "Number of folders in search menu"
    , searchMenuFolderCountInfo = "How many folders to display in search menu at once. Other folders can be expanded. Use 0 to always show all."
    , itemDetail = "Item Detail"
    , browserNativePdfView = "Browser-native PDF preview"
    , keyboardShortcutLabel = "Use keyboard shortcuts for navigation and confirm/unconfirm with open edit menu."
    , tagCategoryColors = "Tag Category Colors"
    , colorLabel = Messages.Data.Color.gb
    , chooseTagColorLabel = "Choose color for tag categories"
    , tagColorDescription = "Tags can be represented differently based on their category."
    , fields = "Fields"
    , fieldsInfo = "Choose which fields to display in search and edit menus."
    , fieldLabel = Messages.Data.Fields.gb
    , templateHelpMessage =
        """
A pattern allows to customize the title and subtitle of each card.
Variables expressions are enclosed in `{{` and `}}`, other text is
used as-is. The following variables are available:

- `{{name}}` the item name
- `{{source}}` the source the item was created from
- `{{folder}}` the items folder
- `{{corrOrg}}` the correspondent organization
- `{{corrPerson}}` the correspondent person
- `{{correspondent}}` both organization and person separated by a comma
- `{{concPerson}}` the concerning person
- `{{concEquip}}` the concerning equipment
- `{{concerning}}` both person and equipment separated by a comma
- `{{fileCount}}` the number of attachments of this item
- `{{dateLong}}` the item date as full formatted date
- `{{dateShort}}` the item date as short formatted date (yyyy/mm/dd)
- `{{dueDateLong}}` the item due date as full formatted date
- `{{dueDateShort}}` the item due date as short formatted date (yyyy/mm/dd)
- `{{direction}}` the items direction values as string

If some variable is not present, an empty string is rendered. You can
combine multiple variables with `|` to use the first non-empty one,
for example `{{corrOrg|corrPerson|-}}` would render the organization
and if that is not present the person. If both are absent a dash `-`
is rendered.
"""
    , pdfMode = Messages.Data.PdfMode.gb
    , resetLabel = "Reset"
    }


de : Texts
de =
    { basics = Messages.Basics.de
    , general = "Allgemein"
    , showSideMenuByDefault = "Menü an der linken Seite standardmäßig anzeigen"
    , uiLanguage = "Sprache der Oberfläche"
    , itemSearch = "Suchansicht"
    , maxResultsPerPageInfo =
        \max ->
            "Maximale Anzahl von Resultaten in einer Seite. Maximal "
                ++ String.fromInt max
                ++ "."
    , maxResultsPerPage = "Anzahl pro Seite"
    , showBasicSearchStatsByDefault = "Zeige einfache Statistiken zum Suchresultat an"
    , enablePowerSearch = "Die 'Power-Suche' aktivieren"
    , itemCards = "Kachelansicht"
    , maxNoteSize = "Max. Länge der Notizen"
    , maxNoteSizeInfo =
        \max ->
            "Maximale Länge der Notizen, die in der Kachel dargestellt werden. Zwischen 0 - "
                ++ String.fromInt max
                ++ "."
    , sizeOfItemPreview = "Größe der Vorschau (kann bei Feldern unten ganz ausgeschaltet werden)"
    , cardTitlePattern = "Titelvorlage der Kachel"
    , togglePatternHelpText = "Hilfe anzeigen/ausblenden"
    , cardSubtitlePattern = "Untertitelvorlage der Kachel"
    , searchMenu = "Suchmenü"
    , searchMenuTagCount = "Anzahl von Tags"
    , searchMenuTagCountInfo = "So viele Tags werden im Suchmenü gleichzeitig dargestellt. Weitere können ausgeklappt werden. Verwende 0, um alle anzuzeigen."
    , searchMenuCatCount = "Anzahl Tag-Kategorien"
    , searchMenuCatCountInfo = "So viele Tag-Kategorien werden gleichzeitig im Suchmenü dargestellt. Weitere können ausgeklappt werden. Verwende 0, um alle anzuzeigen."
    , searchMenuFolderCount = "Anzahl von Ordnern"
    , searchMenuFolderCountInfo = "So viele Ordner werden gleichzeitig im Suchmenü dargestellt. Weitere können ausgeklappt werden. Verwende 0, um alle anzuzeigen."
    , itemDetail = "Detailansicht"
    , browserNativePdfView = "Browsereigene PDF-Vorschau"
    , keyboardShortcutLabel = "Aktivere Tastenkürzel zur Navigation und zum Bestätigen der Metadaten"
    , tagCategoryColors = "Tag-Kategoriefarben"
    , colorLabel = Messages.Data.Color.de
    , chooseTagColorLabel = "Wähle eine Farbe für eine Tag-Kategorie"
    , tagColorDescription = "Tags können anhand ihrer Kategorie verschieden dargestellt werden."
    , fields = "Felder"
    , fieldsInfo = "Wähle welche Felder angezeigt werden sollen und welche nicht"
    , fieldLabel = Messages.Data.Fields.de
    , templateHelpMessage =
        """
Eine Vorlage erlaubt es, den Titel und Untertitel einer Kachel
individuell anzupassen. Dabei werden Variablen innerhalb `{{` und `}}`
verwendet. Anderer Text wird wörtlich dargestellt. Die folgenden
Variablen sind verfügbar:

- `{{name}}` Der Name
- `{{source}}` die Quelle durch welche das Dokument entstand
- `{{folder}}` der Ordner
- `{{corrOrg}}` die korrespondierende Organisation
- `{{corrPerson}}` die korrespondierende Person
- `{{correspondent}}` Organisation und Person, getrennt durch ein Komma
- `{{concPerson}}` die betreffende Person
- `{{concEquip}}` die betreffende Aussstattung
- `{{concerning}}` Person und Ausstattung, getrennt durch ein Komma
- `{{fileCount}}` die Anzahl von Anhängen
- `{{dateLong}}` das Datum lang formatiert
- `{{dateShort}}` das Datum kurz formatiert (yyyy/mm/dd)
- `{{dueDateLong}}` das Fälligkeitsdatum lang formatiert
- `{{dueDateShort}}` das Fälligkeitsdatum kurz formatiert (yyyy/mm/dd)
- `{{direction}}` die Richtung

Wenn eine Variable nicht vorhanden ist, wird eine leere Zeichenkette
geschrieben. Mit einem `|` können mehrere Variablen hintereinander
verknüpft werden, bis zur ersten die einen Wert enthält. Zum Beispiel:
`{{corrOrg|corrPerson|-}}` würde entweder die Organisation darstellen
oder, wenn diese leer ist, die Person. Sind beide leer wird ein `-`
dargestellt.
"""
    , pdfMode = Messages.Data.PdfMode.de
    , resetLabel = "Zurücksetzen"
    }


fr : Texts
fr =
    { basics = Messages.Basics.fr
    , general = "Général"
    , showSideMenuByDefault = "Afficher le menu latéral par défaut"
    , uiLanguage = "Langue de l'interface"
    , itemSearch = "Recherche de document"
    , maxResultsPerPageInfo =
        \max ->
            "Nombre maximum de résultats  par page. Au plus "
                ++ String.fromInt max
                ++ "."
    , maxResultsPerPage = "Résultats par page"
    , showBasicSearchStatsByDefault = "Afficher les statistiques de base par défaut"
    , enablePowerSearch = "Activer la barre de recherche avancée"
    , itemCards = "Carte des documents"
    , maxNoteSize = "Longueur max. par note"
    , maxNoteSizeInfo =
        \max ->
            "Longueur maximale de la note à afficher entre 0 - "
                ++ String.fromInt max
                ++ "."
    , sizeOfItemPreview = "Taille de l'aperçu des documents"
    , cardTitlePattern = "Gabarit du titre"
    , togglePatternHelpText = "Afficher/masquer le texte d'aide des gabarits"
    , cardSubtitlePattern = "Gabarit du sous-titre"
    , searchMenu = "Menu de recherche"
    , searchMenuTagCount = "Nombre de tag dans le menu de recherche"
    , searchMenuTagCountInfo = "Combien de tag afficher dans le menu de recherche à la fois. Les autres peuvent être déroulés. Mettre 0 pour toujours tout afficher."
    , searchMenuCatCount = "Nombre de catégorie dans le menu de recherche"
    , searchMenuCatCountInfo = "Combien de catégorie afficher dans le menu de recherche à la fois. Les autres peuvent être déroulés. Mettre 0 pour toujours tout afficher."
    , searchMenuFolderCount = "Nombre de dossier dans le menu de recherche"
    , searchMenuFolderCountInfo = "Combien de dossier afficher dans le menu de recherche à la fois. Les autres peuvent être déroulés. Mettre 0 pour toujours tout afficher."
    , itemDetail = "Détail d'un document"
    , browserNativePdfView = "Aperçu PDF natif du navigateur"
    , keyboardShortcutLabel = "Utiliser les raccourcis claviers pour la navigation/valider/invalider avec les menu d'édition ouvert."
    , tagCategoryColors = "Couleur des catégories de tag"
    , colorLabel = Messages.Data.Color.fr
    , chooseTagColorLabel = "Choisir les couleurs des catéories de tag"
    , tagColorDescription = "Les tags peuvent être affichés différement selon leur catégorie."
    , fields = "Champs"
    , fieldsInfo = "Choisir quels champs affichés dans les menus d'édition et de recherche."
    , fieldLabel = Messages.Data.Fields.fr
    , templateHelpMessage =
        """
Un gabarit permet de personnaliser les titre et sous titre de chaque carte.
Les variables sont encadrées par `{{` and `}}`, le reste du texte est utilisé
comme tel. Les variables suivantes sont disponible:

- `{{name}}` nom du document
- `{{source}}` la source d'origine du document
- `{{folder}}` le dossier du document
- `{{corrOrg}}` l'organisation correspondante
- `{{corrPerson}}` la personne correspondante
- `{{correspondent}}` les deux organisation et personne séparées par une virgule
- `{{concPerson}}` la personne concernée
- `{{concEquip}}` l'équipement concerné
- `{{concerning}}` les deux equipement et personne séparés par une virgule
- `{{fileCount}}` le nombre de fichier du document
- `{{dateLong}}` La date  complète du document
- `{{dateShort}}` la date numérique du document (jj/mm/aaaa)
- `{{dueDateLong}}` La date d'échance complète du document
- `{{dueDateShort}}` La date numérique d'échéance du document (jj/mm/aaaa)
- `{{direction}}` La direction/sens du document

Si une variable n'est pas présente, une chaine de charactère vide remplace. Il est
possible de combiner plusieurs variables avec `|`, la première non vide sera utilisée.
Par example: `{{corrOrg|corrPerson|-}}` affichera l'organisation si présente, la personne
si organisation est absente et enfin `-` si les 2 sont absentes.
"""
    , pdfMode = Messages.Data.PdfMode.fr
    , resetLabel = "Remise à zéro"
    }
