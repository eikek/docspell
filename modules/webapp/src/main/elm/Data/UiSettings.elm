module Data.UiSettings exposing
    ( Pos(..)
    , StoredUiSettings
    , UiSettings
    , defaults
    , merge
    , mergeDefaults
    , posFromString
    , posToString
    , tagColor
    , tagColorString
    , toStoredUiSettings
    )

import Api.Model.Tag exposing (Tag)
import Data.Color exposing (Color)
import Dict exposing (Dict)


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
    }


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
    , itemDetailNotesPosition = Top
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
    }


tagColor : Tag -> UiSettings -> Maybe Color
tagColor tag settings =
    let
        readColor c =
            Dict.get c settings.tagCategoryColors
    in
    Maybe.andThen readColor tag.category


tagColorString : Tag -> UiSettings -> String
tagColorString tag settings =
    tagColor tag settings
        |> Maybe.map Data.Color.toString
        |> Maybe.withDefault ""



--- Helpers


choose : Maybe a -> a -> a
choose m1 m2 =
    Maybe.withDefault m2 m1
