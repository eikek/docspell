module Comp.ItemDetail.AddFilesForm exposing (view)

import Comp.Dropzone
import Comp.ItemDetail.Model exposing (..)
import Comp.Progress
import Data.DropdownStyle
import Dict
import File exposing (File)
import Html exposing (..)
import Html.Attributes exposing (..)
import Html.Events exposing (onCheck, onClick, onInput)
import Set
import Styles as S
import Util.File exposing (makeFileId)
import Util.Size


view : Model -> Html Msg
view model =
    div
        [ classList
            [ ( "hidden", not model.addFilesOpen )
            ]
        , class "flex flex-col px-2 py-2 mb-4"
        , class S.box
        ]
        [ div [ class "text-lg font-bold" ]
            [ text "Add more files to this item"
            ]
        , Html.map AddFilesMsg
            (Comp.Dropzone.view2 model.addFilesModel)
        , div [ class "flex flex-row space-x-2 mt-2" ]
            [ button
                [ class S.primaryButton
                , href "#"
                , onClick AddFilesSubmitUpload
                ]
                [ text "Submit"
                ]
            , button
                [ class S.secondaryButton
                , href "#"
                , onClick AddFilesReset
                ]
                [ text "Reset"
                ]
            ]
        , div
            [ classList
                [ ( S.successMessage, True )
                , ( "hidden", model.selectedFiles == [] || not (isSuccessAll model) )
                ]
            , class "mt-2"
            ]
            [ text "All files have been uploaded. They are being processed, some data "
            , text "may not be available immediately. "
            , a
                [ class S.successMessageLink
                , href "#"
                , onClick ReloadItem
                ]
                [ text "Refresh now"
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
