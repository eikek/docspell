{-
   Copyright 2020 Docspell Contributors

   SPDX-License-Identifier: GPL-3.0-or-later
-}


module Comp.ItemDetail.Update exposing (update)

import Api
import Api.Model.BasicResult exposing (BasicResult)
import Api.Model.CustomField exposing (CustomField)
import Api.Model.CustomFieldValue exposing (CustomFieldValue)
import Api.Model.DirectionValue exposing (DirectionValue)
import Api.Model.IdName exposing (IdName)
import Api.Model.ItemDetail exposing (ItemDetail)
import Api.Model.ItemFieldValue exposing (ItemFieldValue)
import Api.Model.MoveAttachment exposing (MoveAttachment)
import Api.Model.OptionalDate exposing (OptionalDate)
import Api.Model.OptionalId exposing (OptionalId)
import Api.Model.OptionalText exposing (OptionalText)
import Api.Model.StringList exposing (StringList)
import Browser.Navigation as Nav
import Comp.AttachmentMeta
import Comp.CustomFieldMultiInput
import Comp.DatePicker
import Comp.DetailEdit
import Comp.Dropdown exposing (isDropdownChangeMsg)
import Comp.Dropzone
import Comp.EquipmentForm
import Comp.ItemDetail.FieldTabState as FTabState
import Comp.ItemDetail.Model
    exposing
        ( AttachmentRename
        , ConfirmModalValue(..)
        , MailSendResult(..)
        , Model
        , Msg(..)
        , NotesField(..)
        , SaveNameState(..)
        , SelectActionMode(..)
        , UpdateResult
        , ViewMode(..)
        , initSelectViewModel
        , initShowQrModel
        , isEditNotes
        , isShowQrAttach
        , isShowQrItem
        , resultModel
        , resultModelCmd
        , resultModelCmdSub
        )
import Comp.ItemMail
import Comp.KeyInput
import Comp.LinkTarget
import Comp.MarkdownInput
import Comp.OrgForm
import Comp.PersonForm
import Comp.SentMails
import Data.CustomFieldChange exposing (CustomFieldChange(..))
import Data.Direction
import Data.EquipmentOrder
import Data.Fields exposing (Field)
import Data.Flags exposing (Flags)
import Data.FolderOrder
import Data.ItemNav exposing (ItemNav)
import Data.PersonOrder
import Data.PersonUse
import Data.TagOrder
import Data.UiSettings exposing (UiSettings)
import DatePicker
import Dict
import Html5.DragDrop as DD
import Http
import Page exposing (Page(..))
import Ports
import Set exposing (Set)
import Throttle
import Time
import Util.File exposing (makeFileId)
import Util.List
import Util.Maybe
import Util.String
import Util.Tag


