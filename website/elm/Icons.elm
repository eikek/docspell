module Icons exposing (..)

import Html exposing (..)
import Html.Attributes exposing (..)


copyright : Html msg
copyright =
    img [ src "icons/copyright-40.svg" ] []


infoSquared : Html msg
infoSquared =
    img [ src "icons/info-square-40.svg" ] []


refresh : Html msg
refresh =
    img [ src "icons/refresh-40.svg" ] []


logo : Html msg
logo =
    img [ src "icons/logo-only.svg" ] []


logoMC : Html msg
logoMC =
    img [ src "icons/logo-only-mc.svg" ] []


logoWidth : Int -> Html msg
logoWidth w =
    img [ src "icons/logo-only.svg", width w ] []


home : Html msg
home =
    img [ src "icons/home-40.svg" ] []


docs : Html msg
docs =
    img [ src "icons/notes-40.svg" ] []


github : Html msg
github =
    img [ src "/icons/github-40.svg" ] []


githubGreen : Html msg
githubGreen =
    img [ src "/icons/github-40-green.svg" ] []
