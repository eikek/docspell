module Comp.ItemDetail.Update exposing (update)

import Api
import Api.Model.BasicResult exposing (BasicResult)
import Api.Model.DirectionValue exposing (DirectionValue)
import Api.Model.IdName exposing (IdName)
import Api.Model.ItemDetail exposing (ItemDetail)
import Api.Model.MoveAttachment exposing (MoveAttachment)
import Api.Model.OptionalDate exposing (OptionalDate)
import Api.Model.OptionalId exposing (OptionalId)
import Api.Model.OptionalText exposing (OptionalText)
import Api.Model.ReferenceList exposing (ReferenceList)
import Api.Model.Tag exposing (Tag)
import Browser.Navigation as Nav
import Comp.AttachmentMeta
import Comp.DatePicker
import Comp.DetailEdit
import Comp.Dropdown exposing (isDropdownChangeMsg)
import Comp.Dropzone
import Comp.EquipmentForm
import Comp.ItemDetail.Model
    exposing
        ( AttachmentRename
        , Model
        , Msg(..)
        , NotesField(..)
        , SaveNameState(..)
        , isEditNotes
        )
import Comp.ItemMail
import Comp.KeyInput
import Comp.MarkdownInput
import Comp.OrgForm
import Comp.PersonForm
import Comp.SentMails
import Comp.YesNoDimmer
import Data.Direction
import Data.Fields exposing (Field)
import Data.Flags exposing (Flags)
import Data.ItemNav exposing (ItemNav)
import Data.UiSettings exposing (UiSettings)
import DatePicker
import Dict
import Html exposing (..)
import Html.Attributes exposing (..)
import Html5.DragDrop as DD
import Http
import Page exposing (Page(..))
import Ports
import Set exposing (Set)
import Throttle
import Time
import Util.File exposing (makeFileId)
import Util.Folder exposing (mkFolderOption)
import Util.Http
import Util.List
import Util.Maybe
import Util.String


