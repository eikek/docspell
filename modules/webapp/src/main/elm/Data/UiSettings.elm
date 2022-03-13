{-
   Copyright 2020 Eike K. & Contributors

   SPDX-License-Identifier: AGPL-3.0-or-later
-}


module Data.UiSettings exposing
    ( ItemPattern
    , StoredUiSettings
    , UiSettings
    , cardPreviewSize
    , cardPreviewSize2
    , catColor
    , catColorFg2
    , catColorString2
    , convert
    , defaults
    , documentationSite
    , emptyStoredSettings
    , fieldHidden
    , fieldVisible
    , getUiLanguage
    , merge
    , mergeDefaults
    , pdfUrl
    , pdfView
    , storedUiSettingsDecoder
    , storedUiSettingsEncode
    , tagColor
    , tagColorFg2
    , tagColorString2
    )

import Api.Model.Tag exposing (Tag)
import Data.BasicSize exposing (BasicSize)
import Data.Color exposing (Color)
import Data.Fields exposing (Field)
import Data.Flags exposing (Flags)
import Data.ItemArrange exposing (ItemArrange)
import Data.ItemTemplate exposing (ItemTemplate)
import Data.Pdf exposing (PdfMode)
import Data.TimeZone exposing (TimeZone)
import Data.UiTheme exposing (UiTheme)
import Dict exposing (Dict)
import Html exposing (Attribute, Html, embed, iframe)
import Html.Attributes as HA exposing (src)
import Json.Decode as Decode
import Json.Decode.Pipeline as P
import Json.Encode as Encode
import Messages
import Messages.UiLanguage exposing (UiLanguage)


{-| Settings for the web ui. All fields should be optional, since it
is loaded from the server and mus be backward compatible.

Making fields optional, allows it to evolve without breaking previous
versions. Also if a user is logged out, an empty object is send to
force default settings.

-}
type alias StoredUiSettings =
    { itemSearchPageSize : Maybe Int
    , tagCategoryColors : Maybe (List ( String, String ))
    , pdfMode : Maybe String
    , itemSearchNoteLength : Maybe Int
    , searchMenuFolderCount : Maybe Int
    , searchMenuTagCount : Maybe Int
    , searchMenuTagCatCount : Maybe Int
    , formFields : Maybe (List String)
    , itemDetailShortcuts : Maybe Bool
    , cardPreviewSize : Maybe String
    , cardTitleTemplate : Maybe String
    , cardSubtitleTemplate : Maybe String
    , searchStatsVisible : Maybe Bool
    , cardPreviewFullWidth : Maybe Bool
    , uiTheme : Maybe String
    , sideMenuVisible : Maybe Bool
    , powerSearchEnabled : Maybe Bool
    , uiLang : Maybe String
    , itemSearchShowGroups : Maybe Bool
    , itemSearchArrange : Maybe String
    , timeZone : Maybe String
    }


emptyStoredSettings : StoredUiSettings
emptyStoredSettings =
    { itemSearchPageSize = Nothing
    , tagCategoryColors = Nothing
    , pdfMode = Nothing
    , itemSearchNoteLength = Nothing
    , searchMenuFolderCount = Nothing
    , searchMenuTagCount = Nothing
    , searchMenuTagCatCount = Nothing
    , formFields = Nothing
    , itemDetailShortcuts = Nothing
    , cardPreviewSize = Nothing
    , cardTitleTemplate = Nothing
    , cardSubtitleTemplate = Nothing
    , searchStatsVisible = Nothing
    , cardPreviewFullWidth = Nothing
    , uiTheme = Nothing
    , sideMenuVisible = Nothing
    , powerSearchEnabled = Nothing
    , uiLang = Nothing
    , itemSearchShowGroups = Nothing
    , itemSearchArrange = Nothing
    , timeZone = Nothing
    }


