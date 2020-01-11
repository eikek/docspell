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
    , update
    , view
    )

import Html exposing (..)
import Html.Attributes exposing (..)
import Html.Events exposing (onClick, onInput)
import Simple.Fuzzy
import Util.Html exposing (onKeyUp)
import Util.List


type alias Option =
    { value : String
    , text : String
    }


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
    , selected = False
    , active = False
    }


type alias Model a =
    { multiple : Bool
    , selected : List (Item a)
    , available : List (Item a)
    , makeOption : a -> Option
    , menuOpen : Bool
    , filterString : String
    , labelColor : a -> String
    , searchable : Int -> Bool
    , placeholder : String
    }


makeModel :
    { multiple : Bool
    , searchable : Int -> Bool
    , makeOption : a -> Option
    , labelColor : a -> String
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
        , searchable = \n -> n > 8
        , makeOption = opts.makeOption
        , labelColor = \_ -> ""
        , placeholder = opts.placeholder
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
    , labelColor : a -> String
    }
    -> Model a
makeMultiple opts =
    makeModel
        { multiple = True
        , searchable = \n -> n > 8
        , makeOption = opts.makeOption
        , labelColor = opts.labelColor
        , placeholder = ""
        }


getSelected : Model a -> List a
getSelected model =
    List.map .value model.selected


type Msg a
    = SetOptions (List a)
    | SetSelection (List a)
    | ToggleMenu
    | AddItem (Item a)
    | RemoveItem (Item a)
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
    { model | filterString = str, available = filterOptions str model.available }


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


clearActive : Model a -> Model a
clearActive model =
    { model | available = List.map (\e -> { e | active = False }) model.available }



-- TODO enhance update function to return this info


isDropdownChangeMsg : Msg a -> Bool
isDropdownChangeMsg cm =
    case cm of
        AddItem _ ->
            True

        RemoveItem _ ->
            True

        KeyPress code ->
            Util.Html.intToKeyCode code
                |> Maybe.map (\c -> c == Util.Html.Enter)
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
            ( { m | menuOpen = False }, Cmd.none )

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

                Just Util.Html.Down ->
                    ( makeNextActive ((+) 1) model, Cmd.none )

                Just Util.Html.Enter ->
                    let
                        m =
                            selectActive model
                    in
                    ( { m | menuOpen = False }, Cmd.none )

                _ ->
                    ( model, Cmd.none )



-- View


view : Model a -> Html (Msg a)
view model =
    if model.multiple then
        viewMultiple model

    else
        viewSingle model


viewSingle : Model a -> Html (Msg a)
viewSingle model =
    let
        renderClosed item =
            div
                [ class "message"
                , style "display" "inline-block !important"
                , onClick ToggleMenu
                ]
                [ i [ class "delete icon", onClick (RemoveItem item) ] []
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
                , onKeyUp KeyPress
                , value model.filterString
                ]
                []
            , renderMenu model
            ]
    in
    div
        [ classList
            [ ( "ui search dropdown selection", True )
            , ( "open", model.menuOpen )
            ]
        ]
        (List.append
            [ i [ class "dropdown icon", onClick ToggleMenu ] []
            ]
         <|
            if model.menuOpen && isSearchable model then
                openSearch

            else
                renderDefault
        )


viewMultiple : Model a -> Html (Msg a)
viewMultiple model =
    let
        renderSelectMultiple : Item a -> Html (Msg a)
        renderSelectMultiple item =
            div
                [ classList
                    [ ( "ui label", True )
                    , ( model.labelColor item.value, True )
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
                    , onKeyUp KeyPress
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
        , onClick ToggleMenu
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
        ]
