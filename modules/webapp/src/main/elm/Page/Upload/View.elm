module Page.Upload.View exposing (view)

import Comp.Dropzone
import Comp.FixedDropdown
import Comp.Progress
import Dict
import File exposing (File)
import Html exposing (..)
import Html.Attributes exposing (..)
import Html.Events exposing (onCheck, onClick)
import Page exposing (Page(..))
import Page.Upload.Data exposing (..)
import Util.File exposing (makeFileId)
import Util.Maybe
import Util.Size


view : Maybe String -> Model -> Html Msg
view mid model =
    div [ class "upload-page ui grid container" ]
        [ div [ class "row" ]
            [ div [ class "sixteen wide column" ]
                [ div [ class "ui top attached segment" ]
                    [ renderForm model
                    ]
                , Html.map DropzoneMsg (Comp.Dropzone.view model.dropzone)
                , div [ class "ui bottom attached segment" ]
                    [ a [ class "ui primary button", href "#", onClick SubmitUpload ]
                        [ text "Submit"
                        ]
                    , a [ class "ui secondary button", href "#", onClick Clear ]
                        [ text "Reset"
                        ]
                    ]
                ]
            ]
        , if isDone model && hasErrors model then
            renderErrorMsg model

          else
            span [ class "invisible" ] []
        , if List.isEmpty model.files then
            span [] []

          else if isSuccessAll model then
            renderSuccessMsg (Util.Maybe.nonEmpty mid) model

          else
            renderUploads model
        ]


renderErrorMsg : Model -> Html Msg
renderErrorMsg _ =
    div [ class "row" ]
        [ div [ class "sixteen wide column" ]
            [ div [ class "ui large error message" ]
                [ h3 [ class "ui header" ]
                    [ i [ class "meh outline icon" ] []
                    , text "Some files failed to upload"
                    ]
                , text "There were errors uploading some files."
                ]
            ]
        ]


renderSuccessMsg : Bool -> Model -> Html Msg
renderSuccessMsg public _ =
    div [ class "row" ]
        [ div [ class "sixteen wide column" ]
            [ div [ class "ui large success message" ]
                [ h3 [ class "ui header" ]
                    [ i [ class "smile outline icon" ] []
                    , text "All files uploaded"
                    ]
                , if public then
                    p [] []

                  else
                    p []
                        [ text "Your files have been successfully uploaded. They are now being processed. Check the "
                        , a [ class "ui link", Page.href HomePage ]
                            [ text "Items page"
                            ]
                        , text " later where the files will arrive eventually. Or go to the "
                        , a [ class "ui link", Page.href QueuePage ]
                            [ text "Processing Page"
                            ]
                        , text " to view the current processing state."
                        ]
                , p []
                    [ text "Click "
                    , a [ class "ui link", href "#", onClick Clear ]
                        [ text "Reset"
                        ]
                    , text " to upload more files."
                    ]
                ]
            ]
        ]


renderUploads : Model -> Html Msg
renderUploads model =
    div [ class "row" ]
        [ div [ class "sixteen wide column" ]
            [ div [ class "ui basic segment" ]
                [ h2 [ class "ui header" ]
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
renderFileItem model mtracker file =
    let
        name =
            File.name file

        size =
            File.size file
                |> toFloat
                |> Util.Size.bytesReadable Util.Size.B
    in
    div [ class "item" ]
        [ i
            [ classList
                [ ( "large", True )
                , ( "file outline icon", isIdle model file )
                , ( "loading spinner icon", isLoading model file )
                , ( "green check icon", isCompleted model file )
                , ( "red bolt icon", isError model file )
                ]
            ]
            []
        , div [ class "middle aligned content" ]
            [ div [ class "header" ]
                [ text name
                ]
            , div [ class "right floated meta" ]
                [ text size
                ]
            , div [ class "description" ]
                [ Comp.Progress.smallIndicating (getProgress model file)
                ]
            ]
        ]


renderForm : Model -> Html Msg
renderForm model =
    div [ class "row" ]
        [ Html.form [ class "ui form" ]
            [ div [ class "grouped fields" ]
                [ div [ class "field" ]
                    [ div [ class "ui radio checkbox" ]
                        [ input
                            [ type_ "radio"
                            , checked model.incoming
                            , onCheck (\_ -> ToggleIncoming)
                            ]
                            []
                        , label [] [ text "Incoming" ]
                        ]
                    ]
                , div [ class "field" ]
                    [ div [ class "ui radio checkbox" ]
                        [ input
                            [ type_ "radio"
                            , checked (not model.incoming)
                            , onCheck (\_ -> ToggleIncoming)
                            ]
                            []
                        , label [] [ text "Outgoing" ]
                        ]
                    ]
                ]
            , div [ class "inline field" ]
                [ div [ class "ui checkbox" ]
                    [ input
                        [ type_ "checkbox"
                        , checked model.singleItem
                        , onCheck (\_ -> ToggleSingleItem)
                        ]
                        []
                    , label [] [ text "All files are one single item" ]
                    ]
                ]
            , div [ class "inline field" ]
                [ div [ class "ui checkbox" ]
                    [ input
                        [ type_ "checkbox"
                        , checked model.skipDuplicates
                        , onCheck (\_ -> ToggleSkipDuplicates)
                        ]
                        []
                    , label [] [ text "Skip files already present in docspell" ]
                    ]
                ]
            , div [ class "inline field" ]
                [ label [] [ text "Language:" ]
                , Html.map LanguageMsg
                    (Comp.FixedDropdown.view
                        (Maybe.map mkLanguageItem model.language)
                        model.languageModel
                    )
                , div [ class "small-info" ]
                    [ text "Used for text extraction and analysis. The collective's "
                    , text "default language is used if not specified here."
                    ]
                ]
            ]
        ]