storedUiSettingsDecoder : Decode.Decoder StoredUiSettings
storedUiSettingsDecoder =
    let
        maybeInt =
            Decode.maybe Decode.int

        maybeString =
            Decode.maybe Decode.string

        maybeBool =
            Decode.maybe Decode.bool
    in
    Decode.succeed StoredUiSettings
        |> P.optional "itemSearchPageSize" maybeInt Nothing
        |> P.optional "tagCategoryColors" (Decode.maybe <| Decode.keyValuePairs Decode.string) Nothing
        |> P.optional "pdfMode" maybeString Nothing
        |> P.optional "itemSearchNoteLength" maybeInt Nothing
        |> P.optional "searchMenuFolderCount" maybeInt Nothing
        |> P.optional "searchMenuTagCount" maybeInt Nothing
        |> P.optional "searchMenuTagCatCount" maybeInt Nothing
        |> P.optional "formFields" (Decode.maybe <| Decode.list Decode.string) Nothing
        |> P.optional "itemDetailShortcuts" maybeBool Nothing
        |> P.optional "cardPreviewSize" maybeString Nothing
        |> P.optional "cardTitleTemplate" maybeString Nothing
        |> P.optional "cardSubtitleTemplate" maybeString Nothing
        |> P.optional "searchStatsVisible" maybeBool Nothing
        |> P.optional "cardPreviewFullWidth" maybeBool Nothing
        |> P.optional "uiTheme" maybeString Nothing
        |> P.optional "sideMenuVisible" maybeBool Nothing
        |> P.optional "powerSearchEnabled" maybeBool Nothing
        |> P.optional "uiLang" maybeString Nothing
        |> P.optional "itemSearchShowGroups" maybeBool Nothing
        |> P.optional "itemSearchArrange" maybeString Nothing
        |> P.optional "timeZone" maybeString Nothing


storedUiSettingsEncode : StoredUiSettings -> Encode.Value
storedUiSettingsEncode value =
    let
        maybeEnc field enca ma =
            Maybe.map (\a -> ( field, enca a )) ma
    in
    Encode.object <|
        List.filterMap identity
            [ maybeEnc "itemSearchPageSize" Encode.int value.itemSearchPageSize
            , maybeEnc "tagCategoryColors"
                (Encode.dict identity Encode.string)
                (Maybe.map Dict.fromList value.tagCategoryColors)
            , maybeEnc "pdfMode" Encode.string value.pdfMode
            , maybeEnc "itemSearchNoteLength" Encode.int value.itemSearchNoteLength
            , maybeEnc "searchMenuFolderCount" Encode.int value.searchMenuFolderCount
            , maybeEnc "searchMenuTagCount" Encode.int value.searchMenuTagCount
            , maybeEnc "searchMenuTagCatCount" Encode.int value.searchMenuTagCatCount
            , maybeEnc "formFields" (Encode.list Encode.string) value.formFields
            , maybeEnc "itemDetailShortcuts" Encode.bool value.itemDetailShortcuts
            , maybeEnc "cardPreviewSize" Encode.string value.cardPreviewSize
            , maybeEnc "cardTitleTemplate" Encode.string value.cardTitleTemplate
            , maybeEnc "cardSubtitleTemplate" Encode.string value.cardSubtitleTemplate
            , maybeEnc "searchStatsVisible" Encode.bool value.searchStatsVisible
            , maybeEnc "cardPreviewFullWidth" Encode.bool value.cardPreviewFullWidth
            , maybeEnc "uiTheme" Encode.string value.uiTheme
            , maybeEnc "sideMenuVisible" Encode.bool value.sideMenuVisible
            , maybeEnc "powerSearchEnabled" Encode.bool value.powerSearchEnabled
            , maybeEnc "uiLang" Encode.string value.uiLang
            , maybeEnc "itemSearchShowGroups" Encode.bool value.itemSearchShowGroups
            , maybeEnc "itemSearchArrange" Encode.string value.itemSearchArrange
            , maybeEnc "timeZone" Encode.string value.timeZone
            ]


{-| Settings for the web ui. These fields are all mandatory, since
there is always a default value.

When loaded from local storage or the server, all optional fields can
fallback to a default value, converting the StoredUiSettings into a
UiSettings.

-}
type alias UiSettings =
    { itemSearchPageSize : Int
    , tagCategoryColors : Dict String Color
    , pdfMode : PdfMode
    , itemSearchNoteLength : Int
    , searchMenuFolderCount : Int
    , searchMenuTagCount : Int
    , searchMenuTagCatCount : Int
    , formFields : List Field
    , itemDetailShortcuts : Bool
    , cardPreviewSize : BasicSize
    , cardTitleTemplate : ItemPattern
    , cardSubtitleTemplate : ItemPattern
    , searchStatsVisible : Bool
    , cardPreviewFullWidth : Bool
    , uiTheme : UiTheme
    , sideMenuVisible : Bool
    , powerSearchEnabled : Bool
    , uiLang : UiLanguage
    , itemSearchShowGroups : Bool
    , itemSearchArrange : ItemArrange
    , timeZone : TimeZone
    }


type alias ItemPattern =
    { pattern : String
    , template : ItemTemplate
    }


readPattern : String -> Maybe ItemPattern
readPattern str =
    Data.ItemTemplate.readTemplate str
        |> Maybe.map (ItemPattern str)


