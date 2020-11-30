module Data.Icons exposing
    ( addFiles
    , addFilesIcon
    , concerned
    , concernedIcon
    , correspondent
    , correspondentIcon
    , customField
    , customFieldIcon
    , customFieldType
    , customFieldTypeIcon
    , customFieldTypeIconString
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
    , folder
    , folderIcon
    , itemDatesIcon
    , organization
    , organizationIcon
    , person
    , personIcon
    , search
    , searchIcon
    , source
    , sourceIcon
    , tag
    , tagIcon
    , tags
    , tagsIcon
    )

import Data.CustomFieldType exposing (CustomFieldType)
import Html exposing (Html, i)
import Html.Attributes exposing (class)


source : String
source =
    "upload icon"


sourceIcon : String -> Html msg
sourceIcon classes =
    i [ class (source ++ " " ++ classes) ] []


customFieldType : CustomFieldType -> String
customFieldType ftype =
    case ftype of
        Data.CustomFieldType.Text ->
            "stream icon"

        Data.CustomFieldType.Numeric ->
            "hashtag icon"

        Data.CustomFieldType.Date ->
            "calendar icon"

        Data.CustomFieldType.Boolean ->
            "marker icon"

        Data.CustomFieldType.Money ->
            "money bill icon"


customFieldTypeIcon : String -> CustomFieldType -> Html msg
customFieldTypeIcon classes ftype =
    i [ class (customFieldType ftype ++ " " ++ classes) ]
        []


customFieldTypeIconString : String -> String -> Html msg
customFieldTypeIconString classes ftype =
    Data.CustomFieldType.fromString ftype
        |> Maybe.map (customFieldTypeIcon classes)
        |> Maybe.withDefault (i [ class "question circle outline icon" ] [])


customField : String
customField =
    "highlighter icon"


customFieldIcon : String -> Html msg
customFieldIcon classes =
    i [ class (customField ++ " " ++ classes) ] []


search : String
search =
    "search icon"


searchIcon : String -> Html msg
searchIcon classes =
    i [ class (search ++ " " ++ classes) ] []


folder : String
folder =
    "folder outline icon"


folderIcon : String -> Html msg
folderIcon classes =
    i [ class (folder ++ " " ++ classes) ] []


concerned : String
concerned =
    "crosshairs icon"


concernedIcon : Html msg
concernedIcon =
    i [ class concerned ] []


correspondent : String
correspondent =
    "address card outline icon"


correspondentIcon : String -> Html msg
correspondentIcon classes =
    i [ class (correspondent ++ " " ++ classes) ] []


itemDates : String
itemDates =
    "calendar alternate outline icon"


itemDatesIcon : String -> Html msg
itemDatesIcon classes =
    i
        [ class classes
        , class itemDates
        ]
        []


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
