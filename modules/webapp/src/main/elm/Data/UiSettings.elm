module Data.UiSettings exposing
    ( ItemPattern
    , Pos(..)
    , StoredUiSettings
    , UiSettings
    , cardPreviewSize
    , catColor
    , catColorString
    , defaults
    , fieldHidden
    , fieldVisible
    , merge
    , mergeDefaults
    , posFromString
    , posToString
    , tagColor
    , tagColorString
    , toStoredUiSettings
    )

import Api.Model.Tag exposing (Tag)
import Data.BasicSize exposing (BasicSize)
import Data.Color exposing (Color)
import Data.Fields exposing (Field)
import Data.ItemTemplate exposing (ItemTemplate)
import Dict exposing (Dict)
import Html exposing (Attribute)
import Html.Attributes as HA


{-| Settings for the web ui. All fields should be optional, since it
is loaded from local storage.

Making fields optional, allows it to evolve without breaking previous
versions. Also if a user is logged out, an empty object is send to
force default settings.

-}
type alias StoredUiSettings =
    { itemSearchPageSize : Maybe Int
    , tagCategoryColors : List ( String, String )
    , nativePdfPreview : Bool
    , itemSearchNoteLength : Maybe Int
    , itemDetailNotesPosition : Maybe String
    , searchMenuFolderCount : Maybe Int
    , searchMenuTagCount : Maybe Int
    , searchMenuTagCatCount : Maybe Int
    , formFields : Maybe (List String)
    , itemDetailShortcuts : Bool
    , searchMenuVisible : Bool
    , editMenuVisible : Bool
    , cardPreviewSize : Maybe String
    , cardTitleTemplate : Maybe String
    , cardSubtitleTemplate : Maybe String
    }


{-| Settings for the web ui. These fields are all mandatory, since
there is always a default value.

When loaded from local storage, all optional fields can fallback to a
default value, converting the StoredUiSettings into a UiSettings.

-}
type alias UiSettings =
    { itemSearchPageSize : Int
    , tagCategoryColors : Dict String Color
    , nativePdfPreview : Bool
    , itemSearchNoteLength : Int
    , itemDetailNotesPosition : Pos
    , searchMenuFolderCount : Int
    , searchMenuTagCount : Int
    , searchMenuTagCatCount : Int
    , formFields : List Field
    , itemDetailShortcuts : Bool
    , searchMenuVisible : Bool
    , editMenuVisible : Bool
    , cardPreviewSize : BasicSize
    , cardTitleTemplate : ItemPattern
    , cardSubtitleTemplate : ItemPattern
    }


type alias ItemPattern =
    { pattern : String
    , template : ItemTemplate
    }


readPattern : String -> Maybe ItemPattern
readPattern str =
    Data.ItemTemplate.readTemplate str
        |> Maybe.map (ItemPattern str)


type Pos
    = Top
    | Bottom


posToString : Pos -> String
posToString pos =
    case pos of
        Top ->
            "top"

        Bottom ->
            "bottom"


posFromString : String -> Maybe Pos
posFromString str =
    case str of
        "top" ->
            Just Top

        "bottom" ->
            Just Bottom

        _ ->
            Nothing


defaults : UiSettings
defaults =
    { itemSearchPageSize = 60
    , tagCategoryColors = Dict.empty
    , nativePdfPreview = False
    , itemSearchNoteLength = 0
    , itemDetailNotesPosition = Bottom
    , searchMenuFolderCount = 3
    , searchMenuTagCount = 6
    , searchMenuTagCatCount = 3
    , formFields = Data.Fields.all
    , itemDetailShortcuts = False
    , searchMenuVisible = False
    , editMenuVisible = False
    , cardPreviewSize = Data.BasicSize.Medium
    , cardTitleTemplate =
        { template = Data.ItemTemplate.name
        , pattern = "{{name}}"
        }
    , cardSubtitleTemplate =
        { template = Data.ItemTemplate.dateLong
        , pattern = "{{dateLong}}"
        }
    }


merge : StoredUiSettings -> UiSettings -> UiSettings
merge given fallback =
    { itemSearchPageSize =
        choose given.itemSearchPageSize fallback.itemSearchPageSize
    , tagCategoryColors =
        Dict.union
            (Dict.fromList given.tagCategoryColors
                |> Dict.map (\_ -> Data.Color.fromString)
                |> Dict.filter (\_ -> \mc -> mc /= Nothing)
                |> Dict.map (\_ -> Maybe.withDefault Data.Color.Grey)
            )
            fallback.tagCategoryColors
    , nativePdfPreview = given.nativePdfPreview
    , itemSearchNoteLength =
        choose given.itemSearchNoteLength fallback.itemSearchNoteLength
    , itemDetailNotesPosition =
        choose (Maybe.andThen posFromString given.itemDetailNotesPosition)
            fallback.itemDetailNotesPosition
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
    , itemDetailShortcuts = given.itemDetailShortcuts
    , searchMenuVisible = given.searchMenuVisible
    , editMenuVisible = given.editMenuVisible
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
    }


mergeDefaults : StoredUiSettings -> UiSettings
mergeDefaults given =
    merge given defaults


toStoredUiSettings : UiSettings -> StoredUiSettings
toStoredUiSettings settings =
    { itemSearchPageSize = Just settings.itemSearchPageSize
    , tagCategoryColors =
        Dict.map (\_ -> Data.Color.toString) settings.tagCategoryColors
            |> Dict.toList
    , nativePdfPreview = settings.nativePdfPreview
    , itemSearchNoteLength = Just settings.itemSearchNoteLength
    , itemDetailNotesPosition = Just (posToString settings.itemDetailNotesPosition)
    , searchMenuFolderCount = Just settings.searchMenuFolderCount
    , searchMenuTagCount = Just settings.searchMenuTagCount
    , searchMenuTagCatCount = Just settings.searchMenuTagCatCount
    , formFields =
        List.map Data.Fields.toString settings.formFields
            |> Just
    , itemDetailShortcuts = settings.itemDetailShortcuts
    , searchMenuVisible = settings.searchMenuVisible
    , editMenuVisible = settings.editMenuVisible
    , cardPreviewSize =
        settings.cardPreviewSize
            |> Data.BasicSize.asString
            |> Just
    , cardTitleTemplate = settings.cardTitleTemplate.pattern |> Just
    , cardSubtitleTemplate = settings.cardSubtitleTemplate.pattern |> Just
    }


catColor : UiSettings -> String -> Maybe Color
catColor settings c =
    Dict.get c settings.tagCategoryColors


tagColor : Tag -> UiSettings -> Maybe Color
tagColor tag settings =
    Maybe.andThen (catColor settings) tag.category


catColorString : UiSettings -> String -> String
catColorString settings name =
    catColor settings name
        |> Maybe.map Data.Color.toString
        |> Maybe.withDefault ""


tagColorString : Tag -> UiSettings -> String
tagColorString tag settings =
    tagColor tag settings
        |> Maybe.map Data.Color.toString
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



--- Helpers


choose : Maybe a -> a -> a
choose m1 m2 =
    Maybe.withDefault m2 m1
