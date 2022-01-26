{-
   Copyright 2020 Eike K. & Contributors

   SPDX-License-Identifier: AGPL-3.0-or-later
-}


module Data.Dashboards exposing
    ( AllDashboards
    , Dashboards
    , countAll
    , decoder
    , empty
    , emptyAll
    , encode
    , exists
    , existsAll
    , find
    , findInAll
    , foldl
    , getAllDefault
    , getDefault
    , getScope
    , insert
    , insertIn
    , isDefaultAll
    , isEmpty
    , isEmptyAll
    , map
    , remove
    , removeFromAll
    , selectBoards
    , setDefaultAll
    , singleton
    , singletonAll
    , unsetDefaultAll
    )

import Data.AccountScope exposing (AccountScope)
import Data.Dashboard exposing (Dashboard)
import Dict exposing (Dict)
import Json.Decode as D
import Json.Encode as E
import Util.Maybe


type Dashboards
    = Dashboards Info


empty : Dashboards
empty =
    Dashboards { default = "", boards = Dict.empty }


isEmpty : Dashboards -> Bool
isEmpty (Dashboards info) =
    Dict.isEmpty info.boards


insert : Dashboard -> Dashboards -> Dashboards
insert board (Dashboards info) =
    let
        nb =
            Dict.insert (String.toLower board.name) board info.boards
    in
    Dashboards { info | boards = nb }


singleton : Dashboard -> Dashboards
singleton board =
    insert board empty


remove : String -> Dashboards -> Dashboards
remove name (Dashboards info) =
    let
        nb =
            Dict.remove (String.toLower name) info.boards
    in
    Dashboards { info | boards = nb }


map : (Dashboard -> a) -> Dashboards -> List a
map f (Dashboards info) =
    List.map f (Dict.values info.boards)


find : String -> Dashboards -> Maybe Dashboard
find name (Dashboards info) =
    Dict.get (String.toLower name) info.boards


foldl : (Dashboard -> a -> a) -> a -> Dashboards -> a
foldl f init (Dashboards info) =
    List.foldl f init (Dict.values info.boards)


exists : String -> Dashboards -> Bool
exists name (Dashboards info) =
    Dict.member (String.toLower name) info.boards


getDefault : Dashboards -> Maybe Dashboard
getDefault (Dashboards info) =
    Dict.get (String.toLower info.default) info.boards


isDefault : String -> Dashboards -> Bool
isDefault name (Dashboards info) =
    String.toLower name == String.toLower info.default


setDefault : String -> Dashboards -> Dashboards
setDefault name (Dashboards info) =
    Dashboards { info | default = String.toLower name }


unsetDefault : String -> Dashboards -> Dashboards
unsetDefault name dbs =
    if isDefault name dbs then
        setDefault "" dbs

    else
        dbs


getFirst : Dashboards -> Maybe Dashboard
getFirst (Dashboards info) =
    List.head (Dict.values info.boards)



--- AllDashboards


type alias AllDashboards =
    { collective : Dashboards
    , user : Dashboards
    }


emptyAll : AllDashboards
emptyAll =
    AllDashboards empty empty


isEmptyAll : AllDashboards -> Bool
isEmptyAll all =
    isEmpty all.collective && isEmpty all.user


insertIn : AccountScope -> Dashboard -> AllDashboards -> AllDashboards
insertIn scope board all =
    Data.AccountScope.fold
        { user = insert board all.user
        , collective = all.collective
        }
        { user = all.user
        , collective = insert board all.collective
        }
        scope


selectBoards : AccountScope -> AllDashboards -> Dashboards
selectBoards scope all =
    Data.AccountScope.fold all.user all.collective scope


getAllDefault : AllDashboards -> Maybe Dashboard
getAllDefault boards =
    Util.Maybe.or
        [ getDefault boards.user
        , getDefault boards.collective
        , getFirst boards.user
        , getFirst boards.collective
        ]


existsAll : String -> AllDashboards -> Bool
existsAll name boards =
    exists name boards.collective || exists name boards.user


singletonAll : Dashboard -> AllDashboards
singletonAll board =
    AllDashboards empty (singleton board)


isDefaultAll : String -> AllDashboards -> Bool
isDefaultAll name all =
    isDefault name all.user || isDefault name all.collective


findInAll : String -> AllDashboards -> Maybe Dashboard
findInAll name all =
    Util.Maybe.or
        [ find name all.user
        , find name all.collective
        ]


removeFromAll : String -> AllDashboards -> AllDashboards
removeFromAll name all =
    { user = remove name all.user
    , collective = remove name all.collective
    }


setDefaultAll : String -> AllDashboards -> AllDashboards
setDefaultAll name all =
    if isDefaultAll name all then
        all

    else
        { user = setDefault name all.user
        , collective = setDefault name all.collective
        }


unsetDefaultAll : String -> AllDashboards -> AllDashboards
unsetDefaultAll name all =
    if isDefaultAll name all then
        { user = unsetDefault name all.user
        , collective = unsetDefault name all.collective
        }

    else
        all


getScope : String -> AllDashboards -> Maybe AccountScope
getScope name all =
    if exists name all.user then
        Just Data.AccountScope.User

    else if exists name all.collective then
        Just Data.AccountScope.Collective

    else
        Nothing


countAll : AllDashboards -> Int
countAll all =
    List.sum
        [ foldl (\_ -> \n -> n + 1) 0 all.user
        , foldl (\_ -> \n -> n + 1) 0 all.collective
        ]



--- Helper


type alias Info =
    { boards : Dict String Dashboard
    , default : String
    }



--- JSON


decoder : D.Decoder Dashboards
decoder =
    D.oneOf
        [ D.map Dashboards infoDecoder
        , emptyObjectDecoder
        ]


encode : Dashboards -> E.Value
encode (Dashboards info) =
    infoEncode info


infoDecoder : D.Decoder Info
infoDecoder =
    D.map2 Info
        (D.field "boards" <| D.dict Data.Dashboard.decoder)
        (D.field "default" D.string)


emptyObjectDecoder : D.Decoder Dashboards
emptyObjectDecoder =
    D.dict (D.fail "non-empty") |> D.map (\_ -> empty)


infoEncode : Info -> E.Value
infoEncode info =
    E.object
        [ ( "boards", E.dict identity Data.Dashboard.encode info.boards )
        , ( "default", E.string info.default )
        ]
