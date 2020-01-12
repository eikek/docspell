module Util.Html exposing
    ( KeyCode(..)
    , classActive
    , intToKeyCode
    , onClickk
    , onKeyUp
    )

import Html exposing (Attribute)
import Html.Attributes exposing (class)
import Html.Events exposing (keyCode, on)
import Json.Decode as Decode


type KeyCode
    = Up
    | Down
    | Left
    | Right
    | Enter
    | Space


intToKeyCode : Int -> Maybe KeyCode
intToKeyCode code =
    case code of
        38 ->
            Just Up

        40 ->
            Just Down

        39 ->
            Just Right

        37 ->
            Just Left

        13 ->
            Just Enter

        32 ->
            Just Space

        _ ->
            Nothing


onKeyUp : (Int -> msg) -> Attribute msg
onKeyUp tagger =
    on "keyup" (Decode.map tagger keyCode)


onClickk : msg -> Attribute msg
onClickk msg =
    Html.Events.preventDefaultOn "click" (Decode.map alwaysPreventDefault (Decode.succeed msg))


alwaysPreventDefault : msg -> ( msg, Bool )
alwaysPreventDefault msg =
    ( msg, True )


classActive : Bool -> String -> Attribute msg
classActive active classes =
    class
        (classes
            ++ (if active then
                    " active"

                else
                    ""
               )
        )