defaults : UiSettings
defaults =
    { itemSearchPageSize = 60
    , tagCategoryColors = Dict.empty
    , pdfMode = Data.Pdf.Detect
    , itemSearchNoteLength = 0
    , searchMenuFolderCount = 3
    , searchMenuTagCount = 6
    , searchMenuTagCatCount = 3
    , formFields = Data.Fields.all
    , itemDetailShortcuts = False
    , cardPreviewSize = Data.BasicSize.Medium
    , cardTitleTemplate =
        { template = Data.ItemTemplate.name
        , pattern = "{{name}}"
        }
    , cardSubtitleTemplate =
        { template = Data.ItemTemplate.dateLong
        , pattern = "{{dateLong}}"
        }
    , searchStatsVisible = True
    , cardPreviewFullWidth = False
    , uiTheme = Data.UiTheme.Light
    , sideMenuVisible = True
    , powerSearchEnabled = False
    , uiLang = Messages.UiLanguage.English
    , itemSearchShowGroups = True
    , itemSearchArrange = Data.ItemArrange.Cards
    , timeZone = Data.TimeZone.utc
    }


merge : StoredUiSettings -> UiSettings -> UiSettings
merge given fallback =
    { itemSearchPageSize =
        choose given.itemSearchPageSize fallback.itemSearchPageSize
    , tagCategoryColors =
        Dict.union
            (Maybe.map Dict.fromList given.tagCategoryColors
                |> Maybe.withDefault Dict.empty
                |> Dict.map (\_ -> Data.Color.fromString)
                |> Dict.filter (\_ -> \mc -> mc /= Nothing)
                |> Dict.map (\_ -> Maybe.withDefault Data.Color.Grey)
            )
            fallback.tagCategoryColors
    , pdfMode =
        given.pdfMode
            |> Maybe.andThen Data.Pdf.fromString
            |> Maybe.withDefault fallback.pdfMode
    , itemSearchNoteLength =
        choose given.itemSearchNoteLength fallback.itemSearchNoteLength
    , searchMenuFolderCount =
        choose given.searchMenuFolderCount
            fallback.searchMenuFolderCount
    , searchMenuTagCount =
        choose given.searchMenuTagCount fallback.searchMenuTagCount
    , searchMenuTagCatCount =
        choose given.searchMenuTagCatCount fallback.searchMenuTagCatCount
    , formFields =
        choose
            (Maybe.map Data.Fields.fromList given.formFields)
            fallback.formFields
    , itemDetailShortcuts = choose given.itemDetailShortcuts fallback.itemDetailShortcuts
    , cardPreviewSize =
        given.cardPreviewSize
            |> Maybe.andThen Data.BasicSize.fromString
            |> Maybe.withDefault fallback.cardPreviewSize
    , cardTitleTemplate =
        Maybe.andThen readPattern given.cardTitleTemplate
            |> Maybe.withDefault fallback.cardTitleTemplate
    , cardSubtitleTemplate =
        Maybe.andThen readPattern given.cardSubtitleTemplate
            |> Maybe.withDefault fallback.cardSubtitleTemplate
    , searchStatsVisible = choose given.searchStatsVisible fallback.searchStatsVisible
    , cardPreviewFullWidth = choose given.cardPreviewFullWidth fallback.cardPreviewFullWidth
    , uiTheme =
        Maybe.andThen Data.UiTheme.fromString given.uiTheme
            |> Maybe.withDefault fallback.uiTheme
    , sideMenuVisible = choose given.sideMenuVisible fallback.sideMenuVisible
    , powerSearchEnabled = choose given.powerSearchEnabled fallback.powerSearchEnabled
    , uiLang =
        Maybe.map Messages.fromIso2 given.uiLang
            |> Maybe.withDefault fallback.uiLang
    , itemSearchShowGroups = choose given.itemSearchShowGroups fallback.itemSearchShowGroups
    , itemSearchArrange =
        Maybe.andThen Data.ItemArrange.fromString given.itemSearchArrange
            |> Maybe.withDefault fallback.itemSearchArrange
    , timeZone =
        Maybe.andThen Data.TimeZone.get given.timeZone
            |> Maybe.withDefault fallback.timeZone
    }


mergeDefaults : StoredUiSettings -> UiSettings
mergeDefaults given =
    merge given defaults


