module Comp.ItemDetail exposing
    ( Model
    , Msg(..)
    , emptyModel
    , update
    , view
    )

import Api
import Api.Model.Attachment exposing (Attachment)
import Api.Model.BasicResult exposing (BasicResult)
import Api.Model.DirectionValue exposing (DirectionValue)
import Api.Model.EquipmentList exposing (EquipmentList)
import Api.Model.FolderItem exposing (FolderItem)
import Api.Model.FolderList exposing (FolderList)
import Api.Model.IdName exposing (IdName)
import Api.Model.ItemDetail exposing (ItemDetail)
import Api.Model.ItemProposals exposing (ItemProposals)
import Api.Model.MoveAttachment exposing (MoveAttachment)
import Api.Model.OptionalDate exposing (OptionalDate)
import Api.Model.OptionalId exposing (OptionalId)
import Api.Model.OptionalText exposing (OptionalText)
import Api.Model.ReferenceList exposing (ReferenceList)
import Api.Model.SentMails exposing (SentMails)
import Api.Model.Tag exposing (Tag)
import Api.Model.TagList exposing (TagList)
import Browser.Navigation as Nav
import Comp.AttachmentMeta
import Comp.DatePicker
import Comp.DetailEdit
import Comp.Dropdown exposing (isDropdownChangeMsg)
import Comp.Dropzone
import Comp.EquipmentForm
import Comp.ItemMail
import Comp.MarkdownInput
import Comp.OrgForm
import Comp.PersonForm
import Comp.SentMails
import Comp.YesNoDimmer
import Data.Direction exposing (Direction)
import Data.Flags exposing (Flags)
import Data.Icons as Icons
import Data.UiSettings exposing (UiSettings)
import DatePicker exposing (DatePicker)
import Dict exposing (Dict)
import File exposing (File)
import Html exposing (..)
import Html.Attributes exposing (..)
import Html.Events exposing (onCheck, onClick, onInput)
import Html5.DragDrop as DD
import Http
import Markdown
import Page exposing (Page(..))
import Ports
import Set exposing (Set)
import Util.File exposing (makeFileId)
import Util.Folder exposing (mkFolderOption)
import Util.Http
import Util.List
import Util.Maybe
import Util.Size
import Util.String
import Util.Tag
import Util.Time


type alias Model =
    { item : ItemDetail
    , visibleAttach : Int
    , menuOpen : Bool
    , tagModel : Comp.Dropdown.Model Tag
    , directionModel : Comp.Dropdown.Model Direction
    , corrOrgModel : Comp.Dropdown.Model IdName
    , corrPersonModel : Comp.Dropdown.Model IdName
    , concPersonModel : Comp.Dropdown.Model IdName
    , concEquipModel : Comp.Dropdown.Model IdName
    , folderModel : Comp.Dropdown.Model IdName
    , allFolders : List FolderItem
    , nameModel : String
    , notesModel : Maybe String
    , notesField : NotesField
    , deleteItemConfirm : Comp.YesNoDimmer.Model
    , itemDatePicker : DatePicker
    , itemDate : Maybe Int
    , itemProposals : ItemProposals
    , dueDate : Maybe Int
    , dueDatePicker : DatePicker
    , itemMail : Comp.ItemMail.Model
    , mailOpen : Bool
    , mailSending : Bool
    , mailSendResult : Maybe BasicResult
    , sentMails : Comp.SentMails.Model
    , sentMailsOpen : Bool
    , attachMeta : Dict String Comp.AttachmentMeta.Model
    , attachMetaOpen : Bool
    , pdfNativeView : Maybe Bool
    , deleteAttachConfirm : Comp.YesNoDimmer.Model
    , addFilesOpen : Bool
    , addFilesModel : Comp.Dropzone.Model
    , selectedFiles : List File
    , completed : Set String
    , errored : Set String
    , loading : Set String
    , attachDD : DD.Model String String
    , modalEdit : Maybe Comp.DetailEdit.Model
    , attachRename : Maybe AttachmentRename
    }


type NotesField
    = ViewNotes
    | EditNotes Comp.MarkdownInput.Model
    | HideNotes


type alias AttachmentRename =
    { id : String
    , newName : String
    }


isEditNotes : NotesField -> Bool
isEditNotes field =
    case field of
        EditNotes _ ->
            True

        ViewNotes ->
            False

        HideNotes ->
            False


