{-
   Copyright 2020 Eike K. & Contributors

   SPDX-License-Identifier: AGPL-3.0-or-later
-}


module Page.Share.Menubar exposing (view)

import Comp.Basic as B
import Comp.MenuBar as MB
import Comp.PowerSearchInput
import Comp.SearchMenu
import Html exposing (..)
import Html.Attributes exposing (..)
import Html.Events exposing (onClick)
import Messages.Page.Share exposing (Texts)
import Page.Share.Data exposing (Model, Msg(..))
import Styles as S


view : Texts -> Model -> Html Msg
view texts model =
    let
        btnStyle =
            S.secondaryBasicButton ++ " text-sm"

        searchInput =
            Comp.SearchMenu.textSearchString
                model.searchMenuModel.textSearchModel

        powerSearchBar =
            div
                [ class "relative flex flex-grow flex-row" ]
                [ Html.map PowerSearchMsg
                    (Comp.PowerSearchInput.viewInput
                        { placeholder = texts.basics.searchPlaceholder
                        , extraAttrs = []
                        }
                        model.powerSearchInput
                    )
                , Html.map PowerSearchMsg
                    (Comp.PowerSearchInput.viewResult [] model.powerSearchInput)
                ]
    in
    MB.view
        { end =
            [ MB.CustomElement <|
                B.secondaryBasicButton
                    { label = ""
                    , icon =
                        if model.searchInProgress then
                            "fa fa-sync animate-spin"

                        else
                            "fa fa-sync"
                    , disabled = model.searchInProgress
                    , handler = onClick ResetSearch
                    , attrs = [ href "#" ]
                    }
            ]
        , start =
            [ MB.CustomElement <|
                powerSearchBar
            ]
        , rootClasses = "mb-2 pt-1 dark:bg-bluegray-700 items-center text-sm"
        }
