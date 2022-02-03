module Icons exposing (..)

import Html exposing (..)
import Html.Attributes exposing (..)


copyright : Html msg
copyright =
    i [ class "fa fa-copyright font-thin" ] []


infoSquared : Html msg
infoSquared =
    img [ src "icons/info-square-40.svg" ] []


refresh : Html msg
refresh =
    img [ src "icons/refresh-40.svg" ] []


logo : Html msg
logo =
    img [ src "icons/logo-only-36.svg" ] []


logoMC : Html msg
logoMC =
    img [ src "icons/logo-only-mc.svg" ] []


logoWidth : Int -> Html msg
logoWidth w =
    img [ src "icons/logo-only.svg", width w ] []


home : Html msg
home =
    i [ class "fa fa-home" ] []


docs : Html msg
docs =
    i [ class "fa fa-book" ] []


github : Html msg
github =
    i [ class "fab fa-github-alt" ] []


githubGreen : Html msg
githubGreen =
    img [ src "/icons/github-40-green.svg" ] []


blog : Html msg
blog =
    i [ class "fa fa-blog" ] []
