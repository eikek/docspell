module ExtraAttr exposing (..)

import Html exposing (..)
import Html.Attributes exposing (..)


ariaExpanded : Bool -> Attribute msg
ariaExpanded flag =
    attribute "aria-expanded"
        (if flag then
            "true"

         else
            "false"
        )


ariaHidden : Bool -> Attribute msg
ariaHidden flag =
    attribute "aria-hidden"
        (if flag then
            "true"

         else
            "false"
        )


ariaLabel : String -> Attribute msg
ariaLabel name =
    attribute "aria-label" name


role : String -> Attribute msg
role name =
    attribute "role" name
