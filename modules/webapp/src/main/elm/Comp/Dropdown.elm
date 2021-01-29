module Comp.Dropdown exposing
    ( Model
    , Msg(..)
    , Option
    , getSelected
    , isDropdownChangeMsg
    , makeModel
    , makeMultiple
    , makeSingle
    , makeSingleList
    , mkOption
    , notSelected
    , orgDropdown
    , setMkOption
    , update
    , view
    , view2
    , viewSingle
    , viewSingle2
    )

{-| This needs to be rewritten from scratch!
-}

import Api.Model.IdName exposing (IdName)
import Data.DropdownStyle as DS
import Data.UiSettings exposing (UiSettings)
import Html exposing (..)
import Html.Attributes exposing (..)
import Html.Events exposing (onClick, onInput)
import Simple.Fuzzy
import Util.Html exposing (onKeyUp)
import Util.List


orgDropdown : Model IdName
orgDropdown =
    makeModel
        { multiple = False
        , searchable = \n -> n > 0
        , makeOption = \e -> { value = e.id, text = e.name, additional = "" }
        , labelColor = \_ -> \_ -> ""
        , placeholder = "Choose an organization"
        }


type alias Option =
    { value : String
    , text : String
    , additional : String
    }


mkOption : String -> String -> Option
mkOption value text =
    Option value text ""


type alias Item a =
    { value : a
    , option : Option
    , visible : Bool
    , selected : Bool
    , active : Bool
    }


makeItem : Model a -> a -> Item a
makeItem model val =
    { value = val
    , option = model.makeOption val
    , visible = True
    , selected =
        List.any (\i -> i.value == val) model.selected
    , active = False
    }


type alias Model a =
    { multiple : Bool
    , selected : List (Item a)
    , available : List (Item a)
    , makeOption : a -> Option
    , menuOpen : Bool
    , filterString : String
    , labelColor : a -> UiSettings -> String
    , searchable : Int -> Bool
    , placeholder : String
    }


setMkOption : (a -> Option) -> Model a -> Model a
setMkOption mkopt model =
    { model | makeOption = mkopt }


makeModel :
    { multiple : Bool
    , searchable : Int -> Bool
    , makeOption : a -> Option
    , labelColor : a -> UiSettings -> String
    , placeholder : String
    }
    -> Model a
makeModel input =
    { multiple = input.multiple
    , searchable = input.searchable
    , selected = []
    , available = []
    , makeOption = input.makeOption
    , menuOpen = False
    , filterString = ""
    , labelColor = input.labelColor
    , placeholder = input.placeholder
    }


makeSingle :
    { makeOption : a -> Option
    , placeholder : String
    }
    -> Model a
makeSingle opts =
    makeModel
        { multiple = False
        , searchable = \n -> n > 0
        , makeOption = opts.makeOption
        , labelColor = \_ -> \_ -> ""
        , placeholder =
            if opts.placeholder == "" then
                "Select…"

            else
                opts.placeholder
        }


makeSingleList :
    { makeOption : a -> Option
    , placeholder : String
    , options : List a
    , selected : Maybe a
    }
    -> Model a
makeSingleList opts =
    let
        m =
            makeSingle { makeOption = opts.makeOption, placeholder = opts.placeholder }

        m2 =
            { m | available = List.map (makeItem m) opts.options }

        m3 =
            Maybe.map (makeItem m2) opts.selected
                |> Maybe.map (selectItem m2)
                |> Maybe.withDefault m2
    in
    m3


makeMultiple :
    { makeOption : a -> Option
    , labelColor : a -> UiSettings -> String
    }
    -> Model a
