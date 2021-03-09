module Comp.FixedDropdown exposing
    ( Item
    , Model
    , Msg
    , init
    , initMap
    , initString
    , initTuple
    , update
    , view2
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
    , display : String
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


init : List (Item a) -> Model a
init options =
    { options = options
    , menuOpen = False
    , selected = Nothing
    }


initString : List String -> Model String
initString strings =
    init <| List.map (\s -> Item s s) strings


initMap : (a -> String) -> List a -> Model a
initMap elToString els =
    init <| List.map (\a -> Item a (elToString a)) els


initTuple : List ( String, a ) -> Model a
initTuple tuples =
    let
        mkItem ( txt, id ) =
            Item id txt
    in
    init <| List.map mkItem tuples


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


viewStyled2 : DS.DropdownStyle -> Bool -> Maybe (Item a) -> Model a -> Html (Msg a)
viewStyled2 style error sel model =
    let
        renderItem item =
            a
                [ href "#"
                , class style.item
                , classList
                    [ ( style.itemActive, isSelected model item )
                    , ( "font-semibold", Just item == sel )
                    ]
                , onClick (SelectItem2 item)
                ]
                [ text item.display
                ]
    in
    div
        [ class ("relative " ++ style.root)
        , onKeyUpCode KeyPress
        ]
        [ a
            [ class style.link
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
                [ Maybe.map .display sel
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
            [ class style.menu
            , classList [ ( "hidden", not model.menuOpen ) ]
            ]
            (List.map renderItem model.options)
        ]


view2 : Maybe (Item a) -> Model a -> Html (Msg a)
view2 =
    viewStyled2 DS.mainStyle False
