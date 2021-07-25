{-
   Copyright 2020 Docspell Contributors

   SPDX-License-Identifier: GPL-3.0-or-later
-}


module Data.Items exposing
    ( concat
    , first
    , idSet
    , length
    , replaceIn
    )

import Api.Model.ItemLight exposing (ItemLight)
import Api.Model.ItemLightGroup exposing (ItemLightGroup)
import Api.Model.ItemLightList exposing (ItemLightList)
import Dict exposing (Dict)
import Set exposing (Set)
import Util.List


concat : ItemLightList -> ItemLightList -> ItemLightList
concat l0 l1 =
    let
        lastOld =
            lastGroup l0

        firstNew =
            List.head l1.groups
    in
    case ( lastOld, firstNew ) of
        ( Nothing, Nothing ) ->
            l0

        ( Just _, Nothing ) ->
            l0

        ( Nothing, Just _ ) ->
            l1

        ( Just o, Just n ) ->
            if o.name == n.name then
                let
                    ng =
                        ItemLightGroup o.name (o.items ++ n.items)

                    prev =
                        Util.List.dropRight 1 l0.groups

                    suff =
                        List.drop 1 l1.groups
                in
                ItemLightList (prev ++ (ng :: suff))

            else
                ItemLightList (l0.groups ++ l1.groups)


first : ItemLightList -> Maybe ItemLight
first list =
    List.head list.groups
        |> Maybe.map .items
        |> Maybe.withDefault []
        |> List.head


length : ItemLightList -> Int
length list =
    List.map (\g -> List.length g.items) list.groups
        |> List.sum


lastGroup : ItemLightList -> Maybe ItemLightGroup
lastGroup list =
    List.reverse list.groups
        |> List.head


idSet : ItemLightList -> Set String
idSet items =
    List.map idSetGroup items.groups
        |> List.foldl Set.union Set.empty


idSetGroup : ItemLightGroup -> Set String
idSetGroup group =
    List.map .id group.items
        |> Set.fromList


replaceIn : ItemLightList -> ItemLightList -> ItemLightList
replaceIn origin replacements =
    let
        newItems =
            mkItemDict replacements

        replaceItem item =
            case Dict.get item.id newItems of
                Just ni ->
                    { ni | highlighting = item.highlighting }

                Nothing ->
                    item

        replaceGroup g =
            List.map replaceItem g.items
                |> ItemLightGroup g.name
    in
    List.map replaceGroup origin.groups
        |> ItemLightList



--- Helper


mkItemDict : ItemLightList -> Dict String ItemLight
mkItemDict list =
    let
        insertItems : Dict String ItemLight -> List ItemLight -> Dict String ItemLight
        insertItems dict items =
            List.foldl (\i -> \d -> Dict.insert i.id i d) dict items

        insertGroup dict groups =
            List.foldl (\g -> \d -> insertItems d g.items) dict groups
    in
    insertGroup Dict.empty list.groups
