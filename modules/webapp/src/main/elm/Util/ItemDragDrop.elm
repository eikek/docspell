{-
   Copyright 2020 Eike K. & Contributors

   SPDX-License-Identifier: AGPL-3.0-or-later
-}


module Util.ItemDragDrop exposing
    ( DragDropData
    , Dropped
    , ItemDrop(..)
    , Model
    , Msg
    , draggable
    , droppable
    , getDropId
    , init
    , makeUpdateCmd
    , update
    )

import Api
import Api.Model.BasicResult exposing (BasicResult)
import Api.Model.OptionalId exposing (OptionalId)
import Api.Model.StringList exposing (StringList)
import Data.Flags exposing (Flags)
import Html exposing (Attribute)
import Html5.DragDrop as DD
import Http


type ItemDrop
    = Tag String
    | Folder String
    | FolderRemove


type alias Model =
    DD.Model String ItemDrop


type alias Msg =
    DD.Msg String ItemDrop


type alias Dropped =
    { itemId : String
    , target : ItemDrop
    }


type alias DragDropData =
    { model : Model
    , dropped : Maybe Dropped
    }


init : Model
init =
    DD.init


update : Msg -> Model -> DragDropData
update msg model =
    let
        ( m, res ) =
            DD.update msg model
    in
    DragDropData m (Maybe.map (\( id, t, _ ) -> Dropped id t) res)


makeUpdateCmd :
    Flags
    -> (Result Http.Error BasicResult -> msg)
    -> Maybe Dropped
    -> Cmd msg
makeUpdateCmd flags receive droppedMaybe =
    case droppedMaybe of
        Just dropped ->
            case dropped.target of
                Folder fid ->
                    Api.setFolder flags dropped.itemId (OptionalId (Just fid)) receive

                FolderRemove ->
                    Api.setFolder flags dropped.itemId (OptionalId Nothing) receive

                Tag tid ->
                    Api.toggleTags flags dropped.itemId (StringList [ tid ]) receive

        Nothing ->
            Cmd.none


droppable : (Msg -> msg) -> ItemDrop -> List (Attribute msg)
droppable tagger dropId =
    DD.droppable tagger dropId


draggable : (Msg -> msg) -> String -> List (Attribute msg)
draggable tagger itemId =
    DD.draggable tagger itemId


getDropId : Model -> Maybe ItemDrop
getDropId model =
    DD.getDropId model
