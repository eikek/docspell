module Page.Upload.Update exposing (update)

import Api
import Api.Model.ItemUploadMeta
import Comp.Dropzone
import Comp.FixedDropdown
import Data.Flags exposing (Flags)
import Data.Language
import Dict
import Http
import Page.Upload.Data exposing (..)
import Set exposing (Set)
import Util.File exposing (makeFileId)
import Util.Maybe


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
            ( emptyModel, Cmd.none, Sub.none )

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
