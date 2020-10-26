module Comp.ItemDetail.FormChange exposing
    ( FormChange(..)
    , multiUpdate
    )

import Api
import Api.Model.BasicResult exposing (BasicResult)
import Api.Model.IdName exposing (IdName)
import Api.Model.ItemsAndDirection exposing (ItemsAndDirection)
import Api.Model.ItemsAndName exposing (ItemsAndName)
import Api.Model.ItemsAndRef exposing (ItemsAndRef)
import Api.Model.ItemsAndRefs exposing (ItemsAndRefs)
import Api.Model.ReferenceList exposing (ReferenceList)
import Data.Direction exposing (Direction)
import Data.Flags exposing (Flags)
import Http
import Set exposing (Set)


type FormChange
    = NoFormChange
    | TagChange ReferenceList
    | FolderChange (Maybe IdName)
    | DirectionChange Direction
    | OrgChange (Maybe IdName)
    | CorrPersonChange (Maybe IdName)
    | ConcPersonChange (Maybe IdName)
    | EquipChange (Maybe IdName)
    | ItemDateChange (Maybe Int)
    | DueDateChange (Maybe Int)
    | NameChange String


multiUpdate :
    Flags
    -> Set String
    -> FormChange
    -> (Result Http.Error BasicResult -> msg)
    -> Cmd msg
multiUpdate flags ids change receive =
    let
        items =
            Set.toList ids
    in
    case change of
        TagChange tags ->
            let
                data =
                    ItemsAndRefs items (List.map .id tags.items)
            in
            Api.setTagsMultiple flags data receive

        NameChange name ->
            let
                data =
                    ItemsAndName items name
            in
            Api.setNameMultiple flags data receive

        FolderChange id ->
            let
                data =
                    ItemsAndRef items (Maybe.map .id id)
            in
            Api.setFolderMultiple flags data receive

        DirectionChange dir ->
            let
                data =
                    ItemsAndDirection items (Data.Direction.toString dir)
            in
            Api.setDirectionMultiple flags data receive

        _ ->
            Cmd.none