update : Nav.Key -> Flags -> ItemNav -> UiSettings -> Msg -> Model -> ( Model, Cmd Msg, Sub Msg )
update key flags inav settings msg model =
    case msg of
        Init ->
            let
                ( dp, dpc ) =
                    Comp.DatePicker.init

                ( im, ic ) =
                    Comp.ItemMail.init flags
            in
            noSub
                ( { model | itemDatePicker = dp, dueDatePicker = dp, itemMail = im, visibleAttach = 0 }
                , Cmd.batch
                    [ getOptions flags
                    , Cmd.map ItemDatePickerMsg dpc
                    , Cmd.map DueDatePickerMsg dpc
                    , Cmd.map ItemMailMsg ic
                    , Api.getSentMails flags model.item.id SentMailsResp
                    ]
                )

        SetItem item ->
            let
                ( m1, c1, s1 ) =
                    update key
                        flags
                        inav
                        settings
                        (TagDropdownMsg (Comp.Dropdown.SetSelection item.tags))
                        model

                ( m2, c2, s2 ) =
                    update key
                        flags
                        inav
                        settings
                        (DirDropdownMsg
                            (Comp.Dropdown.SetSelection
                                (Data.Direction.fromString item.direction
                                    |> Maybe.map List.singleton
                                    |> Maybe.withDefault []
                                )
                            )
                        )
                        m1

                ( m3, c3, s3 ) =
                    update key
                        flags
                        inav
                        settings
                        (OrgDropdownMsg
                            (Comp.Dropdown.SetSelection
                                (item.corrOrg
                                    |> Maybe.map List.singleton
                                    |> Maybe.withDefault []
                                )
                            )
                        )
                        m2

                ( m4, c4, s4 ) =
                    update key
                        flags
                        inav
                        settings
                        (CorrPersonMsg
                            (Comp.Dropdown.SetSelection
                                (item.corrPerson
                                    |> Maybe.map List.singleton
                                    |> Maybe.withDefault []
                                )
                            )
                        )
                        m3

                ( m5, c5, s5 ) =
                    update key
                        flags
                        inav
                        settings
                        (ConcPersonMsg
                            (Comp.Dropdown.SetSelection
                                (item.concPerson
                                    |> Maybe.map List.singleton
                                    |> Maybe.withDefault []
                                )
                            )
                        )
                        m4

                ( m6, c6, s6 ) =
                    update key
                        flags
                        inav
                        settings
                        (ConcEquipMsg
                            (Comp.Dropdown.SetSelection
                                (item.concEquipment
                                    |> Maybe.map List.singleton
                                    |> Maybe.withDefault []
                                )
                            )
                        )
                        m5

                ( m7, c7, s7 ) =
                    update key flags inav settings AddFilesReset m6

                ( m8, c8, s8 ) =
                    update key
                        flags
                        inav
                        settings
                        (FolderDropdownMsg
                            (Comp.Dropdown.SetSelection
                                (item.folder
                                    |> Maybe.map List.singleton
                                    |> Maybe.withDefault []
                                )
                            )
                        )
                        m7

                proposalCmd =
                    if item.state == "created" then
                        Api.getItemProposals flags item.id GetProposalResp

                    else
                        Cmd.none
            in
            ( { m8
                | item = item
                , nameModel = item.name
                , nameState = SaveSuccess
                , notesModel = item.notes
                , notesField =
                    if Util.String.isNothingOrBlank item.notes then
                        EditNotes Comp.MarkdownInput.init

                    else
                        ViewNotes
                , itemDate = item.itemDate
                , dueDate = item.dueDate
                , visibleAttach = 0
                , modalEdit = Nothing
              }
            , Cmd.batch
                [ c1
                , c2
                , c3
                , c4
                , c5
                , c6
                , c7
                , c8
                , getOptions flags
                , proposalCmd
                , Api.getSentMails flags item.id SentMailsResp
                ]
            , Sub.batch [ s1, s2, s3, s4, s5, s6, s7, s8 ]
            )

        SetActiveAttachment pos ->
            noSub
                ( { model
                    | visibleAttach = pos
                    , sentMailsOpen = False
                    , attachRename = Nothing
                  }
                , Cmd.none
                )

        ToggleMenu ->
            noSub ( { model | menuOpen = not model.menuOpen }, Cmd.none )

        ReloadItem ->
            if model.item.id == "" then
                noSub ( model, Cmd.none )

            else
                noSub ( model, Api.itemDetail flags model.item.id GetItemResp )

        FolderDropdownMsg m ->
            let
                ( m2, c2 ) =
                    Comp.Dropdown.update m model.folderModel

                newModel =
                    { model | folderModel = m2 }

                idref =
                    Comp.Dropdown.getSelected m2 |> List.head

                save =
                    if isDropdownChangeMsg m then
                        setFolder flags newModel idref

                    else
                        Cmd.none
            in
            noSub ( newModel, Cmd.batch [ save, Cmd.map FolderDropdownMsg c2 ] )

        TagDropdownMsg m ->
            let
                ( m2, c2 ) =
                    Comp.Dropdown.update m model.tagModel

                newModel =
                    { model | tagModel = m2 }

                save =
                    if isDropdownChangeMsg m then
                        saveTags flags newModel

                    else
                        Cmd.none
            in
            noSub ( newModel, Cmd.batch [ save, Cmd.map TagDropdownMsg c2 ] )

        DirDropdownMsg m ->
            let
                ( m2, c2 ) =
                    Comp.Dropdown.update m model.directionModel

                newModel =
                    { model | directionModel = m2 }

                save =
                    if isDropdownChangeMsg m then
                        setDirection flags newModel

                    else
                        Cmd.none
            in
            noSub ( newModel, Cmd.batch [ save, Cmd.map DirDropdownMsg c2 ] )

        OrgDropdownMsg m ->
            let
                ( m2, c2 ) =
                    Comp.Dropdown.update m model.corrOrgModel

                newModel =
                    { model | corrOrgModel = m2 }

                idref =
                    Comp.Dropdown.getSelected m2 |> List.head

                save =
                    if isDropdownChangeMsg m then
                        setCorrOrg flags newModel idref

                    else
                        Cmd.none
            in
            noSub ( newModel, Cmd.batch [ save, Cmd.map OrgDropdownMsg c2 ] )

        CorrPersonMsg m ->
            let
                ( m2, c2 ) =
                    Comp.Dropdown.update m model.corrPersonModel

                newModel =
                    { model | corrPersonModel = m2 }

                idref =
                    Comp.Dropdown.getSelected m2 |> List.head

                save =
                    if isDropdownChangeMsg m then
                        setCorrPerson flags newModel idref

                    else
                        Cmd.none
            in
            noSub ( newModel, Cmd.batch [ save, Cmd.map CorrPersonMsg c2 ] )

        ConcPersonMsg m ->
            let
                ( m2, c2 ) =
                    Comp.Dropdown.update m model.concPersonModel

                newModel =
                    { model | concPersonModel = m2 }

                idref =
                    Comp.Dropdown.getSelected m2 |> List.head

                save =
                    if isDropdownChangeMsg m then
                        setConcPerson flags newModel idref

                    else
                        Cmd.none
            in
            noSub ( newModel, Cmd.batch [ save, Cmd.map ConcPersonMsg c2 ] )

        ConcEquipMsg m ->
            let
                ( m2, c2 ) =
                    Comp.Dropdown.update m model.concEquipModel

                newModel =
                    { model | concEquipModel = m2 }

                idref =
                    Comp.Dropdown.getSelected m2 |> List.head

                save =
                    if isDropdownChangeMsg m then
                        setConcEquip flags newModel idref

                    else
                        Cmd.none
            in
            noSub ( newModel, Cmd.batch [ save, Cmd.map ConcEquipMsg c2 ] )

        SetName str ->
            case Util.Maybe.fromString str of
                Just newName ->
                    let
                        nm =
                            { model | nameModel = newName }

                        cmd_ =
                            setName flags nm

                        ( newThrottle, cmd ) =
                            Throttle.try cmd_ nm.nameSaveThrottle
                    in
                    withSub
                        ( { nm
                            | nameState = Saving
                            , nameSaveThrottle = newThrottle
                          }
                        , cmd
                        )

                Nothing ->
                    noSub ( { model | nameModel = str, nameState = SaveFailed }, Cmd.none )

        SetNotes str ->
            noSub
                ( { model | notesModel = Util.Maybe.fromString str }
                , Cmd.none
                )

        ToggleEditNotes ->
            noSub
                ( { model
                    | notesField =
                        if isEditNotes model.notesField then
                            ViewNotes

                        else
                            EditNotes Comp.MarkdownInput.init
                  }
                , Cmd.none
                )

        NotesEditMsg lm ->
            case model.notesField of
                EditNotes em ->
                    let
                        ( lm2, str ) =
                            Comp.MarkdownInput.update (Maybe.withDefault "" model.notesModel) lm em
                    in
                    noSub
                        ( { model | notesField = EditNotes lm2, notesModel = Util.Maybe.fromString str }
                        , Cmd.none
                        )

                ViewNotes ->
                    noSub ( model, Cmd.none )

        SaveNotes ->
            noSub ( model, setNotes flags model )

        ConfirmItem ->
            let
                resetCmds =
                    resetHiddenFields settings flags model.item.id ResetHiddenMsg
            in
            noSub ( model, Cmd.batch (Api.setConfirmed flags model.item.id SaveResp :: resetCmds) )

        UnconfirmItem ->
            noSub ( model, Api.setUnconfirmed flags model.item.id SaveResp )

        ItemDatePickerMsg m ->
            let
                ( dp, event ) =
                    Comp.DatePicker.updateDefault m model.itemDatePicker
            in
            case event of
                DatePicker.Picked date ->
                    let
                        newModel =
                            { model | itemDatePicker = dp, itemDate = Just (Comp.DatePicker.midOfDay date) }
                    in
                    noSub ( newModel, setDate flags newModel newModel.itemDate )

                _ ->
                    noSub ( { model | itemDatePicker = dp }, Cmd.none )

        RemoveDate ->
            noSub ( { model | itemDate = Nothing }, setDate flags model Nothing )

        DueDatePickerMsg m ->
            let
                ( dp, event ) =
                    Comp.DatePicker.updateDefault m model.dueDatePicker
            in
            case event of
                DatePicker.Picked date ->
                    let
                        newModel =
                            { model | dueDatePicker = dp, dueDate = Just (Comp.DatePicker.midOfDay date) }
                    in
                    noSub ( newModel, setDueDate flags newModel newModel.dueDate )

                _ ->
                    noSub ( { model | dueDatePicker = dp }, Cmd.none )

        RemoveDueDate ->
            noSub ( { model | dueDate = Nothing }, setDueDate flags model Nothing )

        DeleteItemConfirm m ->
            let
                ( cm, confirmed ) =
                    Comp.YesNoDimmer.update m model.deleteItemConfirm

                cmd =
                    if confirmed then
                        Api.deleteItem flags model.item.id DeleteResp

                    else
                        Cmd.none
            in
            noSub ( { model | deleteItemConfirm = cm }, cmd )

        RequestDelete ->
            update key flags inav settings (DeleteItemConfirm Comp.YesNoDimmer.activate) model

        SetCorrOrgSuggestion idname ->
            noSub ( model, setCorrOrg flags model (Just idname) )

        SetCorrPersonSuggestion idname ->
            noSub ( model, setCorrPerson flags model (Just idname) )

        SetConcPersonSuggestion idname ->
            noSub ( model, setConcPerson flags model (Just idname) )

        SetConcEquipSuggestion idname ->
            noSub ( model, setConcEquip flags model (Just idname) )

        SetItemDateSuggestion date ->
            noSub ( model, setDate flags model (Just date) )

        SetDueDateSuggestion date ->
            noSub ( model, setDueDate flags model (Just date) )

        GetFolderResp (Ok fs) ->
            let
                model_ =
                    { model
                        | allFolders = fs.items
                        , folderModel =
                            Comp.Dropdown.setMkOption
                                (mkFolderOption flags fs.items)
                                model.folderModel
                    }

                mkIdName fitem =
                    IdName fitem.id fitem.name

                opts =
                    fs.items
                        |> List.map mkIdName
                        |> Comp.Dropdown.SetOptions
            in
            update key flags inav settings (FolderDropdownMsg opts) model_

        GetFolderResp (Err _) ->
            noSub ( model, Cmd.none )

        GetTagsResp (Ok tags) ->
            let
                tagList =
                    Comp.Dropdown.SetOptions tags.items

                ( m1, c1, s1 ) =
                    update key flags inav settings (TagDropdownMsg tagList) model
            in
            ( m1, c1, s1 )

        GetTagsResp (Err _) ->
            noSub ( model, Cmd.none )

        GetOrgResp (Ok orgs) ->
            let
                opts =
                    Comp.Dropdown.SetOptions orgs.items
            in
            update key flags inav settings (OrgDropdownMsg opts) model

        GetOrgResp (Err _) ->
            noSub ( model, Cmd.none )

        GetPersonResp (Ok ps) ->
            let
                opts =
                    Comp.Dropdown.SetOptions ps.items

                ( m1, c1, s1 ) =
                    update key flags inav settings (CorrPersonMsg opts) model

                ( m2, c2, s2 ) =
                    update key flags inav settings (ConcPersonMsg opts) m1
            in
            ( m2, Cmd.batch [ c1, c2 ], Sub.batch [ s1, s2 ] )

        GetPersonResp (Err _) ->
            noSub ( model, Cmd.none )

        GetEquipResp (Ok equips) ->
            let
                opts =
                    Comp.Dropdown.SetOptions
                        (List.map (\e -> IdName e.id e.name)
                            equips.items
                        )
            in
            update key flags inav settings (ConcEquipMsg opts) model

        GetEquipResp (Err _) ->
            noSub ( model, Cmd.none )

        SaveResp (Ok res) ->
            if res.success then
                noSub ( model, Api.itemDetail flags model.item.id GetItemResp )

            else
                noSub ( model, Cmd.none )

        SaveResp (Err _) ->
            noSub ( model, Cmd.none )

        SaveNameResp (Ok res) ->
            if res.success then
                noSub
                    ( { model
                        | nameState = SaveSuccess
                        , item = setItemName model.item model.nameModel
                      }
                    , Cmd.none
                    )

            else
                noSub
                    ( { model | nameState = SaveFailed }
                    , Cmd.none
                    )

        SaveNameResp (Err _) ->
            noSub ( { model | nameState = SaveFailed }, Cmd.none )

        DeleteResp (Ok res) ->
            if res.success then
                case inav.next of
                    Just id ->
                        noSub ( model, Page.set key (ItemDetailPage id) )

                    Nothing ->
                        noSub ( model, Page.set key HomePage )

            else
                noSub ( model, Cmd.none )

        DeleteResp (Err _) ->
            noSub ( model, Cmd.none )

        GetItemResp (Ok item) ->
            update key flags inav settings (SetItem item) model

        GetItemResp (Err _) ->
            noSub ( model, Cmd.none )

        GetProposalResp (Ok ip) ->
            noSub ( { model | itemProposals = ip }, Cmd.none )

        GetProposalResp (Err _) ->
            noSub ( model, Cmd.none )

        ItemMailMsg m ->
            let
                ( im, ic, fa ) =
                    Comp.ItemMail.update flags m model.itemMail
            in
            case fa of
                Comp.ItemMail.FormNone ->
                    noSub ( { model | itemMail = im }, Cmd.map ItemMailMsg ic )

                Comp.ItemMail.FormCancel ->
                    noSub
                        ( { model
                            | itemMail = Comp.ItemMail.clear im
                            , mailOpen = False
                            , mailSendResult = Nothing
                          }
                        , Cmd.map ItemMailMsg ic
                        )

                Comp.ItemMail.FormSend sm ->
                    let
                        mail =
                            { item = model.item.id
                            , mail = sm.mail
                            , conn = sm.conn
                            }
                    in
                    noSub
                        ( { model | mailSending = True }
                        , Cmd.batch
                            [ Cmd.map ItemMailMsg ic
                            , Api.sendMail flags mail SendMailResp
                            ]
                        )

        ToggleMail ->
            let
                newOpen =
                    not model.mailOpen

                filesOpen =
                    if newOpen == True then
                        False

                    else
                        model.addFilesOpen

                sendResult =
                    if newOpen then
                        model.mailSendResult

                    else
                        Nothing
            in
            noSub
                ( { model
                    | mailOpen = newOpen
                    , addFilesOpen = filesOpen
                    , mailSendResult = sendResult
                  }
                , Cmd.none
                )

        SendMailResp (Ok br) ->
            let
                mm =
                    if br.success then
                        Comp.ItemMail.clear model.itemMail

                    else
                        model.itemMail
            in
            noSub
                ( { model
                    | itemMail = mm
                    , mailSending = False
                    , mailSendResult = Just br
                  }
                , if br.success then
                    Api.itemDetail flags model.item.id GetItemResp

                  else
                    Cmd.none
                )

        SendMailResp (Err err) ->
            let
                errmsg =
                    Util.Http.errorToString err
            in
            noSub
                ( { model
                    | mailSendResult = Just (BasicResult False errmsg)
                    , mailSending = False
                  }
                , Cmd.none
                )

        SentMailsMsg m ->
            let
                sm =
                    Comp.SentMails.update m model.sentMails
            in
            noSub ( { model | sentMails = sm }, Cmd.none )

        ToggleSentMails ->
            noSub ( { model | sentMailsOpen = not model.sentMailsOpen }, Cmd.none )

        SentMailsResp (Ok list) ->
            let
                sm =
                    Comp.SentMails.initMails list.items
            in
            noSub ( { model | sentMails = sm }, Cmd.none )

        SentMailsResp (Err _) ->
            noSub ( model, Cmd.none )

        AttachMetaClick id ->
            case Dict.get id model.attachMeta of
                Just _ ->
                    noSub
                        ( { model | attachMetaOpen = not model.attachMetaOpen }
                        , Cmd.none
                        )

                Nothing ->
                    let
                        ( am, ac ) =
                            Comp.AttachmentMeta.init flags id

                        nextMeta =
                            Dict.insert id am model.attachMeta
                    in
                    noSub
                        ( { model | attachMeta = nextMeta, attachMetaOpen = True }
                        , Cmd.map (AttachMetaMsg id) ac
                        )

        AttachMetaMsg id lmsg ->
            case Dict.get id model.attachMeta of
                Just cm ->
                    let
                        am =
                            Comp.AttachmentMeta.update lmsg cm
                    in
                    noSub
                        ( { model | attachMeta = Dict.insert id am model.attachMeta }
                        , Cmd.none
                        )

                Nothing ->
                    noSub ( model, Cmd.none )

        TogglePdfNativeView default ->
            noSub
                ( { model
                    | pdfNativeView =
                        case model.pdfNativeView of
                            Just flag ->
                                Just (not flag)

                            Nothing ->
                                Just (not default)
                  }
                , Cmd.none
                )

        DeleteAttachConfirm attachId lmsg ->
            let
                ( cm, confirmed ) =
                    Comp.YesNoDimmer.update lmsg model.deleteAttachConfirm

                cmd =
                    if confirmed then
                        Api.deleteAttachment flags attachId DeleteAttachResp

                    else
                        Cmd.none
            in
            noSub ( { model | deleteAttachConfirm = cm }, cmd )

        DeleteAttachResp (Ok res) ->
            if res.success then
                update key flags inav settings ReloadItem model

            else
                noSub ( model, Cmd.none )

        DeleteAttachResp (Err _) ->
            noSub ( model, Cmd.none )

        RequestDeleteAttachment id ->
            update key
                flags
                inav
                settings
                (DeleteAttachConfirm id Comp.YesNoDimmer.activate)
                model

        AddFilesToggle ->
            noSub
                ( { model
                    | addFilesOpen = not model.addFilesOpen
                    , mailOpen =
                        if model.addFilesOpen == False then
                            False

                        else
                            model.mailOpen
                  }
                , Cmd.none
                )

        AddFilesMsg lm ->
            let
                ( dm, dc, df ) =
                    Comp.Dropzone.update lm model.addFilesModel

                nextFiles =
                    model.selectedFiles ++ df
            in
            noSub
                ( { model | addFilesModel = dm, selectedFiles = nextFiles }
                , Cmd.map AddFilesMsg dc
                )

        AddFilesReset ->
            noSub
                ( { model
                    | selectedFiles = []
                    , addFilesModel = Comp.Dropzone.init Comp.Dropzone.defaultSettings
                    , completed = Set.empty
                    , errored = Set.empty
                    , loading = Set.empty
                  }
                , Cmd.none
                )

        AddFilesSubmitUpload ->
            let
                fileids =
                    List.map makeFileId model.selectedFiles

                uploads =
                    Cmd.batch (Api.uploadAmend flags model.item.id model.selectedFiles AddFilesUploadResp)

                tracker =
                    Sub.batch <| List.map (\id -> Http.track id (AddFilesProgress id)) fileids

                ( cm2, _, _ ) =
                    Comp.Dropzone.update (Comp.Dropzone.setActive False) model.addFilesModel
            in
            ( { model | loading = Set.fromList fileids, addFilesModel = cm2 }
            , uploads
            , tracker
            )

        AddFilesUploadResp fileid (Ok res) ->
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
                    Set.remove fileid model.loading

                newModel =
                    { model | completed = compl, errored = errs, loading = load }
            in
            noSub
                ( newModel
                , Ports.setProgress ( fileid, 100 )
                )

        AddFilesUploadResp fileid (Err _) ->
            let
                errs =
                    setErrored model fileid

                load =
                    Set.remove fileid model.loading
            in
            noSub ( { model | errored = errs, loading = load }, Cmd.none )

        AddFilesProgress fileid progress ->
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

                    else
                        Ports.setProgress ( fileid, percent )
            in
            noSub ( model, updateBars )

        AttachDDMsg lm ->
            let
                ( model_, result ) =
                    DD.update lm model.attachDD

                cmd =
                    case result of
                        Just ( src, trg, _ ) ->
                            if src /= trg then
                                Api.moveAttachmentBefore flags
                                    model.item.id
                                    (MoveAttachment src trg)
                                    SaveResp

                            else
                                Cmd.none

                        Nothing ->
                            Cmd.none
            in
            noSub ( { model | attachDD = model_ }, cmd )

        ModalEditMsg lm ->
            case model.modalEdit of
                Just mm ->
                    let
                        ( mm_, mc_, mv ) =
                            Comp.DetailEdit.update flags lm mm

                        ( model_, cmd_ ) =
                            case mv of
                                Just Comp.DetailEdit.CancelForm ->
                                    ( { model | modalEdit = Nothing }, Cmd.none )

                                Just _ ->
                                    ( model, Api.itemDetail flags model.item.id GetItemResp )

                                Nothing ->
                                    ( { model | modalEdit = Just mm_ }, Cmd.none )
                    in
                    noSub ( model_, Cmd.batch [ cmd_, Cmd.map ModalEditMsg mc_ ] )

                Nothing ->
                    noSub ( model, Cmd.none )

        StartTagModal ->
            noSub
                ( { model
                    | modalEdit = Just (Comp.DetailEdit.initTagByName model.item.id "")
                  }
                , Cmd.none
                )

        StartCorrOrgModal ->
            noSub
                ( { model
                    | modalEdit =
                        Just
                            (Comp.DetailEdit.initOrg
                                model.item.id
                                Comp.OrgForm.emptyModel
                            )
                  }
                , Cmd.none
                )

        StartEditCorrOrgModal ->
            let
                orgId =
                    Comp.Dropdown.getSelected model.corrOrgModel
                        |> List.head
                        |> Maybe.map .id
            in
            case orgId of
                Just oid ->
                    let
                        ( m, c ) =
                            Comp.DetailEdit.editOrg flags oid Comp.OrgForm.emptyModel
                    in
                    noSub ( { model | modalEdit = Just m }, Cmd.map ModalEditMsg c )

                Nothing ->
                    ( model, Cmd.none, Sub.none )

        StartEditEquipModal ->
            let
                equipId =
                    Comp.Dropdown.getSelected model.concEquipModel
                        |> List.head
                        |> Maybe.map .id
            in
            case equipId of
                Just eid ->
                    let
                        ( m, c ) =
                            Comp.DetailEdit.editEquip flags eid Comp.EquipmentForm.emptyModel
                    in
                    noSub ( { model | modalEdit = Just m }, Cmd.map ModalEditMsg c )

                Nothing ->
                    ( model, Cmd.none, Sub.none )

        StartCorrPersonModal ->
            noSub
                ( { model
                    | modalEdit =
                        Just
                            (Comp.DetailEdit.initCorrPerson
                                model.item.id
                                Comp.PersonForm.emptyModel
                            )
                  }
                , Cmd.none
                )

        StartConcPersonModal ->
            noSub
                ( { model
                    | modalEdit =
                        Just
                            (Comp.DetailEdit.initConcPerson
                                model.item.id
                                Comp.PersonForm.emptyModel
                            )
                  }
                , Cmd.none
                )

        StartEditPersonModal pm ->
            let
                persId =
                    Comp.Dropdown.getSelected pm
                        |> List.head
                        |> Maybe.map .id
            in
            case persId of
                Just pid ->
                    let
                        ( m, c ) =
                            Comp.DetailEdit.editPerson flags pid Comp.PersonForm.emptyModel
                    in
                    noSub ( { model | modalEdit = Just m }, Cmd.map ModalEditMsg c )

                Nothing ->
                    ( model, Cmd.none, Sub.none )

        StartEquipModal ->
            noSub
                ( { model
                    | modalEdit =
                        Just
                            (Comp.DetailEdit.initEquip
                                model.item.id
                                Comp.EquipmentForm.emptyModel
                            )
                  }
                , Cmd.none
                )

        CloseModal ->
            noSub ( { model | modalEdit = Nothing }, Cmd.none )

        EditAttachNameStart id ->
            case model.attachRename of
                Nothing ->
                    let
                        name =
                            Util.List.find (\el -> el.id == id) model.item.attachments
                                |> Maybe.map (\el -> Maybe.withDefault "" el.name)
                    in
                    case name of
                        Just n ->
                            noSub ( { model | attachRename = Just (AttachmentRename id n) }, Cmd.none )

                        Nothing ->
                            noSub ( model, Cmd.none )

                Just _ ->
                    noSub ( { model | attachRename = Nothing }, Cmd.none )

        EditAttachNameCancel ->
            noSub ( { model | attachRename = Nothing }, Cmd.none )

        EditAttachNameSet str ->
            case model.attachRename of
                Just m ->
                    noSub
                        ( { model | attachRename = Just { m | newName = str } }
                        , Cmd.none
                        )

                Nothing ->
                    noSub ( model, Cmd.none )

        EditAttachNameSubmit ->
            let
                editId =
                    Maybe.map .id model.attachRename

                name =
                    Util.List.find (\el -> Just el.id == editId) model.item.attachments
                        |> Maybe.map (\el -> Maybe.withDefault "" el.name)

                ma =
                    Util.Maybe.filter (\m -> Just m.newName /= name) model.attachRename
            in
            case ma of
                Just m ->
                    noSub
                        ( model
                        , Api.setAttachmentName
                            flags
                            m.id
                            (Util.Maybe.fromString m.newName)
                            EditAttachNameResp
                        )

                Nothing ->
                    noSub ( { model | attachRename = Nothing }, Cmd.none )

        EditAttachNameResp (Ok res) ->
            if res.success then
                case model.attachRename of
                    Just m ->
                        let
                            changeName a =
                                if a.id == m.id then
                                    { a | name = Util.Maybe.fromString m.newName }

                                else
                                    a

                            changeItem i =
                                { i | attachments = List.map changeName i.attachments }
                        in
                        noSub
                            ( { model
                                | attachRename = Nothing
                                , item = changeItem model.item
                              }
                            , Cmd.none
                            )

                    Nothing ->
                        noSub ( model, Cmd.none )

            else
                noSub ( model, Cmd.none )

        EditAttachNameResp (Err _) ->
            noSub ( model, Cmd.none )

        ResetHiddenMsg _ _ ->
            noSub ( model, Cmd.none )

        UpdateThrottle ->
            let
                ( newThrottle, cmd ) =
                    Throttle.update model.nameSaveThrottle
            in
            withSub ( { model | nameSaveThrottle = newThrottle }, cmd )

        KeyInputMsg lm ->
            let
                ( km, keys ) =
                    Comp.KeyInput.update lm model.keyInputModel

                model_ =
                    { model | keyInputModel = km }
            in
            if keys == Just Comp.KeyInput.ctrlC then
                if model.item.state == "created" then
                    update key flags inav settings ConfirmItem model_

                else
                    update key flags inav settings UnconfirmItem model_

            else if keys == Just Comp.KeyInput.ctrlPoint then
                case inav.next of
                    Just id ->
                        noSub ( model_, Page.set key (ItemDetailPage id) )

                    Nothing ->
                        noSub ( model_, Cmd.none )

            else if keys == Just Comp.KeyInput.ctrlComma then
                case inav.prev of
                    Just id ->
                        noSub ( model_, Page.set key (ItemDetailPage id) )

                    Nothing ->
                        noSub ( model_, Cmd.none )

            else
                -- withSub because the keypress may be inside the name
                -- field and requires to activate the throttle
                withSub ( model_, Cmd.none )

        ToggleAttachMenu ->
            noSub ( { model | attachMenuOpen = not model.attachMenuOpen }, Cmd.none )



