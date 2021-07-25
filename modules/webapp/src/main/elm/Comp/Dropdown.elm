{-
   Copyright 2020 Docspell Contributors

   SPDX-License-Identifier: GPL-3.0-or-later
-}


module Comp.Dropdown exposing
    ( Model
    , Msg(..)
    , Option
    , ViewSettings
    , getSelected
    , isDropdownChangeMsg
    , makeModel
    , makeMultiple
    , makeSingle
    , makeSingleList
    , mkOption
    , notSelected
    , orgFormViewSettings
    , setMkOption
    , update
    , view2
    , viewSingle2
    )

import Api.Model.IdName exposing (IdName)
import Data.DropdownStyle as DS
import Data.UiSettings exposing (UiSettings)
import Html exposing (..)
import Html.Attributes exposing (..)
import Html.Events exposing (onClick, onInput)
import Simple.Fuzzy
import Util.Html exposing (onKeyUp)
import Util.List


type alias Item a =
    { value : a
    , visible : Bool
    , selected : Bool
    , active : Bool
    }


makeItem : Model a -> a -> Item a
makeItem model val =
    { value = val
    , visible = True
    , selected =
        List.any (\i -> i.value == val) model.selected
    , active = False
    }


type alias Model a =
    { multiple : Bool
    , selected : List (Item a)
    , available : List (Item a)
    , menuOpen : Bool
    , filterString : String
    , searchable : Int -> Bool
    }


makeModel :
    { multiple : Bool
    , searchable : Int -> Bool
    }
    -> Model a
makeModel input =
    { multiple = input.multiple
    , searchable = input.searchable
    , selected = []
    , available = []
    , menuOpen = False
    , filterString = ""
    }


makeSingle : Model a
makeSingle =
    makeModel
        { multiple = False
        , searchable = \n -> n > 0
        }


makeSingleList :
    { options : List a
    , selected : Maybe a
    }
    -> Model a
makeSingleList opts =
    let
        m =
            makeSingle

        m2 =
            { m | available = List.map (makeItem m) opts.options }

        m3 =
            Maybe.map (makeItem m2) opts.selected
                |> Maybe.map (selectItem m2)
                |> Maybe.withDefault m2
    in
    m3


makeMultiple : Model a
makeMultiple =
    makeModel
        { multiple = True
        , searchable = \n -> n > 0
        }


getSelected : Model a -> List a
getSelected model =
    List.map .value model.selected


notSelected : Model a -> Bool
notSelected model =
    getSelected model |> List.isEmpty


type Msg a
    = SetOptions (List a)
    | SetSelection (List a)
    | ToggleMenu
    | AddItem (Item a)
    | RemoveItem2 (Item a)
    | Filter (a -> String) String
    | ShowMenu Bool
    | KeyPress Int


getOptions : Model a -> List (Item a)
getOptions model =
    if not model.multiple && isSearchable model && model.menuOpen then
        List.filter .visible model.available

    else
        List.filter (\e -> e.visible && not e.selected) model.available


isSearchable : Model a -> Bool
isSearchable model =
    List.length model.available |> model.searchable



-- Update


deselectItem : Model a -> Item a -> Model a
deselectItem model item =
    let
        value =
            item.value

        sel =
            if model.multiple then
                List.filter (\e -> e.value /= value) model.selected

            else
                []

        show e =
            if e.value == value then
                { e | selected = False }

            else
                e

        avail =
            List.map show model.available
    in
    { model | selected = sel, available = avail }


selectItem : Model a -> Item a -> Model a
selectItem model item =
    let
        value =
            item.value

        sel =
            if model.multiple then
                List.concat [ model.selected, [ item ] ]

            else
                [ item ]

        hide e =
            if e.value == value then
                { e | selected = True }

            else if model.multiple then
                e

            else
                { e | selected = False }

        avail =
            List.map hide model.available
    in
    { model | selected = sel, available = avail }


filterOptions : String -> (a -> String) -> List (Item a) -> List (Item a)
filterOptions str mkText list =
    List.map (\e -> { e | visible = Simple.Fuzzy.match str (mkText e.value), active = False }) list


applyFilter : String -> (a -> String) -> Model a -> Model a
applyFilter str mkText model =
    let
        selected =
            if str /= "" && not model.multiple then
                []

            else
                model.selected
    in
    { model | filterString = str, available = filterOptions str mkText model.available, selected = selected }


clearFilter : Model a -> Model a
clearFilter model =
    { model | filterString = "" }