makeMultiple opts =
    makeModel
        { multiple = True
        , searchable = \n -> n > 0
        , makeOption = opts.makeOption
        , labelColor = opts.labelColor
        , placeholder = ""
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
    | RemoveItem (Item a)
    | RemoveItem2 (Item a)
    | Filter String
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
            item.option.value

        sel =
            if model.multiple then
                List.filter (\e -> e.option.value /= value) model.selected

            else
                []

        show e =
            if e.option.value == value then
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
            item.option.value

        sel =
            if model.multiple then
                List.concat [ model.selected, [ item ] ]

            else
                [ item ]

        hide e =
            if e.option.value == value then
                { e | selected = True }

            else if model.multiple then
                e

            else
                { e | selected = False }

        avail =
            List.map hide model.available
    in
    { model | selected = sel, available = avail }


filterOptions : String -> List (Item a) -> List (Item a)
filterOptions str list =
    List.map (\e -> { e | visible = Simple.Fuzzy.match str e.option.text, active = False }) list


applyFilter : String -> Model a -> Model a
applyFilter str model =
    let
        selected =
            if str /= "" && not model.multiple then
                []

            else
                model.selected
    in
    { model | filterString = str, available = filterOptions str model.available, selected = selected }


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
            { item2 | active = item1.option.value == item2.option.value }

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
            selectItem model item |> applyFilter ""

        Nothing ->
            model


isDropdownChangeMsg : Msg a -> Bool
isDropdownChangeMsg cm =
    case cm of
        AddItem _ ->
            True

        RemoveItem _ ->
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
                    selectItem model e |> applyFilter ""
            in
            ( { m | menuOpen = False }, Cmd.none )

        RemoveItem e ->
            let
                m =
                    deselectItem model e |> applyFilter ""
            in
            ( -- Setting to True, because parent click sets it to False… ugly
              { m | menuOpen = True }
            , Cmd.none
            )

        RemoveItem2 e ->
            let
                m =
                    deselectItem model e |> applyFilter ""
            in
            ( -- Hack above only needed with semanticui
              m
            , Cmd.none
            )

        Filter str ->
            let
                m =
                    applyFilter str model
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
                        ( model, Cmd.none )

                    else
                        case model.selected of
                            [ e ] ->
                                let
                                    ( m_, c_ ) =
                                        update (RemoveItem e) model
                                in
                                ( { m_ | menuOpen = False }, c_ )

                            _ ->
                                ( model, Cmd.none )

                Just Util.Html.Space ->
                    update ToggleMenu model

                Just Util.Html.Enter ->
                    let
                        m =
                            selectActive model
                    in
                    ( { m | menuOpen = False }, Cmd.none )

                _ ->
                    ( model, Cmd.none )



-- View


view : UiSettings -> Model a -> Html (Msg a)
view settings model =
    if model.multiple then
        viewMultiple settings model

    else
        viewSingle model


viewSingle : Model a -> Html (Msg a)
viewSingle model =
    let
        renderClosed item =
            div
                [ class "message"
                , style "display" "inline-block !important"
                ]
                [ i
                    [ class "delete icon"
                    , onClick (RemoveItem item)
                    ]
                    []
                , text item.option.text
                ]

        renderDefault =
            [ List.head model.selected
                |> Maybe.map renderClosed
                |> Maybe.withDefault (renderPlaceholder model)
            , renderMenu model
            ]

        openSearch =
            [ input
                [ class "search"
                , placeholder "Search…"
                , onInput Filter
                , value model.filterString
                ]
                []
            , renderMenu model
            ]
    in
    div
        (classList
            [ ( "ui search dropdown selection", True )
            , ( "open", model.menuOpen )
            ]
            :: (if model.menuOpen then
                    [ tabindex 0
                    , onKeyUp KeyPress
                    ]

                else
                    [ onClick ToggleMenu
                    , tabindex 0
                    , onKeyUp KeyPress
                    ]
               )
        )
        (List.append
            [ i
                (class "dropdown icon"
                    :: (if model.menuOpen then
                            [ onClick ToggleMenu ]

                        else
                            []
                       )
                )
                []
            ]
         <|
            if model.menuOpen && isSearchable model then
                openSearch

            else
                renderDefault
        )


viewMultiple : UiSettings -> Model a -> Html (Msg a)
viewMultiple settings model =
    let
        renderSelectMultiple : Item a -> Html (Msg a)
        renderSelectMultiple item =
            div
                [ classList
                    [ ( "ui label", True )
                    , ( model.labelColor item.value settings, True )
                    ]
                , style "display" "inline-block !important"
                , onClick (RemoveItem item)
                ]
                [ text item.option.text
                , i [ class "delete icon" ] []
                ]
    in
    div
        [ classList
            [ ( "ui search dropdown multiple selection", True )
            , ( "open", model.menuOpen )
            ]
        , tabindex 0
        , onKeyUp KeyPress
        ]
        (List.concat
            [ [ i [ class "dropdown icon", onClick ToggleMenu ] []
              ]
            , List.map renderSelectMultiple model.selected
            , if isSearchable model then
                [ input
                    [ class "search"
                    , placeholder "Search…"
                    , onInput Filter
                    , value model.filterString
                    ]
                    []
                ]

              else
                []
            , [ renderMenu model
              ]
            ]
        )


renderMenu : Model a -> Html (Msg a)
renderMenu model =
    div
        [ classList
            [ ( "menu", True )
            , ( "transition visible", model.menuOpen )
            ]
        ]
        (getOptions model |> List.map renderOption)


renderPlaceholder : Model a -> Html (Msg a)
renderPlaceholder model =
    div
        [ classList
            [ ( "placeholder-message", True )
            , ( "text", model.multiple )
            ]
        , style "display" "inline-block !important"
        ]
        [ text model.placeholder
        ]


renderOption : Item a -> Html (Msg a)
renderOption item =
    div
        [ classList
            [ ( "item", True )
            , ( "active", item.active || item.selected )
            ]
        , onClick (AddItem item)
        ]
        [ text item.option.text
        , span [ class "small-info right-float" ]
            [ text item.option.additional
            ]
        ]



-- View2


view2 : DS.DropdownStyle -> UiSettings -> Model a -> Html (Msg a)
view2 style settings model =
    if model.multiple then
        viewMultiple2 style settings model

    else
        viewSingle2 style model


viewSingle2 : DS.DropdownStyle -> Model a -> Html (Msg a)
viewSingle2 style model =
    let
        renderItem item =
            a
                [ href "#"
                , class style.item
                , classList
                    [ ( style.itemActive, item.active )
                    , ( "font-semibold", item.selected )
                    ]
                , onClick (AddItem item)
                , onKeyUp KeyPress
                ]
                [ text item.option.text
                , span [ class "text-gray-400 float-right" ]
                    [ text item.option.additional
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
            [ class style.link
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
                [ Maybe.map (.option >> .text) sel
                    |> Maybe.withDefault model.placeholder
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
                , placeholder model.placeholder
                , onInput Filter
                , value model.filterString
                , class "inline-block border-0 px-0 w-full py-0 focus:ring-0 "
                , class style.input
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
            [ class style.menu
            , classList [ ( "hidden", not model.menuOpen ) ]
            ]
            (getOptions model |> List.map renderItem)
        ]


viewMultiple2 : DS.DropdownStyle -> UiSettings -> Model a -> Html (Msg a)
viewMultiple2 style settings model =
    let
        renderItem item =
            a
                [ href "#"
                , class style.item
                , classList
                    [ ( style.itemActive, item.active )
                    , ( "font-semibold", item.selected )
                    ]
                , onClick (AddItem item)
                , onKeyUp KeyPress
                ]
                [ text item.option.text
                , span [ class "text-gray-400 float-right" ]
                    [ text item.option.additional
                    ]
                ]

        renderSelectMultiple : Item a -> Html (Msg a)
        renderSelectMultiple item =
            a
                [ class (model.labelColor item.value settings)
                , class "label font-medium inline-flex relative items-center hover:shadow-md mt-1"
                , onClick (RemoveItem item)
                , href "#"
                ]
                [ span [ class "pl-4" ]
                    [ text item.option.text
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
            [ class style.link
            , class "flex inline-flex flex-wrap items-center"
            ]
            [ div
                [ class "flex flex-row flex-wrap space-x-1 items-center mr-2 -mt-1"
                , classList [ ( "hidden", List.isEmpty model.selected ) ]
                ]
                (List.map renderSelectMultiple model.selected)
            , input
                [ type_ "text"
                , placeholder "Search…"
                , onInput Filter
                , value model.filterString
                , class "inline-flex w-16 border-0 px-0 focus:ring-0 h-6"
                , class style.input
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
            [ class style.menu
            , classList [ ( "hidden", not model.menuOpen ) ]
            ]
            (getOptions model |> List.map renderItem)
        ]
