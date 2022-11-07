{-
   Copyright 2020 Eike K. & Contributors

   SPDX-License-Identifier: AGPL-3.0-or-later
-}


module Data.ItemIds exposing
    ( ItemIdChange
    , ItemIds
    , apply
    , clearAll
    , combine
    , combineAll
    , deselect
    , empty
    , fromSet
    , isEmpty
    , isMember
    , maybeOne
    , noChange
    , nonEmpty
    , one
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


nonEmpty : ItemIds -> Bool
nonEmpty ids =
    not (isEmpty ids)


isMember : ItemIds -> String -> Bool
isMember (ItemIds ids) id =
    Set.member id ids


size : ItemIds -> Int
size (ItemIds ids) =
    Set.size ids


fromSet : Set String -> ItemIds
fromSet ids =
    ItemIds ids


one : String -> ItemIds
one id =
    ItemIds (Set.singleton id)


maybeOne : Maybe String -> ItemIds
maybeOne id =
    Maybe.map one id |> Maybe.withDefault empty


union : ItemIds -> ItemIds -> ItemIds
union (ItemIds ids1) (ItemIds ids2) =
    ItemIds (Set.union ids1 ids2)


toList : ItemIds -> List String
toList (ItemIds ids) =
    Set.toList ids


toQuery : ItemIds -> Maybe ItemQuery
toQuery (ItemIds ids) =
    if Set.isEmpty ids then
        Nothing

    else
        Just <| Data.ItemQuery.ItemIdIn (Set.toList ids)



--- Change item ids


type ItemIdChange
    = ItemIdChange
        { remove : Set String
        , add : Set String
        , clear : Bool
        }


apply : ItemIds -> ItemIdChange -> ItemIds
apply (ItemIds ids) (ItemIdChange { remove, add, clear }) =
    if clear then
        empty

    else
        ItemIds (Set.diff ids remove |> Set.union add)


noChange : ItemIdChange
noChange =
    ItemIdChange { remove = Set.empty, add = Set.empty, clear = False }


combine : ItemIdChange -> ItemIdChange -> ItemIdChange
combine (ItemIdChange c1) (ItemIdChange c2) =
    ItemIdChange
        { remove = Set.union c1.remove c2.remove
        , add = Set.union c1.add c2.add
        , clear = False
        }


combineAll : List ItemIdChange -> ItemIdChange
combineAll all =
    List.foldl combine noChange all


select : String -> ItemIdChange
select id =
    ItemIdChange { add = Set.singleton id, remove = Set.empty, clear = False }


selectAll : Set String -> ItemIdChange
selectAll ids =
    ItemIdChange { add = ids, remove = Set.empty, clear = False }


deselect : String -> ItemIdChange
deselect id =
    ItemIdChange { add = Set.empty, remove = Set.singleton id, clear = False }


clearAll : ItemIdChange
clearAll =
    ItemIdChange { add = Set.empty, remove = Set.empty, clear = True }


toggle : ItemIds -> String -> ItemIdChange
toggle ids id =
    if isMember ids id then
        deselect id

    else
        select id
