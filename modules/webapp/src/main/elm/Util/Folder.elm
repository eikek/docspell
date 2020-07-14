module Util.Folder exposing
    ( isFolderMember
    , mkFolderOption
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
    { value = idref.id, text = idref.name, additional = adds }


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
