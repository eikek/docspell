{-
   Copyright 2020 Eike K. & Contributors

   SPDX-License-Identifier: AGPL-3.0-or-later
-}


module Comp.ItemDetail.RunAddonForm exposing (..)

import Comp.Basic as B
import Comp.Dropdown
import Comp.ItemDetail.Model exposing (..)
import Comp.MenuBar as MB
import Data.DropdownStyle as DS
import Data.UiSettings exposing (UiSettings)
import Html exposing (Html, div, h3, label, text)
import Html.Attributes exposing (class, classList, title)
import Html.Events exposing (onClick)
import Messages.Comp.ItemDetail.RunAddonForm exposing (Texts)
import Styles as S


view : Texts -> UiSettings -> Model -> Html Msg
view texts uiSettings model =
    let
        viewSettings =
            { makeOption = \cfg -> { text = cfg.name, additional = "" }
            , placeholder = texts.basics.selectPlaceholder
            , labelColor = \_ -> \_ -> ""
            , style = DS.mainStyle
            }

        runDisabled =
            Comp.Dropdown.getSelected model.addonRunConfigDropdown
                |> List.isEmpty
    in
    div
        [ classList [ ( "hidden", not model.showRunAddon ) ]
        , class "mb-4"
        ]
        [ h3 [ class S.header3 ] [ text texts.runAddon ]
        , div [ class "my-2" ]
            [ label [ class S.inputLabel ]
                [ text texts.addonRunConfig
                ]
            , Html.map RunAddonMsg (Comp.Dropdown.view2 viewSettings uiSettings model.addonRunConfigDropdown)
            ]
        , div [ class "my-2" ]
            [ MB.view
                { start =
                    [ MB.CustomElement <|
                        B.primaryButton
                            { label = "Run"
                            , icon =
                                if model.addonRunSubmitted then
                                    "fa fa-check"

                                else
                                    "fa fa-play"
                            , disabled = runDisabled
                            , handler = onClick RunSelectedAddon
                            , attrs =
                                [ title texts.runAddonTitle
                                ]
                            }
                    , MB.SecondaryButton
                        { label = texts.basics.cancel
                        , icon = Just "fa fa-times"
                        , tagger = ToggleShowRunAddon
                        , title = ""
                        }
                    ]
                , end = []
                , rootClasses = "text-sm mt-1"
                , sticky = False
                }
            ]
        ]
