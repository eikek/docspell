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


viewContent : Maybe String -> Flags -> UiSettings -> Model -> Html Msg
viewContent mid _ _ model =
    div
        [ id "content"
        , class S.content
        ]
        [ div [ class "container mx-auto" ]
            [ div [ class "px-0 flex flex-col" ]
                [ div [ class "py-4" ]
                    [ renderForm model
                    ]
                , div [ class "py-0" ]
                    [ Html.map DropzoneMsg
                        (Comp.Dropzone.view2 model.dropzone)
                    ]
                , div [ class "py-4" ]
                    [ a
                        [ class S.primaryButton
                        , href "#"
                        , onClick SubmitUpload
                        ]
                        [ text "Submit"
                        ]
                    , a
                        [ class S.secondaryButton
                        , class "ml-2"
                        , href "#"
                        , onClick Clear
                        ]
                        [ text "Reset"
                        ]
                    ]
                ]
            , renderErrorMsg model
            , renderSuccessMsg (Util.Maybe.nonEmpty mid) model
            , renderUploads model
            ]
        ]


renderForm : Model -> Html Msg
renderForm model =
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
                    , span [ class "ml-2" ] [ text "Incoming" ]
                    ]
                , label [ class "inline-flex items-center" ]
                    [ input
                        [ type_ "radio"
                        , checked (not model.incoming)
                        , onCheck (\_ -> ToggleIncoming)
                        , class S.radioInput
                        ]
                        []
                    , span [ class "ml-2" ] [ text "Outgoing" ]
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
                        [ text "All files are one single item"
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
                        [ text "Skip files already present in docspell"
                        ]
                    ]
                ]
            , div [ class "flex flex-col mb-3" ]
                [ label [ class "inline-flex items-center mb-2" ]
                    [ span [ class "mr-2" ] [ text "Language:" ]
                    , Html.map LanguageMsg
                        (Comp.FixedDropdown.viewStyled2
                            (DS.mainStyleWith "w-40")
                            False
                            (Maybe.map mkLanguageItem model.language)
                            model.languageModel
                        )
                    ]
                , div [ class "text-gray-400 text-xs" ]
                    [ text "Used for text extraction and analysis. The collective's "
                    , text "default language is used if not specified here."
                    ]
                ]
            ]
        ]


renderErrorMsg : Model -> Html Msg
renderErrorMsg model =
    div
        [ class "row"
        , classList [ ( "hidden", not (isDone model && hasErrors model) ) ]
        ]
        [ div [ class "mt-4" ]
            [ div [ class S.errorMessage ]
                [ text "There were errors uploading some files."
                ]
            ]
        ]


renderSuccessMsg : Bool -> Model -> Html Msg
renderSuccessMsg public model =
    div
        [ class "row"
        , classList [ ( "hidden", List.isEmpty model.files || not (isSuccessAll model) ) ]
        ]
        [ div [ class "mt-4" ]
            [ div [ class S.successMessage ]
                [ h3 [ class S.header2, class "text-green-800 dark:text-lime-800" ]
                    [ i [ class "fa fa-smile font-thin" ] []
                    , span [ class "ml-2" ]
                        [ text "All files uploaded"
                        ]
                    ]
                , p
                    [ classList [ ( "hidden", public ) ]
                    ]
                    [ text "Your files have been successfully uploaded. "
                    , text "They are now being processed. Check the "
                    , a
                        [ class S.successMessageLink
                        , Page.href HomePage
                        ]
                        [ text "Items page"
                        ]
                    , text " later where the files will arrive eventually. Or go to the "
                    , a
                        [ class S.successMessageLink
                        , Page.href QueuePage
                        ]
                        [ text "Processing Page"
                        ]
                    , text " to view the current processing state."
                    ]
                , p []
                    [ text "Click "
                    , a
                        [ class S.successMessageLink
                        , href "#"
                        , onClick Clear
                        ]
                        [ text "Reset"
                        ]
                    , text " to upload more files."
                    ]
                ]
            ]
        ]


renderUploads : Model -> Html Msg
renderUploads model =
    div
        [ class "mt-4"
        , classList [ ( "hidden", List.isEmpty model.files || isSuccessAll model ) ]
        ]
        [ div [ class "sixteen wide column" ]
            [ div [ class "ui basic segment" ]
                [ h2 [ class S.header2 ]
                    [ text "Selected Files"
                    ]
                , div [ class "ui items" ] <|
                    if model.singleItem then
                        List.map (renderFileItem model (Just uploadAllTracker)) model.files

                    else
                        List.map (renderFileItem model Nothing) model.files
                ]
            ]
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
