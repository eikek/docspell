{-
   Copyright 2020 Eike K. & Contributors

   SPDX-License-Identifier: AGPL-3.0-or-later
-}


module Comp.ItemDetail.AddFilesForm exposing (view)

import Comp.Dropzone
import Comp.ItemDetail.Model exposing (..)
import Comp.Progress
import Dict
import File exposing (File)
import Html exposing (..)
import Html.Attributes exposing (..)
import Html.Events exposing (onClick)
import Messages.Comp.ItemDetail.AddFilesForm exposing (Texts)
import Set
import Styles as S
import Util.File exposing (makeFileId)
import Util.Size


view : Texts -> Model -> Html Msg
view texts model =
    let
        dropzoneCfg =
            { light = True
            }
    in
    div
        [ classList
            [ ( "hidden", not model.addFilesOpen )
            ]
        , class "flex flex-col px-2 py-2 mb-4"
        , class S.box
        ]
        [ div [ class "text-lg font-bold" ]
            [ text texts.addMoreFilesToItem
            ]
        , Html.map AddFilesMsg
            (Comp.Dropzone.view2 texts.dropzone dropzoneCfg model.addFilesModel)
        , div [ class "flex flex-row space-x-2 mt-2" ]
            [ button
                [ class S.primaryButton
                , href "#"
                , onClick AddFilesSubmitUpload
                ]
                [ text texts.basics.submit
                ]
            , button
                [ class S.secondaryButton
                , href "#"
                , onClick AddFilesReset
                ]
                [ text texts.reset
                ]
            , div [ class "flex-grow" ] []
            , button
                [ class S.secondaryButton
                , href "#"
                , onClick AddFilesToggle
                ]
                [ text texts.basics.cancel
                ]
            ]
        , div
            [ classList
                [ ( S.successMessage, True )
                , ( "hidden", model.selectedFiles == [] || not (isSuccessAll model) )
                ]
            , class "mt-2"
            ]
            [ text texts.filesSubmittedInfo
            , a
                [ class S.successMessageLink
                , href "#"
                , onClick ReloadItem
                ]
                [ text texts.refreshNow
                ]
            ]
        , div
            [ class "flex flex-col mt-2"
            , classList [ ( "hidden", List.isEmpty model.selectedFiles || isSuccessAll model ) ]
            ]
            (List.map (renderFileItem model) model.selectedFiles)
        ]


renderFileItem : Model -> File -> Html Msg
renderFileItem model file =
    let
        name =
            File.name file

        size =
            File.size file
                |> toFloat
                |> Util.Size.bytesReadable Util.Size.B

        getProgress =
            let
                key =
                    makeFileId file
            in
            Dict.get key model.loading
                |> Maybe.withDefault 0
    in
    div [ class "flex flex-col" ]
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
            [ Comp.Progress.progress2 getProgress
            ]
        ]


isSuccessAll : Model -> Bool
isSuccessAll model =
    List.map makeFileId model.selectedFiles
        |> List.all (\id -> Set.member id model.completed)


isIdle : Model -> File -> Bool
isIdle model file =
    not (isLoading model file || isCompleted model file || isError model file)


isLoading : Model -> File -> Bool
isLoading model file =
    Dict.member (makeFileId file) model.loading


isCompleted : Model -> File -> Bool
isCompleted model file =
    Set.member (makeFileId file) model.completed


isError : Model -> File -> Bool
isError model file =
    Set.member (makeFileId file) model.errored
