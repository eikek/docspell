module Comp.FixedDropdown exposing
    ( Item
    , Model
    , Msg
    , init
    , initMap
    , initString
    , initTuple
    , update
    , view
    , viewString
    , viewStyled
    )

import Html exposing (..)
import Html.Attributes exposing (..)
import Html.Events exposing (onClick)
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
    = SelectItem (Item a)
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

        SelectItem item ->
            ( model, Just item.id )

        KeyPress (Just Space) ->
            update ToggleMenu model

        KeyPress (Just Enter) ->
            if not model.menuOpen then
                update ToggleMenu model

            else
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


viewStyled : String -> Maybe (Item a) -> Model a -> Html (Msg a)
viewStyled classes selected model =
    div
        [ classList
            [ ( "ui selection dropdown", True )
            , ( classes, True )
            , ( "open", model.menuOpen )
            ]
        , tabindex 0
        , onClick ToggleMenu
        , onKeyUpCode KeyPress
        ]
        [ input [ type_ "hidden" ] []
        , i [ class "dropdown icon" ] []
        , div
            [ classList
                [ ( "default", selected == Nothing )
                , ( "text", True )
                ]
            ]
            [ Maybe.map .display selected
                |> Maybe.withDefault "Select…"
                |> text
            ]
        , div
            [ classList
                [ ( "menu transition", True )
                , ( "hidden", not model.menuOpen )
                , ( "visible", model.menuOpen )
                ]
            ]
          <|
            List.map (renderItems model) model.options
        ]


view : Maybe (Item a) -> Model a -> Html (Msg a)
view selected model =
    viewStyled "" selected model


viewString : Maybe String -> Model String -> Html (Msg String)
viewString selected model =
    view (Maybe.map (\s -> Item s s) selected) model


renderItems : Model a -> Item a -> Html (Msg a)
renderItems model item =
    div
        [ classList
            [ ( "item", True )
            , ( "selected", isSelected model item )
            ]
        , onClick (SelectItem item)
        ]
        [ text item.display
        ]
