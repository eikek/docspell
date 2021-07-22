{-
  Copyright 2020 Docspell Contributors

  SPDX-License-Identifier: GPL-3.0-or-later
-}

module Data.Icons exposing
    ( addFiles
    , addFiles2
    , addFilesIcon
    , addFilesIcon2
    , concerned
    , concerned2
    , concernedIcon
    , concernedIcon2
    , correspondent
    , correspondent2
    , correspondentIcon
    , correspondentIcon2
    , customField
    , customField2
    , customFieldIcon
    , customFieldIcon2
    , customFieldType
    , customFieldType2
    , customFieldTypeIcon
    , customFieldTypeIconString
    , customFieldTypeIconString2
    , date
    , date2
    , dateIcon
    , dateIcon2
    , direction
    , direction2
    , directionIcon
    , directionIcon2
    , dueDate
    , dueDate2
    , dueDateIcon
    , dueDateIcon2
    , editNotes
    , editNotesIcon
    , equipment
    , equipment2
    , equipmentIcon
    , equipmentIcon2
    , folder
    , folder2
    , folderIcon
    , folderIcon2
    , itemDatesIcon
    , organization
    , organization2
    , organizationIcon
    , organizationIcon2
    , person
    , person2
    , personIcon
    , personIcon2
    , search
    , searchIcon
    , source
    , source2
    , sourceIcon
    , sourceIcon2
    , tag
    , tag2
    , tagIcon
    , tagIcon2
    , tags
    , tags2
    , tagsIcon
    , tagsIcon2
    )

import Data.CustomFieldType exposing (CustomFieldType)
import Html exposing (Html, i)
import Html.Attributes exposing (class)


source : String
source =
    "upload icon"


source2 : String
source2 =
    "fa fa-upload"


sourceIcon : String -> Html msg
sourceIcon classes =
    i [ class (source ++ " " ++ classes) ] []


sourceIcon2 : String -> Html msg
sourceIcon2 classes =
    i [ class (source2 ++ " " ++ classes) ] []


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


customFieldType2 : CustomFieldType -> String
customFieldType2 ftype =
    case ftype of
        Data.CustomFieldType.Text ->
            "fa fa-stream"

        Data.CustomFieldType.Numeric ->
            "fa fa-hashtag"

        Data.CustomFieldType.Date ->
            "fa fa-calendar"

        Data.CustomFieldType.Boolean ->
            "fa fa-marker"

        Data.CustomFieldType.Money ->
            "fa fa-money-bill"


customFieldTypeIcon : String -> CustomFieldType -> Html msg
customFieldTypeIcon classes ftype =
    i [ class (customFieldType ftype ++ " " ++ classes) ]
        []


customFieldTypeIcon2 : String -> CustomFieldType -> Html msg
customFieldTypeIcon2 classes ftype =
    i [ class (customFieldType2 ftype ++ " " ++ classes) ]
        []


customFieldTypeIconString : String -> String -> Html msg
customFieldTypeIconString classes ftype =
    Data.CustomFieldType.fromString ftype
        |> Maybe.map (customFieldTypeIcon classes)
        |> Maybe.withDefault (i [ class "question circle outline icon" ] [])


customFieldTypeIconString2 : String -> String -> Html msg
customFieldTypeIconString2 classes ftype =
    Data.CustomFieldType.fromString ftype
        |> Maybe.map (customFieldTypeIcon2 classes)
        |> Maybe.withDefault (i [ class "question circle outline icon" ] [])


customField : String
customField =
    "highlighter icon"


customField2 : String
customField2 =
    "fa fa-highlighter"


customFieldIcon : String -> Html msg
customFieldIcon classes =
    i [ class (customField ++ " " ++ classes) ] []


customFieldIcon2 : String -> Html msg
customFieldIcon2 classes =
    i [ class (customField2 ++ " " ++ classes) ] []


search : String
search =
    "search icon"


searchIcon : String -> Html msg
searchIcon classes =
    i [ class (search ++ " " ++ classes) ] []


folder : String
folder =
    "folder outline icon"


folder2 : String
folder2 =
    "fa fa-folder font-thin "


folderIcon : String -> Html msg
folderIcon classes =
    i [ class (folder ++ " " ++ classes) ] []


