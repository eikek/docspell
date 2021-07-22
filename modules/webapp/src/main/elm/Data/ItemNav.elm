{-
  Copyright 2020 Docspell Contributors

  SPDX-License-Identifier: GPL-3.0-or-later
-}

module Data.ItemNav exposing (ItemNav, fromList)

import Api.Model.ItemLight exposing (ItemLight)
import Api.Model.ItemLightList exposing (ItemLightList)
import Util.List


type alias ItemNav =
    { prev : Maybe String
    , next : Maybe String
    , index : Maybe Int
    , length : Int
    }


fromList : ItemLightList -> String -> ItemNav
fromList list id =
    let
        all : List ItemLight
        all =
            List.concatMap .items list.groups

        next =
            Util.List.findNext (\i -> i.id == id) all
                |> Maybe.map .id

        prev =
            Util.List.findPrev (\i -> i.id == id) all
                |> Maybe.map .id

        len =
            List.length all

        index : Maybe Int
        index =
            Util.List.findIndexed (.id >> (==) id) all
                |> Maybe.map Tuple.second
    in
    { prev = prev
    , next = next
    , index = index
    , length = len
    }
