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


dateIcon : Html msg
dateIcon =
    i [ class date ] []


dueDate : String
dueDate =
    "bell icon"


dueDateIcon : Html msg
dueDateIcon =
    i [ class dueDate ] []


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


tagIcon : Html msg
tagIcon =
    i [ class tag ] []


tags : String
tags =
    "tags icon"


tagsIcon : Html msg
tagsIcon =
    i [ class tags ] []


direction : String
direction =
    "exchange icon"


directionIcon : Html msg
directionIcon =
    i [ class direction ] []


person : String
person =
    "user icon"


personIcon : Html msg
personIcon =
    i [ class person ] []


organization : String
organization =
    "factory icon"


organizationIcon : Html msg
organizationIcon =
    i [ class organization ] []


equipment : String
equipment =
    "box icon"


equipmentIcon : Html msg
equipmentIcon =
    i [ class equipment ] []