folderIcon2 : String -> Html msg
folderIcon2 classes =
    i [ class (folder2 ++ " " ++ classes) ] []


concerned : String
concerned =
    "crosshairs icon"


concernedIcon : Html msg
concernedIcon =
    i [ class concerned ] []


concerned2 : String
concerned2 =
    "fa fa-crosshairs"


concernedIcon2 : String -> Html msg
concernedIcon2 classes =
    i
        [ class concerned2
        , class classes
        ]
        []


correspondent : String
correspondent =
    "address card outline icon"


correspondentIcon : String -> Html msg
correspondentIcon classes =
    i [ class (correspondent ++ " " ++ classes) ] []


correspondent2 : String
correspondent2 =
    "fa fa-address-card font-thin"


correspondentIcon2 : String -> Html msg
correspondentIcon2 classes =
    i [ class (correspondent2 ++ " " ++ classes) ] []


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


date2 : String
date2 =
    "fa fa-calendar font-thin"


dateIcon2 : String -> Html msg
dateIcon2 classes =
    i [ class (date2 ++ " " ++ classes) ] []


dueDate : String
dueDate =
    "bell icon"


dueDateIcon : String -> Html msg
dueDateIcon classes =
    i [ class (dueDate ++ " " ++ classes) ] []


dueDate2 : String
dueDate2 =
    "fa fa-bell"


dueDateIcon2 : String -> Html msg
dueDateIcon2 classes =
    i [ class (dueDate2 ++ " " ++ classes) ] []


editNotes : String
editNotes =
    "comment alternate outline icon"


editNotesIcon : Html msg
editNotesIcon =
    i [ class editNotes ] []


addFiles : String
addFiles =
    "file plus icon"


addFiles2 : String
addFiles2 =
    "fa fa-file-upload"


addFilesIcon : Html msg
addFilesIcon =
    i [ class addFiles ] []


addFilesIcon2 : String -> Html msg
addFilesIcon2 classes =
    i [ class addFiles2, class classes ] []


tag : String
tag =
    "tag icon"


tag2 : String
tag2 =
    "fa fa-tag"


tagIcon : String -> Html msg
tagIcon classes =
    i [ class (tag ++ " " ++ classes) ] []


tagIcon2 : String -> Html msg
tagIcon2 classes =
    i [ class (tag2 ++ " " ++ classes) ] []


tags : String
tags =
    "tags icon"


tagsIcon : String -> Html msg
tagsIcon classes =
    i [ class (tags ++ " " ++ classes) ] []


tags2 : String
tags2 =
    "fa fa-tags"


tagsIcon2 : String -> Html msg
tagsIcon2 classes =
    i [ class (tags2 ++ " " ++ classes) ] []


direction : String
direction =
    "exchange icon"


directionIcon : String -> Html msg
directionIcon classes =
    i [ class (direction ++ " " ++ classes) ] []


direction2 : String
direction2 =
    "fa fa-exchange-alt"


directionIcon2 : String -> Html msg
directionIcon2 classes =
    i [ class (direction2 ++ " " ++ classes) ] []


person : String
person =
    "user icon"


person2 : String
person2 =
    "fa fa-user"


personIcon : String -> Html msg
personIcon classes =
    i [ class (person ++ " " ++ classes) ] []


personIcon2 : String -> Html msg
personIcon2 classes =
    i [ class (person2 ++ " " ++ classes) ] []


organization : String
organization =
    "factory icon"


organization2 : String
organization2 =
    "fa fa-industry"


organizationIcon : String -> Html msg
organizationIcon classes =
    i [ class (organization ++ " " ++ classes) ] []


organizationIcon2 : String -> Html msg
organizationIcon2 classes =
    i [ class (organization2 ++ " " ++ classes) ] []


equipment : String
equipment =
    "box icon"


equipment2 : String
equipment2 =
    "fa fa-box"


equipmentIcon : String -> Html msg
equipmentIcon classes =
    i [ class (equipment ++ " " ++ classes) ] []


equipmentIcon2 : String -> Html msg
equipmentIcon2 classes =
    i [ class (equipment2 ++ " " ++ classes) ] []
