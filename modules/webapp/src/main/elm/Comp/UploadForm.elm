module Comp.UploadForm exposing (Model, Msg, init, reset, update, view)

import Api
import Api.Model.BasicResult exposing (BasicResult)
import Api.Model.ItemUploadMeta
import Comp.Dropzone
import Comp.FixedDropdown
import Comp.Progress
import Data.DropdownStyle as DS
import Data.Flags exposing (Flags)
import Data.Language exposing (Language)
import Data.UiSettings exposing (UiSettings)
import Dict exposing (Dict)
import File exposing (File)
import Html exposing (Html, a, div, h2, h3, i, input, label, p, span, text)
import Html.Attributes exposing (action, checked, class, classList, href, id, type_)
import Html.Events exposing (onCheck, onClick)
import Http
import Messages.Comp.UploadForm exposing (Texts)
import Page exposing (Page(..))
import Set exposing (Set)
import Styles
import Util.File exposing (makeFileId)
import Util.Maybe
import Util.Size


type alias Model =
    { incoming : Bool
    , singleItem : Bool
    , files : List File
    , completed : Set String
    , errored : Set String
    , loading : Dict String Int
    , dropzone : Comp.Dropzone.Model
    , skipDuplicates : Bool
    , languageModel : Comp.FixedDropdown.Model Language
    , language : Maybe Language
    }


type Msg
    = SubmitUpload
    | SingleUploadResp String (Result Http.Error BasicResult)
    | GotProgress String Http.Progress
    | ToggleIncoming
    | ToggleSingleItem
    | Clear
    | DropzoneMsg Comp.Dropzone.Msg
    | ToggleSkipDuplicates
    | LanguageMsg (Comp.FixedDropdown.Msg Language)


init : Model
init =
    { incoming = True
    , singleItem = False
    , files = []
    , completed = Set.empty
    , errored = Set.empty
    , loading = Dict.empty
    , dropzone = Comp.Dropzone.init []
    , skipDuplicates = True
    , languageModel =
        Comp.FixedDropdown.init Data.Language.all
    , language = Nothing
    }


reset : Msg
reset =
    Clear


isLoading : Model -> File -> Bool
isLoading model file =
    Dict.member (makeFileId file) model.loading


isCompleted : Model -> File -> Bool
isCompleted model file =
    Set.member (makeFileId file) model.completed


isError : Model -> File -> Bool
isError model file =
    Set.member (makeFileId file) model.errored


isIdle : Model -> File -> Bool
isIdle model file =
    not (isLoading model file || isCompleted model file || isError model file)


uploadAllTracker : String
uploadAllTracker =
    "upload-all"


isDone : Model -> Bool
isDone model =
    List.map makeFileId model.files
        |> List.all (\id -> Set.member id model.completed || Set.member id model.errored)


isSuccessAll : Model -> Bool
isSuccessAll model =
    List.map makeFileId model.files
        |> List.all (\id -> Set.member id model.completed)


hasErrors : Model -> Bool
hasErrors model =
    not (Set.isEmpty model.errored)



--- Update


