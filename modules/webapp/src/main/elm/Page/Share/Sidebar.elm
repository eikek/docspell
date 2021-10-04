module Page.Share.Sidebar exposing (..)

import Comp.SearchMenu
import Data.Flags exposing (Flags)
import Data.UiSettings exposing (UiSettings)
import Html exposing (..)
import Html.Attributes exposing (..)
import Messages.Page.Share exposing (Texts)
import Page.Share.Data exposing (Model, Msg(..))
import Util.ItemDragDrop


view : Texts -> Flags -> UiSettings -> Model -> Html Msg
view texts flags settings model =
    div
        [ class "flex flex-col"
        ]
        [ Html.map SearchMenuMsg
            (Comp.SearchMenu.viewDrop2 texts.searchMenu
                ddDummy
                flags
                settings
                model.searchMenuModel
            )
        ]


ddDummy : Util.ItemDragDrop.DragDropData
ddDummy =
    { model = Util.ItemDragDrop.init
    , dropped = Nothing
    }