emptyModel : Model
emptyModel =
    { item = Api.Model.ItemDetail.empty
    , visibleAttach = 0
    , menuOpen = False
    , tagModel =
        Util.Tag.makeDropdownModel
    , directionModel =
        Comp.Dropdown.makeSingleList
            { makeOption =
                \entry ->
                    { value = Data.Direction.toString entry
                    , text = Data.Direction.toString entry
                    , additional = ""
                    }
            , options = Data.Direction.all
            , placeholder = "Choose a direction…"
            , selected = Nothing
            }
    , corrOrgModel =
        Comp.Dropdown.makeSingle
            { makeOption = \e -> { value = e.id, text = e.name, additional = "" }
            , placeholder = ""
            }
    , corrPersonModel =
        Comp.Dropdown.makeSingle
            { makeOption = \e -> { value = e.id, text = e.name, additional = "" }
            , placeholder = ""
            }
    , concPersonModel =
        Comp.Dropdown.makeSingle
            { makeOption = \e -> { value = e.id, text = e.name, additional = "" }
            , placeholder = ""
            }
    , concEquipModel =
        Comp.Dropdown.makeSingle
            { makeOption = \e -> { value = e.id, text = e.name, additional = "" }
            , placeholder = ""
            }
    , folderModel =
        Comp.Dropdown.makeSingle
            { makeOption = \e -> { value = e.id, text = e.name, additional = "" }
            , placeholder = ""
            }
    , allFolders = []
    , nameModel = ""
    , notesModel = Nothing
    , notesField = ViewNotes
    , deleteItemConfirm = Comp.YesNoDimmer.emptyModel
    , itemDatePicker = Comp.DatePicker.emptyModel
    , itemDate = Nothing
    , itemProposals = Api.Model.ItemProposals.empty
    , dueDate = Nothing
    , dueDatePicker = Comp.DatePicker.emptyModel
    , itemMail = Comp.ItemMail.emptyModel
    , mailOpen = False
    , mailSending = False
    , mailSendResult = Nothing
    , sentMails = Comp.SentMails.init
    , sentMailsOpen = False
    , attachMeta = Dict.empty
    , attachMetaOpen = False
    , pdfNativeView = Nothing
    , deleteAttachConfirm = Comp.YesNoDimmer.emptyModel
    , addFilesOpen = False
    , addFilesModel = Comp.Dropzone.init Comp.Dropzone.defaultSettings
    , selectedFiles = []
    , completed = Set.empty
    , errored = Set.empty
    , loading = Set.empty
    , attachDD = DD.init
    , modalEdit = Nothing
    , attachRename = Nothing
    }


type Msg
    = ToggleMenu
    | ReloadItem
    | Init
    | SetItem ItemDetail
    | SetActiveAttachment Int
    | TagDropdownMsg (Comp.Dropdown.Msg Tag)
    | DirDropdownMsg (Comp.Dropdown.Msg Direction)
    | OrgDropdownMsg (Comp.Dropdown.Msg IdName)
    | CorrPersonMsg (Comp.Dropdown.Msg IdName)
    | ConcPersonMsg (Comp.Dropdown.Msg IdName)
    | ConcEquipMsg (Comp.Dropdown.Msg IdName)
    | GetTagsResp (Result Http.Error TagList)
    | GetOrgResp (Result Http.Error ReferenceList)
    | GetPersonResp (Result Http.Error ReferenceList)
    | GetEquipResp (Result Http.Error EquipmentList)
    | SetName String
    | SaveName
    | SetNotes String
    | ToggleNotes
    | ToggleEditNotes
    | NotesEditMsg Comp.MarkdownInput.Msg
    | SaveNotes
    | ConfirmItem
    | UnconfirmItem
    | SetCorrOrgSuggestion IdName
    | SetCorrPersonSuggestion IdName
    | SetConcPersonSuggestion IdName
    | SetConcEquipSuggestion IdName
    | SetItemDateSuggestion Int
    | SetDueDateSuggestion Int
    | ItemDatePickerMsg Comp.DatePicker.Msg
    | DueDatePickerMsg Comp.DatePicker.Msg
    | DeleteItemConfirm Comp.YesNoDimmer.Msg
    | RequestDelete
    | SaveResp (Result Http.Error BasicResult)
    | DeleteResp (Result Http.Error BasicResult)
    | GetItemResp (Result Http.Error ItemDetail)
    | GetProposalResp (Result Http.Error ItemProposals)
    | RemoveDueDate
    | RemoveDate
    | ItemMailMsg Comp.ItemMail.Msg
    | ToggleMail
    | SendMailResp (Result Http.Error BasicResult)
    | SentMailsMsg Comp.SentMails.Msg
    | ToggleSentMails
    | SentMailsResp (Result Http.Error SentMails)
    | AttachMetaClick String
    | AttachMetaMsg String Comp.AttachmentMeta.Msg
    | TogglePdfNativeView Bool
    | RequestDeleteAttachment String
    | DeleteAttachConfirm String Comp.YesNoDimmer.Msg
    | DeleteAttachResp (Result Http.Error BasicResult)
    | AddFilesToggle
    | AddFilesMsg Comp.Dropzone.Msg
    | AddFilesSubmitUpload
    | AddFilesUploadResp String (Result Http.Error BasicResult)
    | AddFilesProgress String Http.Progress
    | AddFilesReset
    | AttachDDMsg (DD.Msg String String)
    | ModalEditMsg Comp.DetailEdit.Msg
    | StartTagModal
    | StartCorrOrgModal
    | StartCorrPersonModal
    | StartConcPersonModal
    | StartEquipModal
    | CloseModal
    | EditAttachNameStart String
    | EditAttachNameCancel
    | EditAttachNameSet String
    | EditAttachNameSubmit
    | EditAttachNameResp (Result Http.Error BasicResult)
    | GetFolderResp (Result Http.Error FolderList)
    | FolderDropdownMsg (Comp.Dropdown.Msg IdName)



--- Update


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
        Api.setItemName flags model.item.id text SaveResp


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


isLoading : Model -> File -> Bool
isLoading model file =
    Set.member (makeFileId file) model.loading