update : Nav.Key -> Flags -> ItemNav -> UiSettings -> Msg -> Model -> UpdateResult
update key flags inav settings msg model =
    case msg of
        Init ->
            let
                ( dp, dpc ) =
                    Comp.DatePicker.init

                ( im, ic ) =
                    Comp.ItemMail.init flags

                ( cm, cc ) =
                    Comp.CustomFieldMultiInput.init flags
            in
            resultModelCmd
                ( { model
                    | itemDatePicker = dp
                    , dueDatePicker = dp
                    , itemMail = im
                    , visibleAttach = 0
                    , attachMenuOpen = False
                    , customFieldsModel = cm
                  }
                , Cmd.batch
                    [ getOptions flags
                    , Cmd.map ItemDatePickerMsg dpc
                    , Cmd.map DueDatePickerMsg dpc
                    , Cmd.map ItemMailMsg ic
                    , Cmd.map CustomFieldMsg cc
                    , Api.getSentMails flags model.item.id SentMailsResp
                    ]
                )

        SetItem item ->
            let
                res1 =
                    update key
                        flags
                        inav
                        settings
                        (TagDropdownMsg (Comp.Dropdown.SetSelection item.tags))
                        model

                res2 =
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
                        res1.model

                res3 =
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
                        res2.model

                res4 =
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
                        res3.model

                res5 =
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
                        res4.model

                res6 =
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
                        res5.model

                res7 =
                    update key flags inav settings AddFilesReset res6.model

                res8 =
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
                        res7.model

                res9 =
                    update key
                        flags
                        inav
                        settings
                        (CustomFieldMsg (Comp.CustomFieldMultiInput.setValues item.customfields))
                        res8.model

                proposalCmd =
                    if item.state == "created" then
                        Api.getItemProposals flags item.id GetProposalResp

                    else
                        Cmd.none

                lastModel =
                    res9.model
            in
            { model =
                { lastModel
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
            , cmd =
                Cmd.batch
                    [ res1.cmd
                    , res2.cmd
                    , res3.cmd
                    , res4.cmd
                    , res5.cmd
                    , res6.cmd
                    , res7.cmd
                    , res8.cmd
                    , res9.cmd
                    , getOptions flags
                    , proposalCmd
                    , Api.getSentMails flags item.id SentMailsResp
                    , Api.getPersons flags "" Data.PersonOrder.NameAsc GetPersonResp
                    , Cmd.map CustomFieldMsg (Comp.CustomFieldMultiInput.initCmd flags)
                    ]
            , sub =
                Sub.batch
                    [ res1.sub
                    , res2.sub
                    , res3.sub
                    , res4.sub
                    , res5.sub
                    , res6.sub
                    , res7.sub
                    , res8.sub
                    , res9.sub
                    ]
            , linkTarget = Comp.LinkTarget.LinkNone
            , removedItem = Nothing
            }

        SetActiveAttachment pos ->
            resultModel
                { model
                    | visibleAttach = pos
                    , attachMenuOpen = False
                    , sentMailsOpen = False
                    , attachRename = Nothing
                }

        ToggleAttachment id ->
            case model.viewMode of
                SelectView svm ->
                    let
                        svm_ =
                            if Set.member id svm.ids then
                                { svm | ids = Set.remove id svm.ids }

                            else
                                { svm | ids = Set.insert id svm.ids }
                    in
                    resultModel
                        { model | viewMode = SelectView svm_ }

                SimpleView ->
                    resultModel model

        ToggleMenu ->
            resultModel
                { model | menuOpen = not model.menuOpen }

        ReloadItem ->
            if model.item.id == "" then
                resultModel model

            else
                resultModelCmd ( model, Api.itemDetail flags model.item.id GetItemResp )

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
            resultModelCmd ( newModel, Cmd.batch [ save, Cmd.map FolderDropdownMsg c2 ] )

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
            resultModelCmd ( newModel, Cmd.batch [ save, Cmd.map TagDropdownMsg c2 ] )

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
            resultModelCmd ( newModel, Cmd.batch [ save, Cmd.map DirDropdownMsg c2 ] )

        OrgDropdownMsg m ->
            let
                ( m2, c2 ) =
                    Comp.Dropdown.update m model.corrOrgModel

                idref =
                    Comp.Dropdown.getSelected m2 |> List.head

                newModel =
                    { model
                        | corrOrgModel = m2
                    }

                save =
                    if isDropdownChangeMsg m then
                        setCorrOrg flags newModel idref

                    else
                        Cmd.none
            in
            resultModelCmd ( newModel, Cmd.batch [ save, Cmd.map OrgDropdownMsg c2 ] )

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
            resultModelCmd ( newModel, Cmd.batch [ save, Cmd.map CorrPersonMsg c2 ] )

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
            resultModelCmd ( newModel, Cmd.batch [ save, Cmd.map ConcPersonMsg c2 ] )

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
            resultModelCmd ( newModel, Cmd.batch [ save, Cmd.map ConcEquipMsg c2 ] )

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
                    resultModel { model | nameModel = str, nameState = SaveFailed }

        SetNotes str ->
            resultModel
                { model | notesModel = Util.Maybe.fromString str }

        ToggleEditNotes ->
            resultModel
                { model
                    | notesField =
                        if isEditNotes model.notesField then
                            ViewNotes

                        else
                            EditNotes Comp.MarkdownInput.init
                }

        NotesEditMsg lm ->
            case model.notesField of
                EditNotes em ->
                    let
                        ( lm2, str ) =
                            Comp.MarkdownInput.update (Maybe.withDefault "" model.notesModel) lm em
                    in
                    resultModel
                        { model | notesField = EditNotes lm2, notesModel = Util.Maybe.fromString str }

                ViewNotes ->
                    resultModel model

        SaveNotes ->
            resultModelCmd ( model, setNotes flags model )

        ConfirmItem ->
            let
                resetCmds =
                    resetHiddenFields settings flags model.item.id ResetHiddenMsg
            in
            resultModelCmd ( model, Cmd.batch (Api.setConfirmed flags model.item.id SaveResp :: resetCmds) )

        UnconfirmItem ->
            resultModelCmd ( model, Api.setUnconfirmed flags model.item.id SaveResp )

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
                    resultModelCmd ( newModel, setDate flags newModel newModel.itemDate )

                _ ->
                    resultModel { model | itemDatePicker = dp }

        RemoveDate ->
            resultModelCmd ( { model | itemDate = Nothing }, setDate flags model Nothing )

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
                    resultModelCmd ( newModel, setDueDate flags newModel newModel.dueDate )

                _ ->
                    resultModel { model | dueDatePicker = dp }

        RemoveDueDate ->
            resultModelCmd ( { model | dueDate = Nothing }, setDueDate flags model Nothing )

        DeleteItemConfirmed ->
            let
                cmd =
                    Api.deleteItem flags model.item.id (DeleteResp model.item.id)
            in
            resultModelCmd ( { model | itemModal = Nothing }, cmd )

        ItemModalCancelled ->
            resultModel { model | itemModal = Nothing }

        RequestDelete ->
            resultModel { model | itemModal = Just (ConfirmModalDeleteItem DeleteItemConfirmed) }

        SetCorrOrgSuggestion idname ->
            resultModelCmd ( model, setCorrOrg flags model (Just idname) )

        SetCorrPersonSuggestion idname ->
            resultModelCmd ( model, setCorrPerson flags model (Just idname) )

        SetConcPersonSuggestion idname ->
            resultModelCmd ( model, setConcPerson flags model (Just idname) )

        SetConcEquipSuggestion idname ->
            resultModelCmd ( model, setConcEquip flags model (Just idname) )

        SetItemDateSuggestion date ->
            resultModelCmd ( model, setDate flags model (Just date) )

        SetDueDateSuggestion date ->
            resultModelCmd ( model, setDueDate flags model (Just date) )

        GetFolderResp (Ok fs) ->
            let
                model_ =
                    { model | allFolders = fs.items }

                mkIdName fitem =
                    IdName fitem.id fitem.name

                opts =
                    fs.items
                        |> List.map mkIdName
                        |> Comp.Dropdown.SetOptions
            in
            update key flags inav settings (FolderDropdownMsg opts) model_

        GetFolderResp (Err _) ->
            resultModel model

        GetTagsResp (Ok tags) ->
            let
                tagList =
                    Comp.Dropdown.SetOptions tags.items
            in
            update key flags inav settings (TagDropdownMsg tagList) { model | allTags = tags.items }

        GetTagsResp (Err _) ->
            resultModel model

        GetOrgResp (Ok orgs) ->
            let
                opts =
                    Comp.Dropdown.SetOptions orgs.items
            in
            update key flags inav settings (OrgDropdownMsg opts) model

        GetOrgResp (Err _) ->
            resultModel model

        GetPersonResp (Ok ps) ->
            let
                { concerning, correspondent } =
                    Data.PersonUse.spanPersonList ps.items

                personDict =
                    List.map (\p -> ( p.id, p )) ps.items
                        |> Dict.fromList

                corrOrg =
                    Comp.Dropdown.getSelected model.corrOrgModel
                        |> List.head

                personFilter =
                    case corrOrg of
                        Just n ->
                            \p -> p.organization == Just n

                        Nothing ->
                            \_ -> True

                concRefs =
                    List.map (\e -> IdName e.id e.name) concerning

                corrRefs =
                    List.filter personFilter correspondent
                        |> List.map (\e -> IdName e.id e.name)

                model_ =
                    { model | allPersons = personDict }

                res1 =
                    update key
                        flags
                        inav
                        settings
                        (CorrPersonMsg (Comp.Dropdown.SetOptions corrRefs))
                        model_

                res2 =
                    update key
                        flags
                        inav
                        settings
                        (ConcPersonMsg (Comp.Dropdown.SetOptions concRefs))
                        res1.model
            in
            { model = res2.model
            , cmd = Cmd.batch [ res1.cmd, res2.cmd ]
            , sub = Sub.batch [ res1.sub, res2.sub ]
            , linkTarget = Comp.LinkTarget.LinkNone
            , removedItem = Nothing
            }

        GetPersonResp (Err _) ->
            resultModel model

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
            resultModel model

        SaveResp (Ok res) ->
            if res.success then
                resultModelCmd ( model, Api.itemDetail flags model.item.id GetItemResp )

            else
                resultModel model

        SaveResp (Err _) ->
            resultModel model

        SaveNameResp (Ok res) ->
            if res.success then
                resultModel
                    { model
                        | nameState = SaveSuccess
                        , item = setItemName model.item model.nameModel
                    }

            else
                resultModel
                    { model | nameState = SaveFailed }

        SaveNameResp (Err _) ->
            resultModel { model | nameState = SaveFailed }

        DeleteResp removedId (Ok res) ->
            if res.success then
                let
                    result_ =
                        case inav.next of
                            Just id ->
                                resultModelCmd ( model, Page.set key (ItemDetailPage id) )

                            Nothing ->
                                resultModelCmd ( model, Page.set key HomePage )
                in
                { result_ | removedItem = Just removedId }

            else
                resultModel model

        DeleteResp _ (Err _) ->
            resultModel model

        GetItemResp (Ok item) ->
            update key flags inav settings (SetItem item) model

        GetItemResp (Err _) ->
            resultModel model

        GetProposalResp (Ok ip) ->
            resultModel { model | itemProposals = ip }

        GetProposalResp (Err _) ->
            resultModel model

        ItemMailMsg m ->
            let
                ( im, ic, fa ) =
                    Comp.ItemMail.update flags m model.itemMail
            in
            case fa of
                Comp.ItemMail.FormNone ->
                    resultModelCmd ( { model | itemMail = im }, Cmd.map ItemMailMsg ic )

                Comp.ItemMail.FormCancel ->
                    resultModelCmd
                        ( { model
                            | itemMail = Comp.ItemMail.clear im
                            , mailOpen = False
                            , mailSendResult = MailSendResultInitial
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
                    resultModelCmd
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
                        MailSendResultInitial
            in
            resultModel
                { model
                    | mailOpen = newOpen
                    , addFilesOpen = filesOpen
                    , mailSendResult = sendResult
                }

        SendMailResp (Ok br) ->
            let
                mm =
                    if br.success then
                        Comp.ItemMail.clear model.itemMail

                    else
                        model.itemMail
            in
            resultModelCmd
                ( { model
                    | itemMail = mm
                    , mailSending = False
                    , mailSendResult =
                        if br.success then
                            MailSendSuccessful

                        else
                            MailSendFailed br.message
                  }
                , if br.success then
                    Api.itemDetail flags model.item.id GetItemResp

                  else
                    Cmd.none
                )

        SendMailResp (Err err) ->
            resultModel
                { model
                    | mailSendResult = MailSendHttpError err
                    , mailSending = False
                }

        SentMailsMsg m ->
            let
                sm =
                    Comp.SentMails.update m model.sentMails
            in
            resultModel { model | sentMails = sm }

        ToggleSentMails ->
            resultModel { model | sentMailsOpen = not model.sentMailsOpen }

        SentMailsResp (Ok list) ->
            let
                sm =
                    Comp.SentMails.initMails list.items
            in
            resultModel { model | sentMails = sm }

        SentMailsResp (Err _) ->
            resultModel model

        AttachMetaClick id ->
            case Dict.get id model.attachMeta of
                Just _ ->
                    resultModel
                        { model
                            | attachMetaOpen = not model.attachMetaOpen
                            , attachmentDropdownOpen = False
                        }

                Nothing ->
                    let
                        ( am, ac ) =
                            Comp.AttachmentMeta.init flags id

                        nextMeta =
                            Dict.insert id am model.attachMeta
                    in
                    resultModelCmd
                        ( { model
                            | attachMeta = nextMeta
                            , attachMetaOpen = True
                            , attachmentDropdownOpen = False
                          }
                        , Cmd.map (AttachMetaMsg id) ac
                        )

        AttachMetaMsg id lmsg ->
            case Dict.get id model.attachMeta of
                Just cm ->
                    let
                        am =
                            Comp.AttachmentMeta.update lmsg cm
                    in
                    resultModel
                        { model | attachMeta = Dict.insert id am model.attachMeta }

                Nothing ->
                    resultModel model

        TogglePdfNativeView default ->
            resultModel
                { model
                    | pdfNativeView =
                        case model.pdfNativeView of
                            Just flag ->
                                Just (not flag)

                            Nothing ->
                                Just (not default)
                    , attachmentDropdownOpen = False
                }

        DeleteAttachConfirmed attachId ->
            let
                cmd =
                    Api.deleteAttachment flags attachId DeleteAttachResp
            in
            resultModelCmd ( { model | attachModal = Nothing }, cmd )

        AttachModalCancelled ->
            resultModel { model | attachModal = Nothing }

        DeleteAttachResp (Ok res) ->
            if res.success then
                update key flags inav settings ReloadItem model

            else
                resultModel model

        DeleteAttachResp (Err _) ->
            resultModel model

        RequestDeleteAttachment id ->
            let
                model_ =
                    { model
                        | attachmentDropdownOpen = False
                        , attachModal = Just (ConfirmModalDeleteFile (DeleteAttachConfirmed id))
                    }
            in
            resultModel model_

        RequestDeleteSelected ->
            case model.viewMode of
                SelectView svm ->
                    if Set.isEmpty svm.ids then
                        resultModel model

                    else
                        let
                            model_ =
                                { model
                                    | viewMode =
                                        SelectView
                                            { svm
                                                | action = DeleteSelected
                                            }
                                    , attachModal = Just (ConfirmModalDeleteAllFiles DeleteSelectedConfirmed)
                                }
                        in
                        resultModel model_

                SimpleView ->
                    resultModel model

        DeleteSelectedConfirmed ->
            case model.viewMode of
                SelectView svm ->
                    let
                        cmd =
                            Api.deleteAttachments flags svm.ids DeleteAttachResp
                    in
                    resultModelCmd ( { model | attachModal = Nothing, viewMode = SimpleView }, cmd )

                SimpleView ->
                    resultModel model

        AddFilesToggle ->
            resultModel
                { model
                    | addFilesOpen = not model.addFilesOpen
                    , mailOpen =
                        if model.addFilesOpen == False then
                            False

                        else
                            model.mailOpen
                }

        AddFilesMsg lm ->
            let
                ( dm, dc, df ) =
                    Comp.Dropzone.update lm model.addFilesModel

                nextFiles =
                    model.selectedFiles ++ df
            in
            resultModelCmd
                ( { model | addFilesModel = dm, selectedFiles = nextFiles }
                , Cmd.map AddFilesMsg dc
                )

        AddFilesReset ->
            resultModel
                { model
                    | selectedFiles = []
                    , addFilesModel = Comp.Dropzone.init []
                    , completed = Set.empty
                    , errored = Set.empty
                    , loading = Dict.empty
                }

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

                newLoading =
                    List.map (\fid -> ( fid, 0 )) fileids
                        |> Dict.fromList
            in
            resultModelCmdSub
                ( { model | loading = newLoading, addFilesModel = cm2 }
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
                    Dict.remove fileid model.loading

                newModel =
                    { model
                        | completed = compl
                        , errored = errs
                        , loading = load
                    }
            in
            resultModel newModel

        AddFilesUploadResp fileid (Err _) ->
            let
                errs =
                    setErrored model fileid

                load =
                    Dict.remove fileid model.loading
            in
            resultModel { model | errored = errs, loading = load }

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

                newLoading =
                    Dict.insert fileid percent model.loading
            in
            resultModel
                { model | loading = newLoading }

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
            resultModelCmd ( { model | attachDD = model_ }, cmd )

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
                    resultModelCmd ( model_, Cmd.batch [ cmd_, Cmd.map ModalEditMsg mc_ ] )

                Nothing ->
                    resultModel model

        StartTagModal ->
            let
                cats =
                    Util.Tag.getCategories model.allTags
            in
            resultModel
                { model
                    | modalEdit = Just (Comp.DetailEdit.initTagByName model.item.id "" cats)
                }

        StartCorrOrgModal ->
            resultModel
                { model
                    | modalEdit =
                        Just
                            (Comp.DetailEdit.initOrg
                                model.item.id
                                Comp.OrgForm.emptyModel
                            )
                }

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
                    resultModelCmd ( { model | modalEdit = Just m }, Cmd.map ModalEditMsg c )

                Nothing ->
                    resultModel model

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
                    resultModelCmd ( { model | modalEdit = Just m }, Cmd.map ModalEditMsg c )

                Nothing ->
                    resultModel model

        StartCorrPersonModal ->
            let
                ( pm, pc ) =
                    Comp.DetailEdit.initCorrPerson
                        flags
                        model.item.id
                        Comp.PersonForm.emptyModel
            in
            resultModelCmd
                ( { model | modalEdit = Just pm }
                , Cmd.map ModalEditMsg pc
                )

        StartConcPersonModal ->
            let
                ( p, c ) =
                    Comp.DetailEdit.initConcPerson
                        flags
                        model.item.id
                        Comp.PersonForm.emptyModel
            in
            resultModelCmd
                ( { model | modalEdit = Just p }
                , Cmd.map ModalEditMsg c
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
                    resultModelCmd ( { model | modalEdit = Just m }, Cmd.map ModalEditMsg c )

                Nothing ->
                    resultModel model

        StartEquipModal ->
            resultModel
                { model
                    | modalEdit =
                        Just
                            (Comp.DetailEdit.initEquip
                                model.item.id
                                Comp.EquipmentForm.emptyModel
                            )
                }

        CloseModal ->
            resultModel { model | modalEdit = Nothing }

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
                            resultModel
                                { model
                                    | attachRename = Just (AttachmentRename id n)
                                    , attachmentDropdownOpen = False
                                }

                        Nothing ->
                            resultModel model

                Just _ ->
                    resultModel
                        { model
                            | attachRename = Nothing
                            , attachmentDropdownOpen = False
                        }

        EditAttachNameCancel ->
            resultModel { model | attachRename = Nothing }

        EditAttachNameSet str ->
            case model.attachRename of
                Just m ->
                    resultModel
                        { model | attachRename = Just { m | newName = str } }

                Nothing ->
                    resultModel model

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
                    resultModelCmd
                        ( model
                        , Api.setAttachmentName
                            flags
                            m.id
                            (Util.Maybe.fromString m.newName)
                            EditAttachNameResp
                        )

                Nothing ->
                    resultModel { model | attachRename = Nothing }

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
                        resultModel
                            { model
                                | attachRename = Nothing
                                , item = changeItem model.item
                            }

                    Nothing ->
                        resultModel model

            else
                resultModel model

        EditAttachNameResp (Err _) ->
            resultModel model

        ResetHiddenMsg _ _ ->
            resultModel model

        UpdateThrottle ->
            let
                ( newSaveName, cmd1 ) =
                    Throttle.update model.nameSaveThrottle

                ( newCustomField, cmd2 ) =
                    Throttle.update model.customFieldThrottle
            in
            withSub
                ( { model | nameSaveThrottle = newSaveName, customFieldThrottle = newCustomField }
                , Cmd.batch [ cmd1, cmd2 ]
                )

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
                        resultModelCmd ( model_, Page.set key (ItemDetailPage id) )

                    Nothing ->
                        resultModel model_

            else if keys == Just Comp.KeyInput.ctrlComma then
                case inav.prev of
                    Just id ->
                        resultModelCmd ( model_, Page.set key (ItemDetailPage id) )

                    Nothing ->
                        resultModel model_

            else
                -- withSub because the keypress may be inside the name
                -- field and requires to activate the throttle
                withSub ( model_, Cmd.none )

        ToggleAttachMenu ->
            resultModel
                { model
                    | attachMenuOpen = not model.attachMenuOpen
                    , viewMode = SimpleView
                }

        UiSettingsUpdated ->
            let
                model_ =
                    { model
                        | menuOpen = settings.editMenuVisible
                    }
            in
            resultModel model_

        SetLinkTarget lt ->
            { model = model
            , cmd = Cmd.none
            , sub = Sub.none
            , linkTarget = lt
            , removedItem = Nothing
            }

        CustomFieldMsg lm ->
            let
                result =
                    Comp.CustomFieldMultiInput.update flags lm model.customFieldsModel

                cmd_ =
                    Cmd.map CustomFieldMsg result.cmd

                loadingIcon =
                    "refresh loading icon"

                ( action_, icons ) =
                    case result.result of
                        NoFieldChange ->
                            ( Cmd.none, model.customFieldSavingIcon )

                        FieldValueRemove field ->
                            ( Api.deleteCustomValue flags
                                model.item.id
                                field.id
                                (CustomFieldRemoveResp field.id)
                            , Dict.insert field.id loadingIcon model.customFieldSavingIcon
                            )

                        FieldValueChange field value ->
                            ( Api.putCustomValue flags
                                model.item.id
                                (CustomFieldValue field.id value)
                                (CustomFieldSaveResp field value)
                            , Dict.insert field.id loadingIcon model.customFieldSavingIcon
                            )

                        FieldCreateNew ->
                            ( Cmd.none, model.customFieldSavingIcon )

                modalEdit =
                    if result.result == FieldCreateNew then
                        Just (Comp.DetailEdit.initCustomField model.item.id)

                    else
                        Nothing

                ( throttle, action ) =
                    if action_ == Cmd.none then
                        ( model.customFieldThrottle, action_ )

                    else
                        Throttle.try action_ model.customFieldThrottle

                model_ =
                    { model
                        | customFieldsModel = result.model
                        , customFieldThrottle = throttle
                        , modalEdit = modalEdit
                        , customFieldSavingIcon = icons
                    }
            in
            withSub ( model_, Cmd.batch [ cmd_, action ] )

        CustomFieldSaveResp cf fv (Ok res) ->
            let
                model_ =
                    { model | customFieldSavingIcon = Dict.remove cf.id model.customFieldSavingIcon }
            in
            if res.success then
                resultModelCmd
                    ( { model_ | item = setCustomField model.item cf fv }
                    , Cmd.none
                    )

            else
                resultModel model_

        CustomFieldSaveResp cf _ (Err _) ->
            resultModel { model | customFieldSavingIcon = Dict.remove cf.id model.customFieldSavingIcon }

        CustomFieldRemoveResp fieldId (Ok res) ->
            let
                model_ =
                    { model | customFieldSavingIcon = Dict.remove fieldId model.customFieldSavingIcon }
            in
            if res.success then
                resultModelCmd
                    ( model_
                    , Api.itemDetail flags model.item.id GetItemResp
                    )

            else
                resultModel model_

        CustomFieldRemoveResp fieldId (Err _) ->
            resultModel { model | customFieldSavingIcon = Dict.remove fieldId model.customFieldSavingIcon }

        ToggleAttachmentDropdown ->
            resultModel { model | attachmentDropdownOpen = not model.attachmentDropdownOpen }

        ToggleAkkordionTab name ->
            let
                tabs =
                    if Set.member name model.editMenuTabsOpen then
                        Set.remove name model.editMenuTabsOpen

                    else
                        Set.insert name model.editMenuTabsOpen
            in
            resultModel { model | editMenuTabsOpen = tabs }

        ToggleOpenAllAkkordionTabs ->
            let
                allNames =
                    List.map FTabState.tabName FTabState.allTabs
                        |> Set.fromList

                next =
                    if model.editMenuTabsOpen == allNames then
                        Set.empty

                    else
                        allNames
            in
            resultModel { model | editMenuTabsOpen = next }

        RequestReprocessFile id ->
            let
                model_ =
                    { model
                        | attachmentDropdownOpen = False
                        , attachModal = Just (ConfirmModalReprocessFile (ReprocessFileConfirmed id))
                    }
            in
            resultModel model_

        ReprocessFileConfirmed id ->
            let
                cmd =
                    Api.reprocessItem flags model.item.id [ id ] ReprocessFileResp
            in
            resultModelCmd ( { model | attachModal = Nothing }, cmd )

        ReprocessFileResp _ ->
            resultModel model

        RequestReprocessItem ->
            let
                model_ =
                    { model
                        | attachmentDropdownOpen = False
                        , itemModal = Just (ConfirmModalReprocessItem ReprocessItemConfirmed)
                    }
            in
            resultModel model_

        ReprocessItemConfirmed ->
            let
                cmd =
                    Api.reprocessItem flags model.item.id [] ReprocessFileResp
            in
            resultModelCmd ( { model | itemModal = Nothing }, cmd )

        ToggleSelectView ->
            let
                ( nextView, cmd ) =
                    case model.viewMode of
                        SimpleView ->
                            ( SelectView initSelectViewModel, Cmd.none )

                        SelectView _ ->
                            ( SimpleView, Cmd.none )
            in
            withSub
                ( { model
                    | viewMode = nextView
                  }
                , cmd
                )

        RestoreItem ->
            resultModelCmd ( model, Api.restoreItem flags model.item.id SaveResp )

        ToggleShowQrItem id ->
            let
                sqm =
                    model.showQrModel

                next =
                    { sqm | item = not sqm.item }
            in
            resultModel { model | showQrModel = next }

        ToggleShowQrAttach id ->
            let
                sqm =
                    model.showQrModel

                next =
                    { sqm | attach = not sqm.attach }
            in
            resultModel { model | attachmentDropdownOpen = False, showQrModel = next }

        PrintElement id ->
            resultModelCmd ( model, Ports.printElement id )



--- Helper


getOptions : Flags -> Cmd Msg
getOptions flags =
    Cmd.batch
        [ Api.getTags flags "" Data.TagOrder.NameAsc GetTagsResp
        , Api.getOrgLight flags GetOrgResp
        , Api.getPersons flags "" Data.PersonOrder.NameAsc GetPersonResp
        , Api.getEquipments flags "" Data.EquipmentOrder.NameAsc GetEquipResp
        , Api.getFolders flags "" Data.FolderOrder.NameAsc False GetFolderResp
        ]


saveTags : Flags -> Model -> Cmd Msg
saveTags flags model =
    let
        tags =
            Comp.Dropdown.getSelected model.tagModel
                |> Util.List.distinct
                |> List.map (\t -> t.id)
                |> StringList
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
            Api.setDirection flags model.item.id (DirectionValue (Data.Direction.asString d)) SaveResp

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


withSub : ( Model, Cmd Msg ) -> UpdateResult
withSub ( m, c ) =
    { model = m
    , cmd = c
    , sub =
        Sub.batch
            [ Throttle.ifNeeded
                (Time.every 200 (\_ -> UpdateThrottle))
                m.nameSaveThrottle
            , Throttle.ifNeeded
                (Time.every 200 (\_ -> UpdateThrottle))
                m.customFieldThrottle
            ]
    , linkTarget = Comp.LinkTarget.LinkNone
    , removedItem = Nothing
    }


resetField : Flags -> String -> (Field -> Result Http.Error BasicResult -> msg) -> Field -> Cmd msg
resetField flags item tagger field =
    case field of
        Data.Fields.Tag ->
            Api.setTags flags item Api.Model.StringList.empty (tagger Data.Fields.Tag)

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

        Data.Fields.PreviewImage ->
            Cmd.none

        Data.Fields.CustomFields ->
            Cmd.none

        Data.Fields.SourceName ->
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


{-| Sets the field value of the given id into the item detail.
-}
setCustomField : ItemDetail -> CustomField -> String -> ItemDetail
setCustomField item cf fv =
    let
        change ifv =
            if ifv.id == cf.id then
                ( { ifv | value = fv }, True )

            else
                ( ifv, False )

        ( fields, isChanged ) =
            List.map change item.customfields
                |> List.foldl
                    (\( e, isChange ) ->
                        \( list, flag ) -> ( e :: list, isChange || flag )
                    )
                    ( [], False )
    in
    if isChanged then
        { item | customfields = fields }

    else
        { item
            | customfields =
                ItemFieldValue cf.id cf.name cf.label cf.ftype fv :: item.customfields
        }
