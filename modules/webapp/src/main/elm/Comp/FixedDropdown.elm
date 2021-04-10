module Comp.FixedDropdown exposing
    ( Item
    , Model
    , Msg
    , ViewSettings
    , init
    , update
    , viewStyled2
    )

import Data.DropdownStyle as DS
import Html exposing (..)
import Html.Attributes exposing (..)
import Html.Events exposing (onClick)
import Styles as S
import Util.Html exposing (KeyCode(..), onKeyUpCode)
import Util.List


type alias Item a =
    { id : a
    }


type alias Model a =
    { options : List (Item a)
    , menuOpen : Bool
    , selected : Maybe a
    }


type Msg a
    = SelectItem2 (Item a)
    | ToggleMenu
    | KeyPress (Maybe KeyCode)


initItems : List (Item a) -> Model a
initItems options =
    { options = options
    , menuOpen = False
    , selected = Nothing
    }


init : List a -> Model a
init els =
    List.map Item els |> initItems


isSelected : Model a -> Item a -> Bool
isSelected model item =
    model.selected == Just item.id


movePrevious : Model a -> ( Model a, Maybe a )
movePrevious model =
    let
        prev =
            Util.List.findPrev (isSelected model) model.options
    in
    case prev of
        Just p ->
            ( { model | selected = Just p.id, menuOpen = True }, Nothing )

        Nothing ->
            ( { model
                | selected =
                    List.reverse model.options
                        |> List.head
                        |> Maybe.map .id
                , menuOpen = True
              }
            , Nothing
            )


moveNext : Model a -> ( Model a, Maybe a )
moveNext model =
    let
        next =
            Util.List.findNext (isSelected model) model.options
    in
    case next of
        Just n ->
            ( { model | selected = Just n.id, menuOpen = True }, Nothing )

        Nothing ->
            ( { model
                | selected =
                    List.head model.options
                        |> Maybe.map .id
                , menuOpen = True
              }
            , Nothing
            )


update : Msg a -> Model a -> ( Model a, Maybe a )
update msg model =
    case msg of
        ToggleMenu ->
            ( { model | menuOpen = not model.menuOpen }, Nothing )

        SelectItem2 item ->
            ( { model | menuOpen = False }, Just item.id )

        KeyPress (Just Space) ->
            update ToggleMenu model

        KeyPress (Just Enter) ->
            let
                selected =
                    Util.List.find (isSelected model) model.options
            in
            case selected of
                Just i ->
                    ( { model | menuOpen = False }, Just i.id )

                Nothing ->
                    ( model, Nothing )

        KeyPress (Just Up) ->
            movePrevious model

        KeyPress (Just Letter_P) ->
            movePrevious model

        KeyPress (Just Letter_K) ->
            movePrevious model

        KeyPress (Just Down) ->
            moveNext model

        KeyPress (Just Letter_N) ->
            moveNext model

        KeyPress (Just Letter_J) ->
            moveNext model

        KeyPress (Just ESC) ->
            ( { model | menuOpen = False }, Nothing )

        KeyPress _ ->
            ( model, Nothing )



--- View2


type alias ViewSettings a =
    { display : a -> String
    , icon : a -> Maybe String
    , style : DS.DropdownStyle
    }


viewStyled2 : ViewSettings a -> Bool -> Maybe a -> Model a -> Html (Msg a)
viewStyled2 cfg error sel model =
    let
        iconItem id =
            span
                [ classList [ ( "hidden", cfg.icon id == Nothing ) ]
                , class (Maybe.withDefault "" (cfg.icon id))
                , class "mr-2"
                ]
                []

        renderItem item =
            a
                [ href "#"
                , class cfg.style.item
                , classList
                    [ ( cfg.style.itemActive, isSelected model item )
                    , ( "font-semibold", Just item.id == sel )
                    ]
                , onClick (SelectItem2 item)
                ]
                [ iconItem item.id
                , text (cfg.display item.id)
                ]

        selIcon =
            Maybe.map iconItem sel
                |> Maybe.withDefault (span [ class "hidden" ] [])
    in
    div
        [ class ("relative " ++ cfg.style.root)
        , onKeyUpCode KeyPress
        ]
        [ a
            [ class cfg.style.link
            , classList [ ( S.inputErrorBorder, error ) ]
            , tabindex 0
            , onClick ToggleMenu
            , href "#"
            ]
            [ div
                [ class "flex-grow"
                , classList
                    [ ( "opacity-50", sel == Nothing )
                    ]
                ]
                [ selIcon
                , Maybe.map cfg.display sel
                    |> Maybe.withDefault "Select…"
                    |> text
                ]
            , div
                [ class "rounded cursor-pointer ml-2 absolute right-2"
                ]
                [ i [ class "fa fa-angle-down px-2" ] []
                ]
            ]
        , div
            [ class cfg.style.menu
            , classList [ ( "hidden", not model.menuOpen ) ]
            ]
            (List.map renderItem model.options)
        ]