isCompleted : Model -> File -> Bool
isCompleted model file =
    Set.member (makeFileId file) model.completed


isError : Model -> File -> Bool
isError model file =
    Set.member (makeFileId file) model.errored


isIdle : Model -> File -> Bool
isIdle model file =
    not (isLoading model file || isCompleted model file || isError model file)


setCompleted : Model -> String -> Set String
setCompleted model fileid =
    Set.insert fileid model.completed


setErrored : Model -> String -> Set String
setErrored model fileid =
    Set.insert fileid model.errored


isSuccessAll : Model -> Bool
isSuccessAll model =
    List.map makeFileId model.selectedFiles
        |> List.all (\id -> Set.member id model.completed)


noSub : ( Model, Cmd Msg ) -> ( Model, Cmd Msg, Sub Msg )
noSub ( m, c ) =
    ( m, c, Sub.none )


update : Nav.Key -> Flags -> Maybe String -> Msg -> Model -> ( Model, Cmd Msg, Sub Msg )
update key flags next msg model =
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
                    update key flags next (TagDropdownMsg (Comp.Dropdown.SetSelection item.tags)) model

                ( m2, c2, s2 ) =
                    update key
                        flags
                        next
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
                        next
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
                        next
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
                        next
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
                        next
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
                    update key flags next AddFilesReset m6

                ( m8, c8, s8 ) =
                    update key
                        flags
                        next
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
                , notesModel = item.notes
                , notesField = ViewNotes
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
            noSub ( { model | nameModel = str }, Cmd.none )

        SaveName ->
            noSub ( model, setName flags model )

        SetNotes str ->
            noSub
                ( { model | notesModel = Util.Maybe.fromString str }
                , Cmd.none
                )

        ToggleNotes ->
            noSub
                ( { model
                    | notesField =
                        if model.notesField == ViewNotes then
                            HideNotes

                        else
                            ViewNotes
                  }
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

                HideNotes ->
                    noSub ( model, Cmd.none )

                ViewNotes ->
                    noSub ( model, Cmd.none )

        SaveNotes ->
            noSub ( model, setNotes flags model )

        ConfirmItem ->
            noSub ( model, Api.setConfirmed flags model.item.id SaveResp )

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
            update key flags next (DeleteItemConfirm Comp.YesNoDimmer.activate) model

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
            update key flags next (FolderDropdownMsg opts) model_

        GetFolderResp (Err _) ->
            noSub ( model, Cmd.none )

        GetTagsResp (Ok tags) ->
            let
                tagList =
                    Comp.Dropdown.SetOptions tags.items

                ( m1, c1, s1 ) =
                    update key flags next (TagDropdownMsg tagList) model
            in
            ( m1, c1, s1 )

        GetTagsResp (Err _) ->
            noSub ( model, Cmd.none )

        GetOrgResp (Ok orgs) ->
            let
                opts =
                    Comp.Dropdown.SetOptions orgs.items
            in
            update key flags next (OrgDropdownMsg opts) model

        GetOrgResp (Err _) ->
            noSub ( model, Cmd.none )

        GetPersonResp (Ok ps) ->
            let
                opts =
                    Comp.Dropdown.SetOptions ps.items

                ( m1, c1, s1 ) =
                    update key flags next (CorrPersonMsg opts) model

                ( m2, c2, s2 ) =
                    update key flags next (ConcPersonMsg opts) m1
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
            update key flags next (ConcEquipMsg opts) model

        GetEquipResp (Err _) ->
            noSub ( model, Cmd.none )

        SaveResp (Ok res) ->
            if res.success then
                noSub ( model, Api.itemDetail flags model.item.id GetItemResp )

            else
                noSub ( model, Cmd.none )

        SaveResp (Err _) ->
            noSub ( model, Cmd.none )

        DeleteResp (Ok res) ->
            if res.success then
                case next of
                    Just id ->
                        noSub ( model, Page.set key (ItemDetailPage id) )

                    Nothing ->
                        noSub ( model, Page.set key HomePage )

            else
                noSub ( model, Cmd.none )

        DeleteResp (Err _) ->
            noSub ( model, Cmd.none )

        GetItemResp (Ok item) ->
            update key flags next (SetItem item) model

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

                sendResult =
                    if newOpen then
                        model.mailSendResult

                    else
                        Nothing
            in
            noSub
                ( { model
                    | mailOpen = newOpen
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
            noSub ( { model | sentMailsOpen = not model.sentMailsOpen, visibleAttach = -1 }, Cmd.none )

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
                update key flags next ReloadItem model

            else
                noSub ( model, Cmd.none )

        DeleteAttachResp (Err _) ->
            noSub ( model, Cmd.none )

        RequestDeleteAttachment id ->
            update key
                flags
                next
                (DeleteAttachConfirm id Comp.YesNoDimmer.activate)
                model

        AddFilesToggle ->
            noSub
                ( { model | addFilesOpen = not model.addFilesOpen }
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



--- View


actionInputDatePicker : DatePicker.Settings
actionInputDatePicker =
    let
        ds =
            Comp.DatePicker.defaultSettings
    in
    { ds | containerClassList = [ ( "ui action input", True ) ] }


view : { prev : Maybe String, next : Maybe String } -> UiSettings -> Model -> Html Msg
view inav settings model =
    div []
        [ Html.map ModalEditMsg (Comp.DetailEdit.viewModal settings model.modalEdit)
        , renderItemInfo settings model
        , div
            [ classList
                [ ( "ui ablue-comp menu", True )
                , ( "top attached"
                  , model.mailOpen
                        || model.addFilesOpen
                        || isEditNotes model.notesField
                  )
                ]
            ]
            [ a [ class "item", Page.href HomePage ]
                [ i [ class "arrow left icon" ] []
                ]
            , a
                [ classList
                    [ ( "item", True )
                    , ( "disabled", inav.prev == Nothing )
                    ]
                , Maybe.map ItemDetailPage inav.prev
                    |> Maybe.map Page.href
                    |> Maybe.withDefault (href "#")
                ]
                [ i [ class "caret square left outline icon" ] []
                ]
            , a
                [ classList
                    [ ( "item", True )
                    , ( "disabled", inav.next == Nothing )
                    ]
                , Maybe.map ItemDetailPage inav.next
                    |> Maybe.map Page.href
                    |> Maybe.withDefault (href "#")
                ]
                [ i [ class "caret square right outline icon" ] []
                ]
            , a
                [ classList
                    [ ( "toggle item", True )
                    , ( "active", model.menuOpen )
                    ]
                , title "Edit Metadata"
                , onClick ToggleMenu
                , href ""
                ]
                [ i [ class "edit icon" ] []
                ]
            , a
                [ classList
                    [ ( "toggle item", True )
                    , ( "active", model.mailOpen )
                    ]
                , title "Send Mail"
                , onClick ToggleMail
                , href "#"
                ]
                [ i [ class "mail outline icon" ] []
                ]
            , a
                [ classList
                    [ ( "toggle item", True )
                    , ( "active", isEditNotes model.notesField )
                    ]
                , if isEditNotes model.notesField then
                    title "Cancel editing"

                  else
                    title "Edit Notes"
                , onClick ToggleEditNotes
                , href "#"
                ]
                [ Icons.editNotesIcon
                ]
            , a
                [ classList
                    [ ( "toggle item", True )
                    , ( "active", model.addFilesOpen )
                    ]
                , if model.addFilesOpen then
                    title "Close"

                  else
                    title "Add Files"
                , onClick AddFilesToggle
                , href "#"
                ]
                [ Icons.addFilesIcon
                ]
            ]
        , renderMailForm settings model
        , renderAddFilesForm model
        , renderNotes model
        , div [ class "ui grid" ]
            [ Html.map DeleteItemConfirm (Comp.YesNoDimmer.view model.deleteItemConfirm)
            , div
                [ classList
                    [ ( "sixteen wide mobile six wide tablet five wide computer column", True )
                    , ( "invisible", not model.menuOpen )
                    ]
                ]
                (if model.menuOpen then
                    renderEditMenu settings model

                 else
                    []
                )
            , div
                [ classList
                    [ ( "sixteen wide mobile ten wide tablet eleven wide computer column", model.menuOpen )
                    , ( "sixteen", not model.menuOpen )
                    , ( "wide column", True )
                    ]
                ]
              <|
                List.concat
                    [ [ renderAttachmentsTabMenu model
                      ]
                    , renderAttachmentsTabBody settings model
                    , renderIdInfo model
                    ]
            ]
        ]


renderIdInfo : Model -> List (Html Msg)
renderIdInfo model =
    [ div [ class "ui center aligned container" ]
        [ span [ class "small-info" ]
            [ text model.item.id
            , text " • "
            , text "Created: "
            , Util.Time.formatDateTime model.item.created |> text
            , text " • "
            , text "Updated: "
            , Util.Time.formatDateTime model.item.updated |> text
            ]
        ]
    ]


renderNotes : Model -> Html Msg
renderNotes model =
    case model.notesField of
        HideNotes ->
            case model.item.notes of
                Nothing ->
                    span [ class "invisible hidden" ] []

                Just _ ->
                    div [ class "ui segment" ]
                        [ a
                            [ class "ui top left attached label"
                            , onClick ToggleNotes
                            , href "#"
                            ]
                            [ i [ class "eye icon" ] []
                            , text "Show notes…"
                            ]
                        ]

        ViewNotes ->
            case model.item.notes of
                Nothing ->
                    span [ class "hidden invisible" ] []

                Just str ->
                    div [ class "ui raised segment item-notes-display" ]
                        [ Markdown.toHtml [ class "item-notes" ] str
                        , a
                            [ class "ui left corner label"
                            , onClick ToggleNotes
                            , href "#"
                            ]
                            [ i [ class "eye slash icon" ] []
                            ]
                        ]

        EditNotes mm ->
            div [ class "ui bottom attached segment" ]
                [ Html.map NotesEditMsg (Comp.MarkdownInput.view (Maybe.withDefault "" model.notesModel) mm)
                , div [ class "ui secondary menu" ]
                    [ a
                        [ class "link item"
                        , href "#"
                        , onClick SaveNotes
                        ]
                        [ i [ class "save outline icon" ] []
                        , text "Save"
                        ]
                    , a
                        [ class "link item"
                        , href "#"
                        , onClick ToggleEditNotes
                        ]
                        [ i [ class "cancel icon" ] []
                        , text "Cancel"
                        ]
                    ]
                ]


attachmentVisible : Model -> Int -> Bool
attachmentVisible model pos =
    if model.visibleAttach >= List.length model.item.attachments then
        pos == 0

    else
        model.visibleAttach == pos


renderAttachmentsTabMenu : Model -> Html Msg
renderAttachmentsTabMenu model =
    let
        mailTab =
            if Comp.SentMails.isEmpty model.sentMails then
                []

            else
                [ div
                    [ classList
                        [ ( "right item", True )
                        , ( "active", model.sentMailsOpen )
                        ]
                    , onClick ToggleSentMails
                    ]
                    [ text "E-Mails"
                    ]
                ]

        highlight el =
            let
                dropId =
                    DD.getDropId model.attachDD

                dragId =
                    DD.getDragId model.attachDD

                enable =
                    Just el.id == dropId && dropId /= dragId
            in
            [ ( "current-drop-target", enable )
            ]
    in
    div [ class "ui top attached tabular menu" ]
        (List.indexedMap
            (\pos ->
                \el ->
                    if attachmentVisible model pos then
                        a
                            ([ classList <|
                                [ ( "active item", True )
                                ]
                                    ++ highlight el
                             , title (Maybe.withDefault "No Name" el.name)
                             , href ""
                             ]
                                ++ DD.draggable AttachDDMsg el.id
                                ++ DD.droppable AttachDDMsg el.id
                            )
                            [ Maybe.map (Util.String.ellipsis 30) el.name
                                |> Maybe.withDefault "No Name"
                                |> text
                            , a
                                [ class "right-tab-icon-link"
                                , href "#"
                                , onClick (EditAttachNameStart el.id)
                                ]
                                [ i [ class "grey edit link icon" ] []
                                ]
                            ]

                    else
                        a
                            ([ classList <|
                                [ ( "item", True )
                                ]
                                    ++ highlight el
                             , title (Maybe.withDefault "No Name" el.name)
                             , href ""
                             , onClick (SetActiveAttachment pos)
                             ]
                                ++ DD.draggable AttachDDMsg el.id
                                ++ DD.droppable AttachDDMsg el.id
                            )
                            [ Maybe.map (Util.String.ellipsis 20) el.name
                                |> Maybe.withDefault "No Name"
                                |> text
                            ]
            )
            model.item.attachments
            ++ mailTab
        )


renderAttachmentView : UiSettings -> Model -> Int -> Attachment -> Html Msg
renderAttachmentView settings model pos attach =
    let
        fileUrl =
            "/api/v1/sec/attachment/" ++ attach.id

        attachName =
            Maybe.withDefault "No name" attach.name

        hasArchive =
            List.map .id model.item.archives
                |> List.member attach.id
    in
    div
        [ classList
            [ ( "ui attached tab segment", True )
            , ( "active", attachmentVisible model pos )
            ]
        ]
        [ Html.map (DeleteAttachConfirm attach.id) (Comp.YesNoDimmer.view model.deleteAttachConfirm)
        , renderEditAttachmentName model attach
        , div [ class "ui small secondary menu" ]
            [ div [ class "horizontally fitted item" ]
                [ i [ class "file outline icon" ] []
                , text attachName
                , text " ("
                , text (Util.Size.bytesReadable Util.Size.B (toFloat attach.size))
                , text ")"
                ]
            , div [ class "item" ]
                [ div [ class "ui slider checkbox" ]
                    [ input
                        [ type_ "checkbox"
                        , onCheck (\_ -> TogglePdfNativeView settings.nativePdfPreview)
                        , checked (Maybe.withDefault settings.nativePdfPreview model.pdfNativeView)
                        ]
                        []
                    , label [] [ text "Native view" ]
                    ]
                ]
            , div [ class "right menu" ]
                [ a
                    [ classList
                        [ ( "item", True )
                        ]
                    , title "Delete this file permanently"
                    , href "#"
                    , onClick (RequestDeleteAttachment attach.id)
                    ]
                    [ i [ class "red trash icon" ] []
                    ]
                , a
                    [ classList
                        [ ( "item", True )
                        , ( "invisible", not hasArchive )
                        ]
                    , title "Download the original archive file."
                    , href (fileUrl ++ "/archive")
                    , target "_new"
                    ]
                    [ i [ class "file archive outline icon" ] []
                    ]
                , a
                    [ classList
                        [ ( "item", True )
                        , ( "disabled", not attach.converted )
                        ]
                    , title
                        (if attach.converted then
                            case Util.List.find (\s -> s.id == attach.id) model.item.sources of
                                Just src ->
                                    "Goto original: "
                                        ++ Maybe.withDefault "<noname>" src.name

                                Nothing ->
                                    "Goto original file"

                         else
                            "The file was not converted."
                        )
                    , href (fileUrl ++ "/original")
                    , target "_new"
                    ]
                    [ i [ class "external square alternate icon" ] []
                    ]
                , a
                    [ classList
                        [ ( "toggle item", True )
                        , ( "active", isAttachMetaOpen model attach.id )
                        ]
                    , title "Show extracted data"
                    , onClick (AttachMetaClick attach.id)
                    , href "#"
                    ]
                    [ i [ class "info icon" ] []
                    ]
                , a
                    [ class "item"
                    , title "Download PDF to disk"
                    , download attachName
                    , href fileUrl
                    ]
                    [ i [ class "download icon" ] []
                    ]
                ]
            ]
        , div
            [ classList
                [ ( "ui 4:3 embed doc-embed", True )
                , ( "invisible hidden", isAttachMetaOpen model attach.id )
                ]
            ]
            [ iframe
                [ if Maybe.withDefault settings.nativePdfPreview model.pdfNativeView then
                    src fileUrl

                  else
                    src (fileUrl ++ "/view")
                ]
                []
            ]
        , div
            [ classList
                [ ( "ui basic segment", True )
                , ( "invisible hidden", not (isAttachMetaOpen model attach.id) )
                ]
            ]
            [ case Dict.get attach.id model.attachMeta of
                Just am ->
                    Html.map (AttachMetaMsg attach.id)
                        (Comp.AttachmentMeta.view am)

                Nothing ->
                    span [] []
            ]
        ]


isAttachMetaOpen : Model -> String -> Bool
isAttachMetaOpen model id =
    model.attachMetaOpen && (Dict.get id model.attachMeta /= Nothing)


renderAttachmentsTabBody : UiSettings -> Model -> List (Html Msg)
renderAttachmentsTabBody settings model =
    let
        mailTab =
            if Comp.SentMails.isEmpty model.sentMails then
                []

            else
                [ div
                    [ classList
                        [ ( "ui attached tab segment", True )
                        , ( "active", model.sentMailsOpen )
                        ]
                    ]
                    [ h3 [ class "ui header" ]
                        [ text "Sent E-Mails"
                        ]
                    , Html.map SentMailsMsg (Comp.SentMails.view model.sentMails)
                    ]
                ]
    in
    List.indexedMap (renderAttachmentView settings model) model.item.attachments
        ++ mailTab


renderItemInfo : UiSettings -> Model -> Html Msg
renderItemInfo settings model =
    let
        date =
            div
                [ class "item"
                , title "Item Date"
                ]
                [ Maybe.withDefault model.item.created model.item.itemDate
                    |> Util.Time.formatDate
                    |> text
                ]

        duedate =
            div
                [ class "item"
                , title "Due Date"
                ]
                [ Icons.dueDateIcon "grey"
                , Maybe.map Util.Time.formatDate model.item.dueDate
                    |> Maybe.withDefault ""
                    |> text
                ]

        corr =
            div
                [ class "item"
                , title "Correspondent"
                ]
                [ Icons.correspondentIcon ""
                , List.filterMap identity [ model.item.corrOrg, model.item.corrPerson ]
                    |> List.map .name
                    |> String.join ", "
                    |> Util.String.withDefault "(None)"
                    |> text
                ]

        conc =
            div
                [ class "item"
                , title "Concerning"
                ]
                [ Icons.concernedIcon
                , List.filterMap identity [ model.item.concPerson, model.item.concEquipment ]
                    |> List.map .name
                    |> String.join ", "
                    |> Util.String.withDefault "(None)"
                    |> text
                ]

        itemfolder =
            div
                [ class "item"
                , title "Folder"
                ]
                [ Icons.folderIcon ""
                , Maybe.map .name model.item.folder
                    |> Maybe.withDefault "-"
                    |> text
                ]

        src =
            div
                [ class "item"
                , title "Source"
                ]
                [ text model.item.source
                ]
    in
    div [ class "ui fluid container" ]
        (h2
            [ class "ui header"
            ]
            [ i
                [ class (Data.Direction.iconFromString model.item.direction)
                , title model.item.direction
                ]
                []
            , div [ class "content" ]
                [ text model.item.name
                , div
                    [ classList
                        [ ( "ui teal label", True )
                        , ( "invisible", model.item.state /= "created" )
                        ]
                    ]
                    [ text "New!"
                    ]
                , div [ class "sub header" ]
                    [ div [ class "ui horizontal bulleted list" ] <|
                        List.append
                            [ date
                            , corr
                            , conc
                            , itemfolder
                            , src
                            ]
                            (if Util.Maybe.isEmpty model.item.dueDate then
                                []

                             else
                                [ duedate ]
                            )
                    ]
                ]
            ]
            :: renderTags settings model
        )


renderTags : UiSettings -> Model -> List (Html Msg)
renderTags settings model =
    case model.item.tags of
        [] ->
            []

        _ ->
            [ div [ class "ui right aligned fluid container" ] <|
                List.map
                    (\t ->
                        div
                            [ classList
                                [ ( "ui tag label", True )
                                , ( Data.UiSettings.tagColorString t settings, True )
                                ]
                            ]
                            [ text t.name
                            ]
                    )
                    model.item.tags
            ]


renderEditMenu : UiSettings -> Model -> List (Html Msg)
renderEditMenu settings model =
    [ renderEditButtons model
    , renderEditForm settings model
    ]


renderEditButtons : Model -> Html Msg
renderEditButtons model =
    div [ class "ui top attached segment" ]
        [ button
            [ classList
                [ ( "ui primary button", True )
                , ( "invisible", model.item.state /= "created" )
                ]
            , onClick ConfirmItem
            ]
            [ i [ class "check icon" ] []
            , text "Confirm"
            ]
        , button
            [ classList
                [ ( "ui primary button", True )
                , ( "invisible", model.item.state /= "confirmed" )
                ]
            , onClick UnconfirmItem
            ]
            [ i [ class "eye slash outline icon" ] []
            , text "Unconfirm"
            ]
        , button [ class "ui negative button", onClick RequestDelete ]
            [ i [ class "trash icon" ] []
            , text "Delete"
            ]
        ]


renderEditForm : UiSettings -> Model -> Html Msg
renderEditForm settings model =
    let
        addIconLink tip m =
            a
                [ class "right-float"
                , href "#"
                , title tip
                , onClick m
                ]
                [ i [ class "grey plus link icon" ] []
                ]
    in
    div [ class "ui attached segment" ]
        [ div [ class "ui form warning" ]
            [ div [ class "field" ]
                [ label []
                    [ Icons.tagsIcon "grey"
                    , text "Tags"
                    , addIconLink "Add new tag" StartTagModal
                    ]
                , Html.map TagDropdownMsg (Comp.Dropdown.view settings model.tagModel)
                ]
            , div [ class " field" ]
                [ label [] [ text "Name" ]
                , div [ class "ui action input" ]
                    [ input [ type_ "text", value model.nameModel, onInput SetName ] []
                    , button
                        [ class "ui icon button"
                        , onClick SaveName
                        ]
                        [ i [ class "save outline icon" ] []
                        ]
                    ]
                ]
            , div [ class "field" ]
                [ label []
                    [ Icons.folderIcon "grey"
                    , text "Folder"
                    ]
                , Html.map FolderDropdownMsg (Comp.Dropdown.view settings model.folderModel)
                , div
                    [ classList
                        [ ( "ui warning message", True )
                        , ( "hidden", isFolderMember model )
                        ]
                    ]
                    [ Markdown.toHtml [] """
You are **not a member** of this folder. This item will be **hidden**
from any search now. Use a folder where you are a member of to make this
item visible. This message will disappear then.
                      """
                    ]
                ]
            , div [ class "field" ]
                [ label []
                    [ Icons.directionIcon "grey"
                    , text "Direction"
                    ]
                , Html.map DirDropdownMsg (Comp.Dropdown.view settings model.directionModel)
                ]
            , div [ class "field" ]
                [ label []
                    [ Icons.dateIcon "grey"
                    , text "Date"
                    ]
                , div [ class "ui action input" ]
                    [ Html.map ItemDatePickerMsg
                        (Comp.DatePicker.viewTime
                            model.itemDate
                            actionInputDatePicker
                            model.itemDatePicker
                        )
                    , a [ class "ui icon button", href "", onClick RemoveDate ]
                        [ i [ class "trash alternate outline icon" ] []
                        ]
                    ]
                , renderItemDateSuggestions model
                ]
            , div [ class " field" ]
                [ label []
                    [ Icons.dueDateIcon "grey"
                    , text "Due Date"
                    ]
                , div [ class "ui action input" ]
                    [ Html.map DueDatePickerMsg
                        (Comp.DatePicker.viewTime
                            model.dueDate
                            actionInputDatePicker
                            model.dueDatePicker
                        )
                    , a [ class "ui icon button", href "", onClick RemoveDueDate ]
                        [ i [ class "trash alternate outline icon" ] [] ]
                    ]
                , renderDueDateSuggestions model
                ]
            , h4 [ class "ui dividing header" ]
                [ Icons.correspondentIcon ""
                , text "Correspondent"
                ]
            , div [ class "field" ]
                [ label []
                    [ Icons.organizationIcon "grey"
                    , text "Organization"
                    , addIconLink "Add new organization" StartCorrOrgModal
                    ]
                , Html.map OrgDropdownMsg (Comp.Dropdown.view settings model.corrOrgModel)
                , renderOrgSuggestions model
                ]
            , div [ class "field" ]
                [ label []
                    [ Icons.personIcon "grey"
                    , text "Person"
                    , addIconLink "Add new correspondent person" StartCorrPersonModal
                    ]
                , Html.map CorrPersonMsg (Comp.Dropdown.view settings model.corrPersonModel)
                , renderCorrPersonSuggestions model
                ]
            , h4 [ class "ui dividing header" ]
                [ Icons.concernedIcon
                , text "Concerning"
                ]
            , div [ class "field" ]
                [ label []
                    [ Icons.personIcon "grey"
                    , text "Person"
                    , addIconLink "Add new concerning person" StartConcPersonModal
                    ]
                , Html.map ConcPersonMsg (Comp.Dropdown.view settings model.concPersonModel)
                , renderConcPersonSuggestions model
                ]
            , div [ class "field" ]
                [ label []
                    [ Icons.equipmentIcon "grey"
                    , text "Equipment"
                    , addIconLink "Add new equipment" StartEquipModal
                    ]
                , Html.map ConcEquipMsg (Comp.Dropdown.view settings model.concEquipModel)
                , renderConcEquipSuggestions model
                ]
            ]
        ]


renderSuggestions : Model -> (a -> String) -> List a -> (a -> Msg) -> Html Msg
renderSuggestions model mkName idnames tagger =
    div
        [ classList
            [ ( "ui secondary vertical menu", True )
            , ( "invisible", model.item.state /= "created" )
            ]
        ]
        [ div [ class "item" ]
            [ div [ class "header" ]
                [ text "Suggestions"
                ]
            , div [ class "menu" ] <|
                (idnames
                    |> List.take 5
                    |> List.map (\p -> a [ class "item", href "", onClick (tagger p) ] [ text (mkName p) ])
                )
            ]
        ]


renderOrgSuggestions : Model -> Html Msg
renderOrgSuggestions model =
    renderSuggestions model
        .name
        (List.take 5 model.itemProposals.corrOrg)
        SetCorrOrgSuggestion


renderCorrPersonSuggestions : Model -> Html Msg
renderCorrPersonSuggestions model =
    renderSuggestions model
        .name
        (List.take 5 model.itemProposals.corrPerson)
        SetCorrPersonSuggestion


renderConcPersonSuggestions : Model -> Html Msg
renderConcPersonSuggestions model =
    renderSuggestions model
        .name
        (List.take 5 model.itemProposals.concPerson)
        SetConcPersonSuggestion


renderConcEquipSuggestions : Model -> Html Msg
renderConcEquipSuggestions model =
    renderSuggestions model
        .name
        (List.take 5 model.itemProposals.concEquipment)
        SetConcEquipSuggestion


renderItemDateSuggestions : Model -> Html Msg
renderItemDateSuggestions model =
    renderSuggestions model
        Util.Time.formatDate
        (List.take 5 model.itemProposals.itemDate)
        SetItemDateSuggestion


renderDueDateSuggestions : Model -> Html Msg
renderDueDateSuggestions model =
    renderSuggestions model
        Util.Time.formatDate
        (List.take 5 model.itemProposals.dueDate)
        SetDueDateSuggestion


renderMailForm : UiSettings -> Model -> Html Msg
renderMailForm settings model =
    div
        [ classList
            [ ( "ui bottom attached segment", True )
            , ( "invisible hidden", not model.mailOpen )
            ]
        ]
        [ h4 [ class "ui header" ]
            [ text "Send this item via E-Mail"
            ]
        , div
            [ classList
                [ ( "ui dimmer", True )
                , ( "active", model.mailSending )
                ]
            ]
            [ div [ class "ui text loader" ]
                [ text "Sending …"
                ]
            ]
        , Html.map ItemMailMsg (Comp.ItemMail.view settings model.itemMail)
        , div
            [ classList
                [ ( "ui message", True )
                , ( "error"
                  , Maybe.map .success model.mailSendResult
                        |> Maybe.map not
                        |> Maybe.withDefault False
                  )
                , ( "success"
                  , Maybe.map .success model.mailSendResult
                        |> Maybe.withDefault False
                  )
                , ( "invisible hidden", model.mailSendResult == Nothing )
                ]
            ]
            [ Maybe.map .message model.mailSendResult
                |> Maybe.withDefault ""
                |> text
            ]
        ]


renderAddFilesForm : Model -> Html Msg
renderAddFilesForm model =
    div
        [ classList
            [ ( "ui bottom attached segment", True )
            , ( "invisible hidden", not model.addFilesOpen )
            ]
        ]
        [ h4 [ class "ui header" ]
            [ text "Add more files to this item"
            ]
        , Html.map AddFilesMsg (Comp.Dropzone.view model.addFilesModel)
        , button
            [ class "ui primary button"
            , href "#"
            , onClick AddFilesSubmitUpload
            ]
            [ text "Submit"
            ]
        , button
            [ class "ui secondary button"
            , href "#"
            , onClick AddFilesReset
            ]
            [ text "Reset"
            ]
        , div
            [ classList
                [ ( "ui success message", True )
                , ( "invisible hidden", model.selectedFiles == [] || not (isSuccessAll model) )
                ]
            ]
            [ text "All files have been uploaded. They are being processed, some data "
            , text "may not be available immediately. "
            , a
                [ class "link"
                , href "#"
                , onClick ReloadItem
                ]
                [ text "Refresh now"
                ]
            ]
        , div [ class "ui items" ]
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
                [ div
                    [ classList
                        [ ( "ui small indicating progress", True )
                        ]
                    , id (makeFileId file)
                    ]
                    [ div [ class "bar" ]
                        []
                    ]
                ]
            ]
        ]


renderEditAttachmentName : Model -> Attachment -> Html Msg
renderEditAttachmentName model attach =
    let
        am =
            Util.Maybe.filter (\m -> m.id == attach.id) model.attachRename
    in
    case am of
        Just m ->
            div [ class "ui fluid action input" ]
                [ input
                    [ type_ "text"
                    , value m.newName
                    , onInput EditAttachNameSet
                    ]
                    []
                , button
                    [ class "ui primary icon button"
                    , onClick EditAttachNameSubmit
                    ]
                    [ i [ class "check icon" ] []
                    ]
                , button
                    [ class "ui secondary icon button"
                    , onClick EditAttachNameCancel
                    ]
                    [ i [ class "delete icon" ] []
                    ]
                ]

        Nothing ->
            span [ class "invisible hidden" ] []


isFolderMember : Model -> Bool
isFolderMember model =
    let
        selected =
            Comp.Dropdown.getSelected model.folderModel
                |> List.head
                |> Maybe.map .id
    in
    Util.Folder.isFolderMember model.allFolders selected
