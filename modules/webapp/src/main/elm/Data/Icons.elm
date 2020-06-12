module Data.Icons exposing
    ( addFiles
    , addFilesIcon
    , concerned
    , concernedIcon
    , correspondent
    , correspondentIcon
    , date
    , dateIcon
    , direction
    , directionIcon
    , dueDate
    , dueDateIcon
    , editNotes
    , editNotesIcon
    , equipment
    , equipmentIcon
    , organization
    , organizationIcon
    , person
    , personIcon
    , tag
    , tagIcon
    , tags
    , tagsIcon
    )

import Html exposing (Html, i)
import Html.Attributes exposing (class)


concerned : String
concerned =
    "crosshairs icon"


concernedIcon : Html msg
concernedIcon =
    i [ class concerned ] []


correspondent : String
correspondent =
    "address card outline icon"


correspondentIcon : Html msg
correspondentIcon =
    i [ class correspondent ] []


date : String
date =
    "calendar outline icon"


dateIcon : String -> Html msg
dateIcon classes =
    i [ class (date ++ " " ++ classes) ] []


dueDate : String
dueDate =
    "bell icon"


dueDateIcon : String -> Html msg
dueDateIcon classes =
    i [ class (dueDate ++ " " ++ classes) ] []


editNotes : String
editNotes =
    "comment alternate outline icon"


editNotesIcon : Html msg
editNotesIcon =
    i [ class editNotes ] []


addFiles : String
addFiles =
    "file plus icon"


addFilesIcon : Html msg
addFilesIcon =
    i [ class addFiles ] []


tag : String
tag =
    "tag icon"


tagIcon : String -> Html msg
tagIcon classes =
    i [ class (tag ++ " " ++ classes) ] []


tags : String
tags =
    "tags icon"


tagsIcon : String -> Html msg
tagsIcon classes =
    i [ class (tags ++ " " ++ classes) ] []


direction : String
direction =
    "exchange icon"


directionIcon : String -> Html msg
directionIcon classes =
    i [ class (direction ++ " " ++ classes) ] []


person : String
person =
    "user icon"


personIcon : String -> Html msg
personIcon classes =
    i [ class (person ++ " " ++ classes) ] []


organization : String
organization =
    "factory icon"


organizationIcon : String -> Html msg
organizationIcon classes =
    i [ class (organization ++ " " ++ classes) ] []


equipment : String
equipment =
    "box icon"


equipmentIcon : String -> Html msg
equipmentIcon classes =
    i [ class (equipment ++ " " ++ classes) ] []
