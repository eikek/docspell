module Data.UiSettings exposing
    ( StoredUiSettings
    , UiSettings
    , defaults
    , merge
    , mergeDefaults
    , toStoredUiSettings
    )

{-| Settings for the web ui. All fields should be optional, since it
is loaded from local storage.

Making fields optional, allows it to evolve without breaking previous
versions. Also if a user is logged out, an empty object is send to
force default settings.

-}


type alias StoredUiSettings =
    { itemSearchPageSize : Maybe Int
    }


{-| Settings for the web ui. These fields are all mandatory, since
there is always a default value.

When loaded from local storage, all optional fields can fallback to a
default value, converting the StoredUiSettings into a UiSettings.

-}
type alias UiSettings =
    { itemSearchPageSize : Int
    }


defaults : UiSettings
defaults =
    { itemSearchPageSize = 60
    }


merge : StoredUiSettings -> UiSettings -> UiSettings
merge given fallback =
    { itemSearchPageSize =
        choose given.itemSearchPageSize fallback.itemSearchPageSize
    }


mergeDefaults : StoredUiSettings -> UiSettings
mergeDefaults given =
    merge given defaults


toStoredUiSettings : UiSettings -> StoredUiSettings
toStoredUiSettings settings =
    { itemSearchPageSize = Just settings.itemSearchPageSize
    }


choose : Maybe a -> a -> a
choose m1 m2 =
    Maybe.withDefault m2 m1
