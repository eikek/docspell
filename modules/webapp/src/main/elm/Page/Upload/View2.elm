{-
   Copyright 2020 Eike K. & Contributors

   SPDX-License-Identifier: AGPL-3.0-or-later
-}


module Page.Upload.View2 exposing (viewContent, viewSidebar)

import Comp.Dropzone
import Comp.FixedDropdown
import Comp.Progress
import Data.DropdownStyle as DS
import Data.Flags exposing (Flags)
import Data.UiSettings exposing (UiSettings)
import Dict
import File exposing (File)
import Html exposing (..)
import Html.Attributes exposing (..)
import Html.Events exposing (onCheck, onClick)
import Messages.Page.Upload exposing (Texts)
import Page exposing (Page(..))
import Page.Upload.Data exposing (..)
import Styles as S
import Util.File exposing (makeFileId)
import Util.Maybe
import Util.Size


viewSidebar : Maybe String -> Bool -> Flags -> UiSettings -> Model -> Html Msg
viewSidebar _ _ _ _ _ =
    div
        [ id "sidebar"
        , class "hidden"
        ]
        []


viewContent : Texts -> Maybe String -> Flags -> UiSettings -> Model -> Html Msg
viewContent texts mid _ _ model =
    div
        [ id "content"
        , class S.content
        ]
        [ div [ class "container mx-auto" ]
            [ div [ class "px-0 flex flex-col" ]
                [ div [ class "py-4" ]
                    [ if mid == Nothing then
                        renderForm texts model

                      else
                        span [ class "hidden" ] []
                    ]
                , div [ class "py-0" ]
                    [ Html.map DropzoneMsg
                        (Comp.Dropzone.view2 texts.dropzone model.dropzone)
                    ]
                , div [ class "py-4" ]
                    [ a
                        [ class S.primaryButton
                        , href "#"
                        , onClick SubmitUpload
                        ]
                        [ text texts.basics.submit
                        ]
                    , a
                        [ class S.secondaryButton
                        , class "ml-2"
                        , href "#"
                        , onClick Clear
                        ]
                        [ text texts.reset
                        ]
                    ]
                ]
            , renderErrorMsg texts model
            , renderSuccessMsg texts (Util.Maybe.nonEmpty mid) model
            , renderUploads texts model
            ]
        ]


renderForm : Texts -> Model -> Html Msg
renderForm texts model =
    let
        languageCfg =
            { display = texts.languageLabel
            , icon = \_ -> Nothing
            , style = DS.mainStyleWith "w-40"
            , selectPlaceholder = texts.basics.selectPlaceholder
            }
    in
    div [ class "row" ]
        [ Html.form [ action "#" ]
            [ div [ class "flex flex-col mb-3" ]
                [ label [ class "inline-flex items-center" ]
                    [ input
                        [ type_ "radio"
                        , checked model.incoming
                        , onCheck (\_ -> ToggleIncoming)
                        , class S.radioInput
                        ]
                        []
                    , span [ class "ml-2" ] [ text texts.basics.incoming ]
                    ]
                , label [ class "inline-flex items-center" ]
                    [ input
                        [ type_ "radio"
                        , checked (not model.incoming)
                        , onCheck (\_ -> ToggleIncoming)
                        , class S.radioInput
                        ]
                        []
                    , span [ class "ml-2" ] [ text texts.basics.outgoing ]
                    ]
                ]
            , div [ class "flex flex-col mb-3" ]
                [ label [ class "inline-flex items-center" ]
                    [ input
                        [ type_ "checkbox"
                        , checked model.singleItem
                        , onCheck (\_ -> ToggleSingleItem)
                        , class S.checkboxInput
                        ]
                        []
                    , span [ class "ml-2" ]
                        [ text texts.allFilesOneItem
                        ]
                    ]
                ]
            , div [ class "flex flex-col mb-3" ]
                [ label [ class "inline-flex items-center" ]
                    [ input
                        [ type_ "checkbox"
                        , checked model.skipDuplicates
                        , onCheck (\_ -> ToggleSkipDuplicates)
                        , class S.checkboxInput
                        ]
                        []
                    , span [ class "ml-2" ]
                        [ text texts.skipExistingFiles
                        ]
                    ]
                ]
            , div [ class "flex flex-col mb-3" ]
                [ label [ class "inline-flex items-center mb-2" ]
                    [ span [ class "mr-2" ] [ text (texts.language ++ ":") ]
                    , Html.map LanguageMsg
                        (Comp.FixedDropdown.viewStyled2
                            languageCfg
                            False
                            model.language
                            model.languageModel
                        )
                    ]
                , div [ class "text-gray-400 text-xs" ]
                    [ text texts.languageInfo
                    ]
                ]
            ]
        ]


