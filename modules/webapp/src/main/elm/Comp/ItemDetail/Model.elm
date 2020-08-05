module Comp.ItemDetail.Model exposing
    ( AttachmentRename
    , Model
    , NotesField(..)
    , emptyModel
    , isEditNotes
    )

import Api.Model.BasicResult exposing (BasicResult)
import Api.Model.FolderItem exposing (FolderItem)
import Api.Model.IdName exposing (IdName)
import Api.Model.ItemDetail exposing (ItemDetail)
import Api.Model.ItemProposals exposing (ItemProposals)
import Api.Model.Tag exposing (Tag)
import Comp.AttachmentMeta
import Comp.DatePicker
import Comp.DetailEdit
import Comp.Dropdown
import Comp.Dropzone
import Comp.ItemMail
import Comp.MarkdownInput
import Comp.SentMails
import Comp.YesNoDimmer
import Data.Direction exposing (Direction)
import DatePicker exposing (DatePicker)
import Dict exposing (Dict)
import File exposing (File)
import Html exposing (..)
import Html.Attributes exposing (..)
import Html5.DragDrop as DD
import Page exposing (Page(..))
import Set exposing (Set)
import Util.Tag


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
