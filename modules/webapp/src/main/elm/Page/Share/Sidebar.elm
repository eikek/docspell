{-
   Copyright 2020 Eike K. & Contributors

   SPDX-License-Identifier: AGPL-3.0-or-later
-}


module Page.Share.Sidebar exposing (..)

import Comp.SearchMenu
import Comp.Tabs
import Data.Flags exposing (Flags)
import Data.UiSettings exposing (UiSettings)
import Html exposing (..)
import Html.Attributes exposing (..)
import Messages.Page.Share exposing (Texts)
import Page.Share.Data exposing (Model, Msg(..))
import Util.ItemDragDrop


view : Texts -> Flags -> UiSettings -> Model -> Html Msg
view texts flags settings model =
    let
        hideTrashTab tab default =
            case tab of
                Comp.SearchMenu.TabTrashed ->
                    Comp.Tabs.Hidden

                _ ->
                    default

        searchMenuCfg =
            { overrideTabLook = hideTrashTab
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
                settings
                model.searchMenuModel
            )
        ]


ddDummy : Util.ItemDragDrop.DragDropData
ddDummy =
    { model = Util.ItemDragDrop.init
    , dropped = Nothing
    }
