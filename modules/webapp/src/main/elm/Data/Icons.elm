{-
   Copyright 2020 Eike K. & Contributors

   SPDX-License-Identifier: AGPL-3.0-or-later
-}


module Data.Icons exposing
    ( addFiles2
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
    , dashboardIcon
    , date
    , date2
    , dateIcon
    , dateIcon2
    , direction
    , direction2
    , directionIcon
    , directionIcon2
    , documentationIcon
    , dueDate
    , dueDate2
    , dueDateIcon
    , dueDateIcon2
    , editIcon
    , equipment
    , equipmentIcon
    , fileUploadIcon
    , folder
    , folderIcon
    , gotifyIcon
    , itemDatesIcon
    , linkItems
    , matrixIcon
    , metadata
    , metadataIcon
    , notificationHooks
    , notificationHooksIcon
    , organization
    , organizationIcon
    , periodicTasks
    , periodicTasksIcon
    , person
    , personIcon
    , search
    , searchIcon
    , share
    , shareIcon
    , showQr
    , showQrIcon
    , source2
    , sourceIcon2
    , tag
    , tagIcon
    , tags
    , tagsIcon
    , trash
    , trashIcon
    )

import Data.CustomFieldType exposing (CustomFieldType)
import Html exposing (Html, i, img)
import Html.Attributes exposing (class, src)
import Svg
import Svg.Attributes as SA


documentation : String
documentation =
    "fa fa-question-circle"


documentationIcon : String -> Html msg
documentationIcon classes =
    i [ class classes, class documentation ] []


dashboard : String
dashboard =
    "fa fa-house-user"


dashboardIcon : String -> Html msg
dashboardIcon classes =
    i [ class classes, class dashboard ] []


periodicTasks : String
periodicTasks =
    "fa fa-history"


periodicTasksIcon : String -> Html msg
periodicTasksIcon classes =
    i [ class classes, class periodicTasks ] []


notificationHooks : String
notificationHooks =
    "fa fa-comment font-thin"


notificationHooksIcon : String -> Html msg
notificationHooksIcon classes =
    i [ class classes, class notificationHooks ] []


metadata : String
metadata =
    "fa fa-cubes"


metadataIcon : String -> Html msg
metadataIcon classes =
    i [ class classes, class metadata ] []


trash : String
trash =
    "fa fa-trash-alt text-red-500 dark:text-orange-600"


trashIcon : String -> Html msg
trashIcon classes =
    i
        [ class classes
        , class trash
        ]
        []


share : String
share =
    "fa fa-share-alt"


linkItems : String
linkItems =
    "fa fa-link"


shareIcon : String -> Html msg
shareIcon classes =
    i [ class (classes ++ " " ++ share) ] []


source2 : String
source2 =
    "fa fa-upload"


fileUpload : String
fileUpload =
    "fa fa-file-upload"


fileUploadIcon : String -> Html msg
fileUploadIcon classes =
    i [ class classes, class fileUpload ] []


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
    "fa fa-search"


searchIcon : String -> Html msg
searchIcon classes =
    i [ class (search ++ " " ++ classes) ] []


folder : String
folder =
    "fa fa-folder font-thin "


folderIcon : String -> Html msg
folderIcon classes =
    i [ class (folder ++ " " ++ classes) ] []


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


edit : String
edit =
    "fa fa-edit font-thin"


editIcon : String -> Html msg
editIcon classes =
    i [ class edit, class classes ] []


addFiles2 : String
addFiles2 =
    "fa fa-file-upload"


addFilesIcon2 : String -> Html msg
addFilesIcon2 classes =
    i [ class addFiles2, class classes ] []


showQr : String
showQr =
    "fa fa-qrcode"


showQrIcon : String -> Html msg
showQrIcon classes =
    i [ class showQr, class classes ] []


tag : String
tag =
    "fa fa-tag"


tagIcon : String -> Html msg
tagIcon classes =
    i [ class (tag ++ " " ++ classes) ] []


tags : String
tags =
    "fa fa-tags"


tagsIcon : String -> Html msg
tagsIcon classes =
    i [ class (tags ++ " " ++ classes) ] []


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
    "fa fa-user"


personIcon : String -> Html msg
personIcon classes =
    i [ class (person ++ " " ++ classes) ] []


organization : String
organization =
    "fa fa-industry"


organizationIcon : String -> Html msg
organizationIcon classes =
    i [ class (organization ++ " " ++ classes) ] []


equipment : String
equipment =
    "fa fa-box"


equipmentIcon : String -> Html msg
equipmentIcon classes =
    i [ class (equipment ++ " " ++ classes) ] []