--- Helper


getOptions : Flags -> Cmd Msg
getOptions flags =
    Cmd.batch
        [ Api.getTags flags "" GetTagsResp
        , Api.getOrgLight flags GetOrgResp
        , Api.getPersonsLight flags GetPersonResp
        , Api.getEquipments flags "" GetEquipResp
        , Api.getFolders flags "" False GetFolderResp
        ]


saveTags : Flags -> Model -> Cmd Msg
saveTags flags model =
    let
        tags =
            Comp.Dropdown.getSelected model.tagModel
                |> Util.List.distinct
                |> List.map (\t -> IdName t.id t.name)
                |> ReferenceList
    in
    Api.setTags flags model.item.id tags SaveResp


setDirection : Flags -> Model -> Cmd Msg
setDirection flags model =
    let
        dir =
            Comp.Dropdown.getSelected model.directionModel |> List.head
    in
    case dir of
        Just d ->
            Api.setDirection flags model.item.id (DirectionValue (Data.Direction.toString d)) SaveResp

        Nothing ->
            Cmd.none


setFolder : Flags -> Model -> Maybe IdName -> Cmd Msg
setFolder flags model mref =
    let
        idref =
            Maybe.map .id mref
                |> OptionalId
    in
    Api.setFolder flags model.item.id idref SaveResp


