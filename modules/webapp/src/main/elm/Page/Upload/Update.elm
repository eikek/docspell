module Page.Upload.Update exposing (update)

import Api
import Api.Model.ItemUploadMeta
import Comp.Dropzone
import Data.Flags exposing (Flags)
import Http
import Page.Upload.Data exposing (..)
import Ports
import Set exposing (Set)
import Util.File exposing (makeFileId)


update : Maybe String -> Flags -> Msg -> Model -> ( Model, Cmd Msg, Sub Msg )
update sourceId flags msg model =
    case msg of
        ToggleIncoming ->
            ( { model | incoming = not model.incoming }, Cmd.none, Sub.none )

        ToggleSingleItem ->
            ( { model | singleItem = not model.singleItem }, Cmd.none, Sub.none )

        SubmitUpload ->
            let
                emptyMeta =
                    Api.Model.ItemUploadMeta.empty

                meta =
                    { emptyMeta
                        | multiple = not model.singleItem
                        , direction =
                            if model.incoming then
                                Just "incoming"

                            else
                                Just "outgoing"
                    }

                fileids =
                    List.map makeFileId model.files

                uploads =
                    if model.singleItem then
                        Api.uploadSingle flags sourceId meta uploadAllTracker model.files (SingleUploadResp uploadAllTracker)

                    else
                        Cmd.batch (Api.upload flags sourceId meta model.files SingleUploadResp)

                tracker =
                    if model.singleItem then
                        Http.track uploadAllTracker (GotProgress uploadAllTracker)

                    else
                        Sub.batch <| List.map (\id -> Http.track id (GotProgress id)) fileids

                ( cm2, _, _ ) =
                    Comp.Dropzone.update (Comp.Dropzone.setActive False) model.dropzone
            in
            ( { model | loading = Set.fromList fileids, dropzone = cm2 }, uploads, tracker )

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
                        Set.empty

                    else
                        Set.remove fileid model.loading
            in
            ( { model | completed = compl, errored = errs, loading = load }
            , Ports.setProgress ( fileid, 100 )
            , Sub.none
            )

        SingleUploadResp fileid (Err _) ->
            let
                errs =
                    setErrored model fileid

                load =
                    if fileid == uploadAllTracker then
                        Set.empty

                    else
                        Set.remove fileid model.loading
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

                updateBars =
                    if percent == 0 then
                        Cmd.none

                    else if model.singleItem then
                        Ports.setAllProgress ( uploadAllTracker, percent )

                    else
                        Ports.setProgress ( fileid, percent )
            in
            ( model, updateBars, Sub.none )

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
