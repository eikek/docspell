{-
   Copyright 2020 Eike K. & Contributors

   SPDX-License-Identifier: AGPL-3.0-or-later
-}


module Comp.ItemDetail.ItemInfoHeader exposing (view)

import Api.Model.IdName exposing (IdName)
import Comp.ItemDetail.Model
    exposing
        ( Model
        , Msg(..)
        , NotesField(..)
        , SaveNameState(..)
        )
import Comp.LinkTarget
import Data.Direction
import Data.Fields
import Data.Icons as Icons
import Data.UiSettings exposing (UiSettings)
import Html exposing (..)
import Html.Attributes exposing (..)
import Messages.Comp.ItemDetail.ItemInfoHeader exposing (Texts)
import Page exposing (Page(..))
import Styles as S
import Util.Maybe


view : Texts -> UiSettings -> Model -> Html Msg
view texts settings model =
    let
        date =
            ( div
                [ class "ml-2 sm:ml-0 whitespace-nowrap py-1 whitespace-nowrap opacity-75"
                , title texts.itemDate
                ]
                [ Icons.dateIcon2 "mr-2"
                , Maybe.withDefault model.item.created model.item.itemDate
                    |> texts.formatDate
                    |> text
                ]
            , Data.UiSettings.fieldVisible settings Data.Fields.Date
            )

        itemStyle =
            "ml-2 sm:ml-4 py-1 whitespace-nowrap "

        linkStyle =
            "opacity-75 hover:opacity-100"

        duedate =
            ( div
                [ class "ml-2 sm:ml-4 py-1 max-w-min whitespace-nowrap opacity-100"
                , class S.basicLabel
                , title texts.dueDate
                ]
                [ Icons.dueDateIcon2 "mr-2"
                , Maybe.map texts.formatDate model.item.dueDate
                    |> Maybe.withDefault ""
                    |> text
                ]
            , Data.UiSettings.fieldVisible settings Data.Fields.DueDate
                && Util.Maybe.nonEmpty model.item.dueDate
            )

        corr =
            ( div
                [ class itemStyle
                , title texts.basics.correspondent
                ]
                (Icons.correspondentIcon2 "mr-2"
                    :: Comp.LinkTarget.makeCorrLink model.item
                        [ ( linkStyle, True ) ]
                        SetLinkTarget
                )
            , Data.UiSettings.fieldVisible settings Data.Fields.CorrOrg
                || Data.UiSettings.fieldVisible settings Data.Fields.CorrPerson
            )

        conc =
            ( div
                [ class itemStyle
                , title texts.basics.concerning
                ]
                (Icons.concernedIcon2 "mr-2"
                    :: Comp.LinkTarget.makeConcLink model.item
                        [ ( linkStyle, True ) ]
                        SetLinkTarget
                )
            , Data.UiSettings.fieldVisible settings Data.Fields.ConcEquip
                || Data.UiSettings.fieldVisible settings Data.Fields.ConcPerson
            )

        itemfolder =
            ( div
                [ class itemStyle
                , title texts.basics.folder
                ]
                [ Icons.folderIcon "mr-2"
                , Comp.LinkTarget.makeFolderLink model.item
                    [ ( linkStyle, True ) ]
                    SetLinkTarget
                ]
            , Data.UiSettings.fieldVisible settings Data.Fields.Folder
            )

        src =
            ( div
                [ class itemStyle
                , title texts.source
                ]
                [ Icons.sourceIcon2 "mr-2"
                , Comp.LinkTarget.makeSourceLink [ ( linkStyle, True ) ]
                    SetLinkTarget
                    model.item.source
                ]
            , True
            )

        isDeleted =
            model.item.state == "deleted"

        isCreated =
            model.item.state == "created"
    in
    div [ class "flex flex-col pb-2" ]
        [ div [ class "flex flex-row items-center text-2xl" ]
            [ if isDeleted then
                div
                    [ classList
                        [ ( " text-4xl", True )
                        , ( "hidden", not isDeleted )
                        ]
                    , title texts.basics.deleted
                    ]
                    [ Icons.trashIcon "mr-2"
                    ]

              else
                i
                    [ classList
                        [ ( "hidden", Data.UiSettings.fieldHidden settings Data.Fields.Direction )
                        ]
                    , class (Data.Direction.iconFromString2 model.item.direction)
                    , class "mr-2"
                    , title model.item.direction
                    ]
                    []
            , div [ class "flex-grow ml-1 flex flex-col" ]
                [ div [ class "flex flex-row items-center font-semibold" ]
                    [ text model.item.name
                    , div
                        [ classList
                            [ ( "hidden", not isCreated )
                            ]
                        , class "ml-3 text-base label bg-blue-500 dark:bg-sky-500 text-white rounded-lg"
                        ]
                        [ text texts.new
                        , i [ class "fa fa-exclamation ml-2" ] []
                        ]
                    , div
                        [ classList
                            [ ( "hidden", not isDeleted )
                            ]
                        , class "ml-3 text-base label bg-red-500 dark:bg-orange-500 text-white rounded-lg"
                        ]
                        [ text texts.basics.deleted
                        , i [ class "fa fa-exclamation ml-2" ] []
                        ]
                    ]
                ]
            ]
        , ul [ class "flex flex-col sm:flex-row flex-wrap text-base " ]
            (List.filter Tuple.second
                [ date
                , corr
                , conc
                , itemfolder
                , src
                , duedate
                ]
                |> List.map Tuple.first
            )
        , renderTagsAndFields settings model
        ]


renderTagsAndFields : UiSettings -> Model -> Html Msg
renderTagsAndFields settings model =
    div [ class "flex flex-row flex-wrap items-center font-semibold sm:justify-end mt-1 min-h-7" ]
        (renderTags settings model ++ renderCustomValues settings model)


renderTags : UiSettings -> Model -> List (Html Msg)
renderTags settings model =
    let
        tagView t =
            Comp.LinkTarget.makeTagLink
                (IdName t.id t.name)
                [ ( "label md:text-sm inline-flex ml-2 hover:opacity-90 mt-1 items-center", True )
                , ( Data.UiSettings.tagColorString2 t settings, True )
                ]
                SetLinkTarget
    in
    if Data.UiSettings.fieldHidden settings Data.Fields.Tag || model.item.tags == [] then
        []

    else
        List.map tagView model.item.tags


renderCustomValues : UiSettings -> Model -> List (Html Msg)
renderCustomValues settings model =
    let
        fieldView cv =
            Comp.LinkTarget.makeCustomFieldLink2
                cv
                [ ( "ml-2 md:text-sm hover:opacity-90 mt-1 " ++ S.basicLabel, True ) ]
                SetLinkTarget

        labelThenName cv =
            Maybe.withDefault cv.name cv.label
    in
    if Data.UiSettings.fieldHidden settings Data.Fields.CustomFields || model.item.customfields == [] then
        []

    else
        List.map fieldView (List.sortBy labelThenName model.item.customfields)