matrixIcon : String -> Html msg
matrixIcon classes =
    Svg.svg
        [ SA.width "520"
        , SA.height "520"
        , SA.viewBox "0 0 520 520"
        , SA.class classes
        ]
        [ Svg.path
            [ SA.d "M13.7,11.9v496.2h35.7V520H0V0h49.4v11.9H13.7z" ]
            []
        , Svg.path
            [ SA.d "M166.3,169.2v25.1h0.7c6.7-9.6,14.8-17,24.2-22.2c9.4-5.3,20.3-7.9,32.5-7.9c11.7,0,22.4,2.3,32.1,6.8\n\tc9.7,4.5,17,12.6,22.1,24c5.5-8.1,13-15.3,22.4-21.5c9.4-6.2,20.6-9.3,33.5-9.3c9.8,0,18.9,1.2,27.3,3.6c8.4,2.4,15.5,6.2,21.5,11.5\n\tc6,5.3,10.6,12.1,14,20.6c3.3,8.5,5,18.7,5,30.7v124.1h-50.9V249.6c0-6.2-0.2-12.1-0.7-17.6c-0.5-5.5-1.8-10.3-3.9-14.3\n\tc-2.2-4.1-5.3-7.3-9.5-9.7c-4.2-2.4-9.9-3.6-17-3.6c-7.2,0-13,1.4-17.4,4.1c-4.4,2.8-7.9,6.3-10.4,10.8c-2.5,4.4-4.2,9.4-5,15.1\n\tc-0.8,5.6-1.3,11.3-1.3,17v103.3h-50.9v-104c0-5.5-0.1-10.9-0.4-16.3c-0.2-5.4-1.3-10.3-3.1-14.9c-1.8-4.5-4.8-8.2-9-10.9\n\tc-4.2-2.7-10.3-4.1-18.5-4.1c-2.4,0-5.6,0.5-9.5,1.6c-3.9,1.1-7.8,3.1-11.5,6.1c-3.7,3-6.9,7.3-9.5,12.9c-2.6,5.6-3.9,13-3.9,22.1\n\tv107.6h-50.9V169.2H166.3z" ]
            []
        , Svg.path
            [ SA.d "M506.3,508.1V11.9h-35.7V0H520v520h-49.4v-11.9H506.3z" ]
            []
        ]


gotifyIcon : String -> Html msg
gotifyIcon classes =
    img
        [ class classes
        , src "data:image/png;base64,iVBORw0KGgoAAAANSUhEUgAAABAAAAAQCAYAAAAf8/9hAAAC80lEQVQ4y32SW0iTYRjHh7WL6K4gCKILbwQzJeomQcKLKEtJvAo0M8vDPG+WFlagaKgdzYgiUYRSUuzCwMN0NtOJ29xJN+fUj3nKedhe9+mOmvv3ft+FZlkPPHwvfO//x/P8379AQOtUXOL70/HJjcFRl4tDr14vC7mY8PDEmchbh48eO0t/HxT8ry6IK9pEvQwKtRsoGvOj2LjJ9z29G9nyOcS/aB49HnYu+Z+AYtOWlxOL1WsQqwj/LRhZR46aRb7WhfsTARSOsAhPSKndF0BFDl7INb2Y8d2Gwi4jnkh1KO3WI0s6BbHOTaEsYlJzW6Iiz6fsD6AXRDIrWgd1WHPYgZ+b2PZ5oDNPIr/TiDydBw8G5+Ega4iLjb37FyBTsYJ6uQZAAH+WTGNEunwBaQPL+GZZgLxX6qfSkF3AiBOiHgYW69yOKBAIQKlUYnFxERssCwldK0vrQc3ABOaYSa9QKDy5A+D2y5Va8GNpeQfg8/kQHR2N+vp6StvGI/kUbraPQ1z+ElVV1eagoKBDuxOoncjotUJnYfaMbrVaQQjB8qodonY9nja8Q93rUlQ+zrQJhQeO7PEgW7mG8i4NNXB1D8TvdqFGpkdquwHyr69gGapD3p1rTX+ZKKHvnzVkR1GHHh8HDejUmvF52IiS7jGkKegEKhbJzQMof/Y8EBEekR4cHBzPp/T3HEiomflaN24PEST1zOFGxyRyuswoo5N9kKnRqRqFyTyB+fl59Pf3Iyw0RCQQKx0O2vwE2YpV5HZbUCnV41P/CIb0RszOWMHaV+DbYPl1OHM1Gg3vzZWYS+WCfMWSgwtRroxBNWfSmzJ0fWmEZ53Flt8Pl8sFlj6j0+mE2+2GyWTC+Pg4709iYlIFB2C5/OcN2yFp60NTSwMM2mGoVGoYDAbYbDZ4PB54vV7MzMxAoVDwZ65KSkpaBQXDdobuTyiEZCg3yNs+Pdn2esj6OktmZ2eJWq0mMpmMMAxDqJjv6elpQoNGamtr+34BzIywNQI18UAAAAAASUVORK5CYII="
        ]
        []
