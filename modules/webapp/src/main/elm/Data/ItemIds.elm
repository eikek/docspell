{-
   Copyright 2020 Eike K. & Contributors

   SPDX-License-Identifier: AGPL-3.0-or-later
-}


module Data.ItemIds exposing
    ( ItemIdChange
    , ItemIds
    , apply
    , combine
    , combineAll
    , deselect
    , empty
    , fromSet
    , isEmpty
    , isMember
    , noChange
    , select
    , selectAll
    , size
    , toList
    , toQuery
    , toggle
    , union
    )

import Data.ItemQuery exposing (ItemQuery)
import Set exposing (Set)


type ItemIds
    = ItemIds (Set String)


empty : ItemIds
empty =
    ItemIds Set.empty


isEmpty : ItemIds -> Bool
isEmpty (ItemIds ids) =
    Set.isEmpty ids


isMember : ItemIds -> String -> Bool
isMember (ItemIds ids) id =
    Set.member id ids


size : ItemIds -> Int
size (ItemIds ids) =
    Set.size ids


fromSet : Set String -> ItemIds
fromSet ids =
    ItemIds ids


union : ItemIds -> ItemIds -> ItemIds
union (ItemIds ids1) (ItemIds ids2) =
    ItemIds (Set.union ids1 ids2)


toList : ItemIds -> List String
toList (ItemIds ids) =
    Set.toList ids


toQuery : ItemIds -> ItemQuery
toQuery (ItemIds ids) =
    Data.ItemQuery.ItemIdIn (Set.toList ids)



--- Change item ids


type ItemIdChange
    = ItemIdChange
        { remove : Set String
        , add : Set String
        }


apply : ItemIds -> ItemIdChange -> ItemIds
apply (ItemIds ids) (ItemIdChange { remove, add }) =
    ItemIds (Set.diff ids remove |> Set.union add)


noChange : ItemIdChange
noChange =
    ItemIdChange { remove = Set.empty, add = Set.empty }


combine : ItemIdChange -> ItemIdChange -> ItemIdChange
combine (ItemIdChange c1) (ItemIdChange c2) =
    ItemIdChange
        { remove = Set.union c1.remove c2.remove
        , add = Set.union c1.add c2.add
        }


combineAll : List ItemIdChange -> ItemIdChange
combineAll all =
    List.foldl combine noChange all


select : String -> ItemIdChange
select id =
    ItemIdChange { add = Set.singleton id, remove = Set.empty }


selectAll : Set String -> ItemIdChange
selectAll ids =
    ItemIdChange { add = ids, remove = Set.empty }


deselect : String -> ItemIdChange
deselect id =
    ItemIdChange { add = Set.empty, remove = Set.singleton id }


toggle : ItemIds -> String -> ItemIdChange
toggle ids id =
    if isMember ids id then
        deselect id

    else
        select id