makeNextActive : (Int -> Int) -> Model a -> Model a
makeNextActive nextEl model =
    let
        opts =
            getOptions model

        current =
            Util.List.findIndexed .active opts

        next =
            Maybe.map Tuple.second current
                |> Maybe.map nextEl
                |> Maybe.andThen (Util.List.get opts)

        merge item1 item2 =
            { item2 | active = item1.value == item2.value }

        updateModel item =
            { model | available = List.map (merge item) model.available, menuOpen = True }
    in
    case next of
        Just item ->
            updateModel item

        Nothing ->
            case List.head opts of
                Just item ->
                    updateModel item

                Nothing ->
                    model


selectActive : Model a -> Model a
selectActive model =
    let
        current =
            getOptions model |> Util.List.find .active
    in
    case current of
        Just item ->
            selectItem model item |> clearFilter

        Nothing ->
            model


isDropdownChangeMsg : Msg a -> Bool
isDropdownChangeMsg cm =
    case cm of
        AddItem _ ->
            True

        RemoveItem2 _ ->
            True

        KeyPress code ->
            Util.Html.intToKeyCode code
                |> Maybe.map (\c -> c == Util.Html.Enter || c == Util.Html.ESC)
                |> Maybe.withDefault False

        _ ->
            False


update : Msg a -> Model a -> ( Model a, Cmd (Msg a) )
update msg model =
    case msg of
        SetOptions list ->
            ( { model | available = List.map (makeItem model) list }, Cmd.none )

        SetSelection list ->
            let
                m0 =
                    List.foldl (\item -> \m -> deselectItem m item) model model.selected

                m1 =
                    List.map (makeItem model) list
                        |> List.foldl (\item -> \m -> selectItem m item) m0
            in
            ( m1, Cmd.none )

        ToggleMenu ->
            ( { model | menuOpen = not model.menuOpen }, Cmd.none )

        AddItem e ->
            let
                m =
                    selectItem model e |> clearFilter
            in
            ( { m | menuOpen = False }, Cmd.none )

        RemoveItem2 e ->
            let
                m =
                    deselectItem model e |> clearFilter
            in
            ( m
            , Cmd.none
            )

        Filter f str ->
            let
                m =
                    applyFilter str f model
            in
            ( { m | menuOpen = True }, Cmd.none )

        ShowMenu flag ->
            ( { model | menuOpen = flag }, Cmd.none )

        KeyPress code ->
            case Util.Html.intToKeyCode code of
                Just Util.Html.Up ->
                    ( makeNextActive (\n -> n - 1) model, Cmd.none )

                Just Util.Html.Letter_P ->
                    ( makeNextActive (\n -> n - 1) model, Cmd.none )

                Just Util.Html.Letter_K ->
                    ( makeNextActive (\n -> n - 1) model, Cmd.none )

                Just Util.Html.Down ->
                    ( makeNextActive ((+) 1) model, Cmd.none )

                Just Util.Html.Letter_N ->
                    ( makeNextActive ((+) 1) model, Cmd.none )

                Just Util.Html.Letter_J ->
                    ( makeNextActive ((+) 1) model, Cmd.none )

                Just Util.Html.ESC ->
                    if model.menuOpen then
                        update ToggleMenu model

                    else
                        case model.selected of
                            [ e ] ->
                                let
                                    ( m_, c_ ) =
                                        update (RemoveItem2 e) model
                                in
                                ( { m_ | menuOpen = False }, c_ )

                            _ ->
                                ( model, Cmd.none )

                Just Util.Html.Space ->
                    if model.menuOpen then
                        ( model, Cmd.none )

                    else
                        update ToggleMenu model

                Just Util.Html.Enter ->
                    let
                        m =
                            selectActive model
                    in
                    ( { m | menuOpen = False }, Cmd.none )

                _ ->
                    ( model, Cmd.none )



-- View2


type alias Option =
    { text : String
    , additional : String
    }


mkOption : String -> Option
mkOption text =
    Option text ""


type alias ViewSettings a =
    { makeOption : a -> Option
    , placeholder : String
    , labelColor : a -> UiSettings -> String
    , style : DS.DropdownStyle
    }


orgFormViewSettings : String -> DS.DropdownStyle -> ViewSettings IdName
orgFormViewSettings placeholder ds =
    { makeOption = \e -> { text = e.name, additional = "" }
    , labelColor = \_ -> \_ -> ""
    , placeholder = placeholder
    , style = ds
    }


setMkOption : (a -> Option) -> ViewSettings a -> ViewSettings a
setMkOption mkopt model =
    { model | makeOption = mkopt }


view2 : ViewSettings a -> UiSettings -> Model a -> Html (Msg a)
view2 cfg settings model =
    if model.multiple then
        viewMultiple2 cfg settings model

    else
        viewSingle2 cfg model