update : Maybe String -> Flags -> Msg -> Model -> ( Model, Cmd Msg, Sub Msg )
update sourceId flags msg model =
    case msg of
        ToggleIncoming ->
            ( { model | incoming = not model.incoming }, Cmd.none, Sub.none )

        ToggleSingleItem ->
            ( { model | singleItem = not model.singleItem }, Cmd.none, Sub.none )

        ToggleSkipDuplicates ->
            ( { model | skipDuplicates = not model.skipDuplicates }, Cmd.none, Sub.none )

        SubmitUpload ->
            let
                emptyMeta =
                    Api.Model.ItemUploadMeta.empty

                meta =
                    { emptyMeta
                        | multiple = not model.singleItem
                        , skipDuplicates = Just model.skipDuplicates
                        , direction =
                            if model.incoming then
                                Just "incoming"

                            else
                                Just "outgoing"
                        , language = Maybe.map Data.Language.toIso3 model.language
                    }

                fileids =
                    List.map makeFileId model.files

                uploads =
                    if model.singleItem then
                        Api.uploadSingle flags
                            sourceId
                            meta
                            uploadAllTracker
                            model.files
                            (SingleUploadResp uploadAllTracker)

                    else
                        Cmd.batch (Api.upload flags sourceId meta model.files SingleUploadResp)

                tracker =
                    if model.singleItem then
                        Http.track uploadAllTracker (GotProgress uploadAllTracker)

                    else
                        Sub.batch <| List.map (\id -> Http.track id (GotProgress id)) fileids

                ( cm2, _, _ ) =
                    Comp.Dropzone.update (Comp.Dropzone.setActive False) model.dropzone

                nowLoading =
                    List.map (\fid -> ( fid, 0 )) fileids
                        |> Dict.fromList
            in
            ( { model | loading = nowLoading, dropzone = cm2 }, uploads, tracker )

        SingleUploadResp fileid (Ok res) ->
            let
                compl =
                    if res.success then
                        setCompleted model fileid

                    else
                        model.completed

                errs =
                    if not res.success then
                        setErrored model fileid

                    else
                        model.errored

                load =
                    if fileid == uploadAllTracker then
                        Dict.empty

                    else
                        Dict.remove fileid model.loading
            in
            ( { model | completed = compl, errored = errs, loading = load }
            , Cmd.none
            , Sub.none
            )

        SingleUploadResp fileid (Err _) ->
            let
                errs =
                    setErrored model fileid

                load =
                    if fileid == uploadAllTracker then
                        Dict.empty

                    else
                        Dict.remove fileid model.loading
            in
            ( { model | errored = errs, loading = load }, Cmd.none, Sub.none )

        GotProgress fileid progress ->
            let
                percent =
                    case progress of
                        Http.Sending p ->
                            Http.fractionSent p
                                |> (*) 100
                                |> round

                        _ ->
                            0

                newLoading =
                    if model.singleItem then
                        Dict.insert uploadAllTracker percent model.loading

                    else
                        Dict.insert fileid percent model.loading
            in
            ( { model | loading = newLoading }
            , Cmd.none
            , Sub.none
            )

        Clear ->
            ( init, Cmd.none, Sub.none )

        DropzoneMsg m ->
            let
                ( m2, c2, files ) =
                    Comp.Dropzone.update m model.dropzone

                nextFiles =
                    List.append model.files files
            in
            ( { model | files = nextFiles, dropzone = m2 }, Cmd.map DropzoneMsg c2, Sub.none )

        LanguageMsg lm ->
            let
                ( dm, sel ) =
                    Comp.FixedDropdown.update lm model.languageModel
            in
            ( { model
                | languageModel = dm
                , language = Util.Maybe.or [ sel, model.language ]
              }
            , Cmd.none
            , Sub.none
            )


setCompleted : Model -> String -> Set String
setCompleted model fileid =
    if fileid == uploadAllTracker then
        List.map makeFileId model.files |> Set.fromList

    else
        Set.insert fileid model.completed


setErrored : Model -> String -> Set String
setErrored model fileid =
    if fileid == uploadAllTracker then
        List.map makeFileId model.files |> Set.fromList

    else
        Set.insert fileid model.errored



--- View


view : Texts -> Maybe String -> Flags -> UiSettings -> Model -> Html Msg
view texts mid _ _ model =
    div
        [ id "content"
        , class Styles.content
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
                        [ class Styles.primaryButton
                        , href "#"
                        , onClick SubmitUpload
                        ]
                        [ text texts.basics.submit
                        ]
                    , a
                        [ class Styles.secondaryButton
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
                        , class Styles.radioInput
                        ]
                        []
                    , span [ class "ml-2" ] [ text texts.basics.incoming ]
                    ]
                , label [ class "inline-flex items-center" ]
                    [ input
                        [ type_ "radio"
                        , checked (not model.incoming)
                        , onCheck (\_ -> ToggleIncoming)
                        , class Styles.radioInput
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
                        , class Styles.checkboxInput
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
                        , class Styles.checkboxInput
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
            [ div [ class Styles.errorMessage ]
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
            [ div [ class Styles.successMessage ]
                [ h3 [ class Styles.header2, class "text-green-800 dark:text-lime-800" ]
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
                        [ class Styles.successMessageLink
                        , Page.href (SearchPage Nothing)
                        ]
                        [ text texts.successBox.itemsPage
                        ]
                    , text texts.successBox.line2
                    , a
                        [ class Styles.successMessageLink
                        , Page.href QueuePage
                        ]
                        [ text texts.successBox.processingPage
                        ]
                    , text texts.successBox.line3
                    ]
                , p []
                    [ text texts.successBox.resetLine1
                    , a
                        [ class Styles.successMessageLink
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
        [ h2 [ class Styles.header2 ]
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
