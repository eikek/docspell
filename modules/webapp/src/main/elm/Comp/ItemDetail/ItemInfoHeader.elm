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
import Page exposing (Page(..))
import Styles as S
import Util.Maybe
import Util.Time


view : UiSettings -> Model -> Html Msg
view settings model =
    let
        date =
            ( div
                [ class "ml-2 sm:ml-0 whitespace-nowrap py-1 whitespace-nowrap opacity-75"
                , title "Item Date"
                ]
                [ Icons.dateIcon2 "mr-2"
                , Maybe.withDefault model.item.created model.item.itemDate
                    |> Util.Time.formatDate
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
                , title "Due Date"
                ]
                [ Icons.dueDateIcon2 "mr-2"
                , Maybe.map Util.Time.formatDate model.item.dueDate
                    |> Maybe.withDefault ""
                    |> text
                ]
            , Data.UiSettings.fieldVisible settings Data.Fields.DueDate
                && Util.Maybe.nonEmpty model.item.dueDate
            )

        corr =
            ( div
                [ class itemStyle
                , title "Correspondent"
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
                , title "Concerning"
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
                , title "Folder"
                ]
                [ Icons.folderIcon2 "mr-2"
                , Comp.LinkTarget.makeFolderLink model.item
                    [ ( linkStyle, True ) ]
                    SetLinkTarget
                ]
            , Data.UiSettings.fieldVisible settings Data.Fields.Folder
            )

        src =
            ( div
                [ class itemStyle
                , title "Source"
                ]
                [ Icons.sourceIcon2 "mr-2"
                , Comp.LinkTarget.makeSourceLink [ ( linkStyle, True ) ]
                    SetLinkTarget
                    model.item.source
                ]
            , True
            )
    in
    div [ class "flex flex-col pb-2" ]
        [ div [ class "flex flex-row items-center text-2xl" ]
            [ i
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
                            [ ( "hidden", model.item.state /= "created" )
                            ]
                        , class "ml-3 text-base label bg-blue-500 dark:bg-lightblue-500 text-white rounded-lg"
                        ]
                        [ text "New"
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
        , div [ class "font-semibold mb-2 mt-3 pr-3" ]
            (renderTagsAndFields settings model)
        ]


renderTagsAndFields : UiSettings -> Model -> List (Html Msg)
renderTagsAndFields settings model =
    [ div [ class "flex flex-row flex-wrap items-center sm:justify-end" ]
        (renderTags settings model ++ renderCustomValues settings model)
    ]


renderTags : UiSettings -> Model -> List (Html Msg)
renderTags settings model =
    let
        tagView t =
            Comp.LinkTarget.makeTagLink
                (IdName t.id t.name)
                [ ( "label inline-flex ml-2 hover:opacity-90 mt-1 items-center", True )
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
                [ ( "ml-2 hover:opacity-90 mt-1 " ++ S.basicLabel, True ) ]
                SetLinkTarget

        labelThenName cv =
            Maybe.withDefault cv.name cv.label
    in
    if Data.UiSettings.fieldHidden settings Data.Fields.CustomFields || model.item.customfields == [] then
        []

    else
        List.map fieldView (List.sortBy labelThenName model.item.customfields)
