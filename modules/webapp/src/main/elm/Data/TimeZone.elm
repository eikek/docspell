{-
   Copyright 2020 Eike K. & Contributors

   SPDX-License-Identifier: AGPL-3.0-or-later
-}


module Data.TimeZone exposing (TimeZone, get, listAll, toName, toZone, utc)

import Dict
import Time exposing (Zone)
import TimeZone as TZ


type TimeZone
    = TimeZone ( String, Zone )


get : String -> Maybe TimeZone
get name =
    case String.toLower name of
        "utc" ->
            Just utc

        _ ->
            Dict.get name TZ.zones
                |> Maybe.map (\z -> TimeZone ( name, z () ))


toName : TimeZone -> String
toName (TimeZone ( name, _ )) =
    name


toZone : TimeZone -> Zone
toZone (TimeZone ( _, zone )) =
    zone


utc : TimeZone
utc =
    TimeZone ( "UTC", Time.utc )


listAll : List String
listAll =
    "UTC" :: Dict.keys TZ.zones