renderErrorMsg : Texts -> Model -> Html Msg
renderErrorMsg texts model =
    div
        [ class "row"
        , classList [ ( "hidden", not (isDone model && hasErrors model) ) ]
        ]
        [ div [ class "mt-4" ]
            [ div [ class S.errorMessage ]
                [ text texts.uploadErrorMessage
                ]
            ]
        ]


renderSuccessMsg : Texts -> Bool -> Model -> Html Msg
renderSuccessMsg texts public model =
    div
        [ class "row"
        , classList [ ( "hidden", List.isEmpty model.files || not (isSuccessAll model) ) ]
        ]
        [ div [ class "mt-4" ]
            [ div [ class S.successMessage ]
                [ h3 [ class S.header2, class "text-green-800 dark:text-lime-800" ]
                    [ i [ class "fa fa-smile font-thin" ] []
                    , span [ class "ml-2" ]
                        [ text texts.successBox.allFilesUploaded
                        ]
                    ]
                , p
                    [ classList [ ( "hidden", public ) ]
                    ]
                    [ text texts.successBox.line1
                    , a
                        [ class S.successMessageLink
                        , Page.href SearchPage
                        ]
                        [ text texts.successBox.itemsPage
                        ]
                    , text texts.successBox.line2
                    , a
                        [ class S.successMessageLink
                        , Page.href QueuePage
                        ]
                        [ text texts.successBox.processingPage
                        ]
                    , text texts.successBox.line3
                    ]
                , p []
                    [ text texts.successBox.resetLine1
                    , a
                        [ class S.successMessageLink
                        , href "#"
                        , onClick Clear
                        ]
                        [ text texts.successBox.reset
                        ]
                    , text texts.successBox.resetLine2
                    ]
                ]
            ]
        ]


renderUploads : Texts -> Model -> Html Msg
renderUploads texts model =
    div
        [ class "mt-4"
        , classList [ ( "hidden", List.isEmpty model.files || isSuccessAll model ) ]
        ]
        [ h2 [ class S.header2 ]
            [ text texts.selectedFiles
            , text (" (" ++ (List.length model.files |> String.fromInt) ++ ")")
            ]
        , div [] <|
            if model.singleItem then
                List.map (renderFileItem model (Just uploadAllTracker)) model.files

            else
                List.map (renderFileItem model Nothing) model.files
        ]


getProgress : Model -> File -> Int
getProgress model file =
    let
        key =
            if model.singleItem then
                uploadAllTracker

            else
                makeFileId file
    in
    Dict.get key model.loading
        |> Maybe.withDefault 0


renderFileItem : Model -> Maybe String -> File -> Html Msg
renderFileItem model _ file =
    let
        name =
            File.name file

        size =
            File.size file
                |> toFloat
                |> Util.Size.bytesReadable Util.Size.B
    in
    div [ class "flex flex-col w-full mb-4" ]
        [ div [ class "flex flex-row items-center" ]
            [ div [ class "inline-flex items-center" ]
                [ i
                    [ classList
                        [ ( "mr-2 text-lg", True )
                        , ( "fa fa-file font-thin", isIdle model file )
                        , ( "fa fa-spinner animate-spin ", isLoading model file )
                        , ( "fa fa-check ", isCompleted model file )
                        , ( "fa fa-bolt", isError model file )
                        ]
                    ]
                    []
                , div [ class "middle aligned content" ]
                    [ div [ class "header" ]
                        [ text name
                        ]
                    ]
                ]
            , div [ class "flex-grow inline-flex justify-end" ]
                [ text size
                ]
            ]
        , div [ class "h-4" ]
            [ Comp.Progress.progress2 (getProgress model file)
            ]
        ]
