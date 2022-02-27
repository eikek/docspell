{-
   Copyright 2020 Eike K. & Contributors

   SPDX-License-Identifier: AGPL-3.0-or-later
-}


module Page.Share.Sidebar exposing (..)

import Comp.SearchMenu
import Comp.Tabs
import Data.Flags exposing (Flags)
import Data.ItemIds
import Html exposing (..)
import Html.Attributes exposing (..)
import Messages.Page.Share exposing (Texts)
import Page.Share.Data exposing (Model, Msg(..))
import Util.ItemDragDrop


view : Texts -> Flags -> Model -> Html Msg
view texts flags model =
    let
        hideTrashTab tab default =
            case tab of
                Comp.SearchMenu.TabTrashed ->
                    Comp.Tabs.Hidden

                _ ->
                    default

        searchMenuCfg =
            { overrideTabLook = hideTrashTab
            , selectedItems = Data.ItemIds.empty
            }
    in
    div
        [ class "flex flex-col"
        ]
        [ Html.map SearchMenuMsg
            (Comp.SearchMenu.viewDrop2 texts.searchMenu
                ddDummy
                flags
                searchMenuCfg
                model.uiSettings
                model.searchMenuModel
            )
        ]


ddDummy : Util.ItemDragDrop.DragDropData
ddDummy =
    { model = Util.ItemDragDrop.init
    , dropped = Nothing
    }
