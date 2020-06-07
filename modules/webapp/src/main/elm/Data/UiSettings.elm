module Data.UiSettings exposing
    ( StoredUiSettings
    , UiSettings
    , defaults
    , merge
    , mergeDefaults
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
    }


{-| Settings for the web ui. These fields are all mandatory, since
there is always a default value.

When loaded from local storage, all optional fields can fallback to a
default value, converting the StoredUiSettings into a UiSettings.

-}
type alias UiSettings =
    { itemSearchPageSize : Int
    , tagCategoryColors : Dict String String
    }


defaults : UiSettings
defaults =
    { itemSearchPageSize = 60
    , tagCategoryColors = Dict.empty
    }


merge : StoredUiSettings -> UiSettings -> UiSettings
merge given fallback =
    { itemSearchPageSize =
        choose given.itemSearchPageSize fallback.itemSearchPageSize
    , tagCategoryColors =
        Dict.union (Dict.fromList given.tagCategoryColors)
            fallback.tagCategoryColors
    }


mergeDefaults : StoredUiSettings -> UiSettings
mergeDefaults given =
    merge given defaults


toStoredUiSettings : UiSettings -> StoredUiSettings
toStoredUiSettings settings =
    { itemSearchPageSize = Just settings.itemSearchPageSize
    , tagCategoryColors = Dict.toList settings.tagCategoryColors
    }


tagColor : Tag -> UiSettings -> Maybe Color
tagColor tag settings =
    let
        readColor c =
            Dict.get c settings.tagCategoryColors
                |> Maybe.andThen Data.Color.fromString
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
