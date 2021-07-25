{-
   Copyright 2020 Docspell Contributors

   SPDX-License-Identifier: GPL-3.0-or-later
-}


module Util.Folder exposing
    ( isFolderMember
    , mkFolderOption
    , onlyVisible
    )

import Api.Model.FolderItem exposing (FolderItem)
import Api.Model.IdName exposing (IdName)
import Comp.Dropdown
import Data.Flags exposing (Flags)


mkFolderOption : Flags -> List FolderItem -> IdName -> Comp.Dropdown.Option
mkFolderOption flags allFolders idref =
    let
        folder =
            List.filter (\e -> e.id == idref.id) allFolders
                |> List.head

        isMember =
            folder
                |> Maybe.map .isMember
                |> Maybe.withDefault False

        isOwner =
            Maybe.map .owner folder
                |> Maybe.map .name
                |> (==) (Maybe.map .user flags.account)

        adds =
            if isOwner then
                "owner"

            else if isMember then
                "member"

            else
                ""
    in
    { text = idref.name, additional = adds }


isFolderMember : List FolderItem -> Maybe String -> Bool
isFolderMember allFolders selected =
    let
        findFolder id =
            List.filter (\e -> e.id == id) allFolders
                |> List.head

        folder =
            Maybe.andThen findFolder selected
    in
    Maybe.map .isMember folder
        |> Maybe.withDefault True


onlyVisible : Flags -> List FolderItem -> List FolderItem
onlyVisible flags folders =
    let
        isVisible folder =
            folder.isMember
                || (Maybe.map .user flags.account == Just folder.owner.name)
    in
    List.filter isVisible folders
