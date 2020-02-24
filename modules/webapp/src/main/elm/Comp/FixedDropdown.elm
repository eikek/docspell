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
    )

import Html exposing (..)
import Html.Attributes exposing (..)
import Html.Events exposing (onClick)


type alias Item a =
    { id : a
    , display : String
    }


type alias Model a =
    { options : List (Item a)
    , menuOpen : Bool
    }


type Msg a
    = SelectItem (Item a)
    | ToggleMenu


init : List (Item a) -> Model a
init options =
    { options = options
    , menuOpen = False
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


update : Msg a -> Model a -> ( Model a, Maybe a )
update msg model =
    case msg of
        ToggleMenu ->
            ( { model | menuOpen = not model.menuOpen }, Nothing )

        SelectItem item ->
            ( model, Just item.id )


view : Maybe (Item a) -> Model a -> Html (Msg a)
view selected model =
    div
        [ classList
            [ ( "ui selection dropdown", True )
            , ( "open", model.menuOpen )
            ]
        , onClick ToggleMenu
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
            List.map renderItems model.options
        ]


renderItems : Item a -> Html (Msg a)
renderItems item =
    div [ class "item", onClick (SelectItem item) ]
        [ text item.display
        ]
