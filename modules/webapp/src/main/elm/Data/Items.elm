module Data.Items exposing
    ( concat
    , first
    , length
    )

import Api.Model.ItemLight exposing (ItemLight)
import Api.Model.ItemLightGroup exposing (ItemLightGroup)
import Api.Model.ItemLightList exposing (ItemLightList)
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
                ItemLightList (prev ++ [ ng ] ++ suff)

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
