{-
   Copyright 2020 Eike K. & Contributors

   SPDX-License-Identifier: AGPL-3.0-or-later
-}


module Comp.ChannelMenu exposing (..)

import Comp.MenuBar as MB
import Data.ChannelType exposing (ChannelType)
import Html exposing (..)
import Html.Attributes exposing (..)
import Html.Events exposing (onClick)
import Messages.Data.ChannelType exposing (Texts)
import Styles as S


type alias Model msg =
    { menuOpen : Bool
    , toggleMenu : msg
    , menuLabel : String
    , onItem : ChannelType -> msg
    }


channelMenu : Texts -> Model msg -> MB.Item msg
channelMenu texts model =
    MB.Dropdown
        { linkIcon = "fa fa-plus"
        , label = model.menuLabel
        , linkClass = [ ( S.primaryButton, True ) ]
        , toggleMenu = model.toggleMenu
        , menuOpen = model.menuOpen
        , items =
            List.map (menuItem texts model) Data.ChannelType.all
        }


menuItem : Texts -> Model msg -> ChannelType -> MB.DropdownMenu msg
menuItem texts model ct =
    { icon = Data.ChannelType.icon ct "w-6 h-6 text-center inline-block"
    , label = texts ct
    , disabled = False
    , attrs =
        [ href ""
        , onClick (model.onItem ct)
        ]
    }
