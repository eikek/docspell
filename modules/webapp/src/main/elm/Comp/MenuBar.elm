{-
  Copyright 2020 Docspell Contributors

  SPDX-License-Identifier: GPL-3.0-or-later
-}

module Comp.MenuBar exposing
    ( ButtonData
    , CheckboxData
    , Item(..)
    , MenuBar
    , TextInputData
    , view
    , viewItem
    , viewSide
    )

import Html exposing (..)
import Html.Attributes exposing (..)
import Html.Events exposing (onCheck, onClick, onInput)
import Styles as S


type Item msg
    = TextInput (TextInputData msg)
    | Checkbox (CheckboxData msg)
    | PrimaryButton (ButtonData msg)
    | SecondaryButton (ButtonData msg)
    | DeleteButton (ButtonData msg)
    | BasicButton (ButtonData msg)
    | CustomButton (CustomButtonData msg)
    | TextLabel LabelData
    | CustomElement (Html msg)
    | Dropdown (DropdownData msg)


type alias MenuBar msg =
    { start : List (Item msg)
    , end : List (Item msg)
    , rootClasses : String
    }


type alias TextInputData msg =
    { tagger : String -> msg
    , value : String
    , placeholder : String
    , icon : Maybe String
    }


type alias CheckboxData msg =
    { tagger : Bool -> msg
    , label : String
    , value : Bool
    , id : String
    }


type alias ButtonData msg =
    { tagger : msg
    , title : String
    , icon : Maybe String
    , label : String
    }


type alias CustomButtonData msg =
    { tagger : msg
    , title : String
    , icon : Maybe String
    , label : String
    , inputClass : List ( String, Bool )
    }


type alias LabelData =
    { icon : String
    , label : String
    , class : String
    }


type alias DropdownData msg =
    { linkIcon : String
    , linkClass : List ( String, Bool )
    , toggleMenu : msg
    , menuOpen : Bool
    , items : List (DropdownMenu msg)
    }


type alias DropdownMenu msg =
    { icon : String
    , label : String
    , attrs : List (Attribute msg)
    }


view : MenuBar msg -> Html msg
view =
    view1 "bg-white dark:bg-bluegray-800"


viewSide : MenuBar msg -> Html msg
viewSide =
    view1 "bg-blue-50 dark:bg-bluegray-700"


view1 : String -> MenuBar msg -> Html msg
view1 classes mb =
    let
        left =
            div [ class "flex flex-row items-center space-x-2 w-full" ]
                (List.map viewItem mb.start)

        right =
            div [ class "flex-grow flex-row flex justify-end space-x-2 w-full" ]
                (List.map viewItem mb.end)
    in
    div
        [ class mb.rootClasses
        , class "flex flex-col sm:flex-row space-y-1 sm:space-y-0 sticky top-0 z-40"
        , class classes
        ]
        [ left
        , right
        ]


viewItem : Item msg -> Html msg
viewItem item =
    case item of
        TextInput model ->
            makeInput model

        Checkbox model ->
            makeCheckbox model

        PrimaryButton model ->
            makeButton [ ( S.primaryButton, True ) ] model

        SecondaryButton model ->
            makeButton [ ( S.secondaryButton, True ) ] model

        DeleteButton model ->
            makeButton [ ( S.deleteButton, True ) ] model

        BasicButton model ->
            makeButton [ ( S.secondaryBasicButton, True ) ] model

        CustomButton model ->
            makeButton model.inputClass model

        TextLabel model ->
            makeLabel model

        CustomElement v ->
            v

        Dropdown model ->
            makeDropdown model


makeDropdown : DropdownData msg -> Html msg
makeDropdown model =
    let
        menuStyle =
            "absolute right-0 bg-white dark:bg-bluegray-800 border dark:border-bluegray-700 z-50 dark:text-bluegray-300 shadow-lg transition duration-200 min-w-max  "

        itemStyle =
            "transition-colors duration-200 items-center block px-4 py-2 text-normal hover:bg-gray-200 dark:hover:bg-bluegray-700 dark:hover:text-bluegray-50"

        menuItem m =
            a
                (class itemStyle :: m.attrs)
                [ i
                    [ class m.icon
                    , classList [ ( "hidden", m.icon == "" ) ]
                    ]
                    []
                , span
                    [ class "ml-2"
                    , classList [ ( "hidden", m.label == "" ) ]
                    ]
                    [ text m.label
                    ]
                ]
    in
    div [ class "relative" ]
        [ a
            [ classList model.linkClass
            , class "block"
            , href "#"
            , onClick model.toggleMenu
            ]
            [ i [ class model.linkIcon ] []
            ]
        , div
            [ class menuStyle
            , classList [ ( "hidden", not model.menuOpen ) ]
            ]
            (List.map menuItem model.items)
        ]


makeLabel : LabelData -> Html msg
makeLabel model =
    div
        [ class "flex items-center justify-center "
        , class model.class
        ]
        [ i
            [ class model.icon
            , classList [ ( "hidden", model.icon == "" ) ]
            ]
            []
        , text model.label
        ]


makeButton :
    List ( String, Bool )
    ->
        { e
            | tagger : msg
            , title : String
            , icon : Maybe String
            , label : String
        }
    -> Html msg
makeButton btnType model =
    let
        ( icon, iconMargin ) =
            case model.icon of
                Just cls ->
                    ( [ i [ class cls ] []
                      ]
                    , if model.label == "" then
                        ""

                      else
                        "ml-2"
                    )

                Nothing ->
                    ( [], "" )

        label =
            if model.label == "" then
                []

            else
                [ span [ class (iconMargin ++ " hidden sm:inline") ]
                    [ text model.label
                    ]
                ]
    in
    a
        [ classList btnType
        , href "#"
        , onClick model.tagger
        , title model.title
        ]
        (icon ++ label)


makeCheckbox : CheckboxData msg -> Html msg
makeCheckbox model =
    div [ class "" ]
        [ label
            [ class "inline-flex space-x-2 items-center"
            , for model.id
            ]
            [ input
                [ type_ "checkbox"
                , onCheck model.tagger
                , checked model.value
                , class S.checkboxInput
                , id model.id
                ]
                []
            , span [ class "truncate" ]
                [ text model.label
                ]
            ]
        ]


makeInput : TextInputData msg -> Html msg
makeInput model =
    let
        ( icon, iconPad ) =
            case model.icon of
                Just cls ->
                    ( [ div [ class S.inputIcon ]
                            [ i [ class cls ] []
                            ]
                      ]
                    , "pl-10"
                    )

                Nothing ->
                    ( [], "" )
    in
    div [ class "relative pr-2" ]
        (input
            [ type_ "text"
            , onInput model.tagger
            , value model.value
            , placeholder model.placeholder
            , class (iconPad ++ " pr-4 py-1 rounded" ++ S.textInput)
            ]
            []
            :: icon
        )