convert : UiSettings -> StoredUiSettings
convert settings =
    { itemSearchPageSize = Just settings.itemSearchPageSize
    , tagCategoryColors =
        Dict.map (\_ -> Data.Color.toString) settings.tagCategoryColors
            |> Dict.toList
            |> Just
    , pdfMode = Just (Data.Pdf.asString settings.pdfMode)
    , itemSearchNoteLength = Just settings.itemSearchNoteLength
    , searchMenuFolderCount = Just settings.searchMenuFolderCount
    , searchMenuTagCount = Just settings.searchMenuTagCount
    , searchMenuTagCatCount = Just settings.searchMenuTagCatCount
    , formFields =
        List.map Data.Fields.toString settings.formFields
            |> Just
    , itemDetailShortcuts = Just settings.itemDetailShortcuts
    , cardPreviewSize =
        settings.cardPreviewSize
            |> Data.BasicSize.asString
            |> Just
    , cardTitleTemplate = settings.cardTitleTemplate.pattern |> Just
    , cardSubtitleTemplate = settings.cardSubtitleTemplate.pattern |> Just
    , searchStatsVisible = Just settings.searchStatsVisible
    , cardPreviewFullWidth = Just settings.cardPreviewFullWidth
    , uiTheme = Just (Data.UiTheme.toString settings.uiTheme)
    , sideMenuVisible = Just settings.sideMenuVisible
    , powerSearchEnabled = Just settings.powerSearchEnabled
    , uiLang = Just <| Messages.toIso2 settings.uiLang
    , itemSearchShowGroups = Just settings.itemSearchShowGroups
    , itemSearchArrange = Data.ItemArrange.asString settings.itemSearchArrange |> Just
    , timeZone = Data.TimeZone.toName settings.timeZone |> Just
    }


catColor : UiSettings -> String -> Maybe Color
catColor settings c =
    Dict.get c settings.tagCategoryColors


tagColor : Tag -> UiSettings -> Maybe Color
tagColor tag settings =
    Maybe.andThen (catColor settings) tag.category


catColorString2 : UiSettings -> String -> String
catColorString2 settings name =
    catColor settings name
        |> Maybe.map Data.Color.toString2
        |> Maybe.withDefault ""


catColorFg2 : UiSettings -> String -> String
catColorFg2 settings name =
    catColor settings name
        |> Maybe.map Data.Color.toStringFg2
        |> Maybe.withDefault ""


tagColorString2 : Tag -> UiSettings -> String
tagColorString2 tag settings =
    tagColor tag settings
        |> Maybe.map Data.Color.toString2
        |> Maybe.withDefault "border-black dark:border-slate-200"


tagColorFg2 : Tag -> UiSettings -> String
tagColorFg2 tag settings =
    tagColor tag settings
        |> Maybe.map Data.Color.toStringFg2
        |> Maybe.withDefault ""


fieldVisible : UiSettings -> Field -> Bool
fieldVisible settings field =
    List.member field settings.formFields


fieldHidden : UiSettings -> Field -> Bool
fieldHidden settings field =
    fieldVisible settings field |> not


cardPreviewSize : UiSettings -> Attribute msg
cardPreviewSize settings =
    Data.BasicSize.asString settings.cardPreviewSize
        |> HA.class


cardPreviewSize2 : UiSettings -> String
cardPreviewSize2 settings =
    case settings.cardPreviewSize of
        Data.BasicSize.Small ->
            "max-h-16"

        Data.BasicSize.Medium ->
            "max-h-52"

        Data.BasicSize.Large ->
            "max-h-80"


pdfUrl : UiSettings -> Flags -> String -> String
pdfUrl settings flags originalUrl =
    case settings.pdfMode of
        Data.Pdf.Detect ->
            Data.Pdf.detectUrl flags originalUrl

        Data.Pdf.Native ->
            originalUrl

        Data.Pdf.Server ->
            Data.Pdf.serverUrl originalUrl


pdfView : UiSettings -> Flags -> String -> List (Attribute msg) -> Html msg
pdfView settings flags originalUrl attrs =
    let
        url =
            pdfUrl settings flags originalUrl

        native =
            embed (src url :: attrs) []

        fallback =
            iframe (src url :: attrs) []
    in
    case settings.pdfMode of
        Data.Pdf.Detect ->
            if flags.pdfSupported then
                native

            else
                fallback

        Data.Pdf.Native ->
            native

        Data.Pdf.Server ->
            fallback


getUiLanguage : Flags -> UiSettings -> UiLanguage -> UiLanguage
getUiLanguage flags settings default =
    case flags.account of
        Just _ ->
            settings.uiLang

        Nothing ->
            default


documentationSite : String
documentationSite =
    "https://docspell.org/docs"



--- Helpers


choose : Maybe a -> a -> a
choose m1 m2 =
    Maybe.withDefault m2 m1