viewSingle2 : ViewSettings a -> Model a -> Html (Msg a)
viewSingle2 cfg model =
    let
        renderItem item =
            a
                [ href "#"
                , class cfg.style.item
                , classList
                    [ ( cfg.style.itemActive, item.active )
                    , ( "font-semibold", item.selected )
                    ]
                , onClick (AddItem item)
                , onKeyUp KeyPress
                ]
                [ text <| (.value >> cfg.makeOption >> .text) item
                , span [ class "text-gray-400 float-right" ]
                    [ text <| (.value >> cfg.makeOption >> .additional) item
                    ]
                ]

        sel =
            List.head model.selected
    in
    div
        [ class "relative "
        , onKeyUp KeyPress
        ]
        [ div
            [ class cfg.style.link
            ]
            [ a
                [ class "flex-grow"
                , classList
                    [ ( "opacity-50", sel == Nothing )
                    , ( "hidden", model.menuOpen && isSearchable model )
                    , ( "ml-4", sel /= Nothing )
                    ]
                , tabindex 0
                , onKeyUp KeyPress
                , onClick ToggleMenu
                , href "#"
                ]
                [ Maybe.map (.value >> cfg.makeOption >> .text) sel
                    |> Maybe.withDefault cfg.placeholder
                    |> text
                ]
            , a
                [ class "absolute left-3"
                , classList
                    [ ( "hidden", (model.menuOpen && isSearchable model) || sel == Nothing )
                    ]
                , class "hover:opacity-50"
                , href "#"
                , Maybe.map (\item -> onClick (RemoveItem2 item)) sel
                    |> Maybe.withDefault (class "hidden")
                ]
                [ i [ class "fa fa-times" ] []
                ]
            , input
                [ type_ "text"
                , placeholder cfg.placeholder
                , onInput (Filter (cfg.makeOption >> .text))
                , value model.filterString
                , class "inline-block border-0 px-0 w-full py-0 focus:ring-0 "
                , class cfg.style.input
                , classList [ ( "hidden", not (model.menuOpen && isSearchable model) ) ]
                ]
                []
            , a
                [ class "rounded cursor-pointer ml-2 absolute right-2"
                , onKeyUp KeyPress
                , onClick ToggleMenu
                , href "#"
                ]
                [ i [ class "fa fa-angle-down px-2" ] []
                ]
            ]
        , div
            [ class cfg.style.menu
            , classList [ ( "hidden", not model.menuOpen ) ]
            ]
            (getOptions model |> List.map renderItem)
        ]


viewMultiple2 : ViewSettings a -> UiSettings -> Model a -> Html (Msg a)
viewMultiple2 cfg settings model =
    let
        renderItem item =
            a
                [ href "#"
                , class cfg.style.item
                , classList
                    [ ( cfg.style.itemActive, item.active )
                    , ( "font-semibold", item.selected )
                    ]
                , onClick (AddItem item)
                , onKeyUp KeyPress
                ]
                [ text <| (.value >> cfg.makeOption >> .text) item
                , span [ class "text-gray-400 float-right" ]
                    [ text <| (.value >> cfg.makeOption >> .additional) item
                    ]
                ]

        renderSelectMultiple : Item a -> Html (Msg a)
        renderSelectMultiple item =
            a
                [ class (cfg.labelColor item.value settings)
                , class "label font-medium inline-flex relative items-center hover:shadow-md mt-1 mr-1"
                , onClick (RemoveItem2 item)
                , href "#"
                ]
                [ span [ class "pl-4" ]
                    [ text <| (.value >> cfg.makeOption >> .text) item
                    ]
                , span [ class "opacity-75 absolute left-2 my-auto" ]
                    [ i [ class "fa fa-times" ] []
                    ]
                ]
    in
    div
        [ class "relative"
        , onKeyUp KeyPress
        ]
        [ div
            [ class cfg.style.link
            , class "flex inline-flex flex-wrap items-center"
            ]
            [ div
                [ class "flex flex-row flex-wrap items-center mr-2 -mt-1"
                , classList [ ( "hidden", List.isEmpty model.selected ) ]
                ]
                (List.map renderSelectMultiple model.selected)
            , input
                [ type_ "text"
                , placeholder cfg.placeholder
                , onInput (Filter (cfg.makeOption >> .text))
                , value model.filterString
                , class "inline-flex w-16 border-0 px-0 focus:ring-0 h-6"
                , class cfg.style.input
                ]
                []
            , a
                [ class "block h-6 flex-grow"
                , onKeyUp KeyPress
                , onClick ToggleMenu
                , href "#"
                ]
                [ i
                    [ class "fa fa-angle-down px-2"
                    , class "absolute right-2 rounded cursor-pointer ml-2 top-1/3"
                    ]
                    []
                ]
            ]
        , div
            [ class cfg.style.menu
            , classList [ ( "hidden", not model.menuOpen ) ]
            ]
            (getOptions model |> List.map renderItem)
        ]