setCorrOrg : Flags -> Model -> Maybe IdName -> Cmd Msg
setCorrOrg flags model mref =
    let
        idref =
            Maybe.map .id mref
                |> OptionalId
    in
    Api.setCorrOrg flags model.item.id idref SaveResp


setCorrPerson : Flags -> Model -> Maybe IdName -> Cmd Msg
setCorrPerson flags model mref =
    let
        idref =
            Maybe.map .id mref
                |> OptionalId
    in
    Api.setCorrPerson flags model.item.id idref SaveResp


setConcPerson : Flags -> Model -> Maybe IdName -> Cmd Msg
setConcPerson flags model mref =
    let
        idref =
            Maybe.map .id mref
                |> OptionalId
    in
    Api.setConcPerson flags model.item.id idref SaveResp


setConcEquip : Flags -> Model -> Maybe IdName -> Cmd Msg
setConcEquip flags model mref =
    let
        idref =
            Maybe.map .id mref
                |> OptionalId
    in
    Api.setConcEquip flags model.item.id idref SaveResp


setName : Flags -> Model -> Cmd Msg
setName flags model =
    let
        text =
            OptionalText (Just model.nameModel)
    in
    if model.nameModel == "" then
        Cmd.none

    else
        Api.setItemName flags model.item.id text SaveNameResp


