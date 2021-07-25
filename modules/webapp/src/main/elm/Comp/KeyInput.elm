{-
   Copyright 2020 Docspell Contributors

   SPDX-License-Identifier: GPL-3.0-or-later
-}


module Comp.KeyInput exposing
    ( KeyInput
    , Model
    , Msg
    , ctrlC
    , ctrlComma
    , ctrlN
    , ctrlPoint
    , ctrlU
    , events
    , eventsM
    , init
    , update
    )

import Html exposing (Attribute)
import Html.Attributes
import Util.Html exposing (KeyCode(..))


type alias KeyInput =
    { down : List KeyCode
    , up : KeyCode
    }


ctrlPlus : KeyCode -> KeyInput
ctrlPlus code =
    { down = [ Ctrl ]
    , up = code
    }


ctrlN : KeyInput
ctrlN =
    ctrlPlus Letter_N


ctrlC : KeyInput
ctrlC =
    ctrlPlus Letter_C


ctrlU : KeyInput
ctrlU =
    ctrlPlus Letter_U


ctrlPoint : KeyInput
ctrlPoint =
    ctrlPlus Point


ctrlComma : KeyInput
ctrlComma =
    ctrlPlus Comma


type alias Model =
    List KeyCode


init : Model
init =
    []


type Msg
    = KeyDown (Maybe KeyCode)
    | KeyUp (Maybe KeyCode)


events : List (Attribute Msg)
events =
    [ Util.Html.onKeyUpCode KeyUp
    , Util.Html.onKeyDownCode KeyDown
    ]


eventsM : (Msg -> msg) -> List (Attribute msg)
eventsM tagger =
    List.map (Html.Attributes.map tagger) events


update : Msg -> Model -> ( Model, Maybe KeyInput )
update msg model =
    case msg of
        KeyDown (Just code) ->
            ( insert code model, Nothing )

        KeyUp (Just code) ->
            let
                m_ =
                    remove code model
            in
            ( m_, Just <| KeyInput m_ code )

        KeyDown Nothing ->
            ( model, Nothing )

        KeyUp Nothing ->
            ( model, Nothing )


insert : a -> List a -> List a
insert el list =
    if List.member el list then
        list

    else
        el :: list


remove : a -> List a -> List a
remove el list =
    List.filter (\e -> e /= el) list