setNotes : Flags -> Model -> Cmd Msg
setNotes flags model =
    let
        text =
            OptionalText model.notesModel
    in
    Api.setItemNotes flags model.item.id text SaveResp


setDate : Flags -> Model -> Maybe Int -> Cmd Msg
setDate flags model date =
    Api.setItemDate flags model.item.id (OptionalDate date) SaveResp


setDueDate : Flags -> Model -> Maybe Int -> Cmd Msg
setDueDate flags model date =
    Api.setItemDueDate flags model.item.id (OptionalDate date) SaveResp


setCompleted : Model -> String -> Set String
setCompleted model fileid =
    Set.insert fileid model.completed


setErrored : Model -> String -> Set String
setErrored model fileid =
    Set.insert fileid model.errored


noSub : ( Model, Cmd Msg ) -> ( Model, Cmd Msg, Sub Msg )
noSub ( m, c ) =
    ( m, c, Sub.none )


withSub : ( Model, Cmd Msg ) -> ( Model, Cmd Msg, Sub Msg )
withSub ( m, c ) =
    ( m
    , c
    , Throttle.ifNeeded
        (Time.every 400 (\_ -> UpdateThrottle))
        m.nameSaveThrottle
    )


resetField : Flags -> String -> (Field -> Result Http.Error BasicResult -> msg) -> Field -> Cmd msg
resetField flags item tagger field =
    case field of
        Data.Fields.Tag ->
            Api.setTags flags item Api.Model.ReferenceList.empty (tagger Data.Fields.Tag)

        Data.Fields.Folder ->
            Api.setFolder flags item Api.Model.OptionalId.empty (tagger Data.Fields.Folder)

        Data.Fields.CorrOrg ->
            Api.setCorrOrg flags item Api.Model.OptionalId.empty (tagger Data.Fields.CorrOrg)

        Data.Fields.CorrPerson ->
            Api.setCorrPerson flags item Api.Model.OptionalId.empty (tagger Data.Fields.CorrPerson)

        Data.Fields.ConcPerson ->
            Api.setConcPerson flags item Api.Model.OptionalId.empty (tagger Data.Fields.ConcPerson)

        Data.Fields.ConcEquip ->
            Api.setConcEquip flags item Api.Model.OptionalId.empty (tagger Data.Fields.ConcEquip)

        Data.Fields.Date ->
            Api.setItemDate flags item Api.Model.OptionalDate.empty (tagger Data.Fields.Date)

        Data.Fields.DueDate ->
            Api.setItemDueDate flags item Api.Model.OptionalDate.empty (tagger Data.Fields.DueDate)

        Data.Fields.Direction ->
            Cmd.none


resetHiddenFields :
    UiSettings
    -> Flags
    -> String
    -> (Field -> Result Http.Error BasicResult -> msg)
    -> List (Cmd msg)
resetHiddenFields settings flags item tagger =
    List.filter (Data.UiSettings.fieldHidden settings) Data.Fields.all
        |> List.map (resetField flags item tagger)


setItemName : ItemDetail -> String -> ItemDetail
setItemName item name =
    { item | name = name }
