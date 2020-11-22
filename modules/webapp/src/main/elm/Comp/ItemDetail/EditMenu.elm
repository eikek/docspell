module Comp.ItemDetail.EditMenu exposing
    ( Model
    , Msg
    , SaveNameState(..)
    , defaultViewConfig
    , init
    , loadModel
    , update
    , view
    )

import Api
import Api.Model.EquipmentList exposing (EquipmentList)
import Api.Model.FolderItem exposing (FolderItem)
import Api.Model.FolderList exposing (FolderList)
import Api.Model.IdName exposing (IdName)
import Api.Model.ItemProposals exposing (ItemProposals)
import Api.Model.ReferenceList exposing (ReferenceList)
import Api.Model.Tag exposing (Tag)
import Api.Model.TagList exposing (TagList)
import Comp.CustomFieldMultiInput exposing (FieldResult(..))
import Comp.DatePicker
import Comp.DetailEdit
import Comp.Dropdown exposing (isDropdownChangeMsg)
import Comp.ItemDetail.FormChange exposing (FormChange(..))
import Data.Direction exposing (Direction)
import Data.Fields
import Data.Flags exposing (Flags)
import Data.Icons as Icons
import Data.UiSettings exposing (UiSettings)
import DatePicker exposing (DatePicker)
import Html exposing (..)
import Html.Attributes exposing (..)
import Html.Events exposing (onClick, onInput)
import Http
import Markdown
import Page exposing (Page(..))
import Task
import Throttle exposing (Throttle)
import Time
import Util.Folder exposing (mkFolderOption)
import Util.List
import Util.Maybe
import Util.Tag



--- Model


type SaveNameState
    = Saving
    | SaveSuccess
    | SaveFailed


type TagEditMode
    = AddTags
    | RemoveTags
    | ReplaceTags


type alias Model =
    { tagModel : Comp.Dropdown.Model Tag
    , nameModel : String
    , nameSaveThrottle : Throttle Msg
    , folderModel : Comp.Dropdown.Model IdName
    , allFolders : List FolderItem
    , directionModel : Comp.Dropdown.Model Direction
    , itemDatePicker : DatePicker
    , itemDate : Maybe Int
    , itemProposals : ItemProposals
    , dueDate : Maybe Int
    , dueDatePicker : DatePicker
    , corrOrgModel : Comp.Dropdown.Model IdName
    , corrPersonModel : Comp.Dropdown.Model IdName
    , concPersonModel : Comp.Dropdown.Model IdName
    , concEquipModel : Comp.Dropdown.Model IdName
    , modalEdit : Maybe Comp.DetailEdit.Model
    , tagEditMode : TagEditMode
    , customFieldModel : Comp.CustomFieldMultiInput.Model
    }


type Msg
    = ItemDatePickerMsg Comp.DatePicker.Msg
    | DueDatePickerMsg Comp.DatePicker.Msg
    | SetName String
    | SaveName
    | UpdateThrottle
    | RemoveDueDate
    | RemoveDate
    | ConfirmMsg Bool
    | ToggleTagEditMode
    | FolderDropdownMsg (Comp.Dropdown.Msg IdName)
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
    | GetFolderResp (Result Http.Error FolderList)
    | CustomFieldMsg Comp.CustomFieldMultiInput.Msg


init : Model
init =
    { tagModel =
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
    , nameSaveThrottle = Throttle.create 1
    , itemDatePicker = Comp.DatePicker.emptyModel
    , itemDate = Nothing
    , itemProposals = Api.Model.ItemProposals.empty
    , dueDate = Nothing
    , dueDatePicker = Comp.DatePicker.emptyModel
    , modalEdit = Nothing
    , tagEditMode = AddTags
    , customFieldModel = Comp.CustomFieldMultiInput.initWith []
    }


loadModel : Flags -> Cmd Msg
loadModel flags =
    let
        ( _, dpc ) =
            Comp.DatePicker.init
    in
    Cmd.batch
        [ Api.getTags flags "" GetTagsResp
        , Api.getOrgLight flags GetOrgResp
        , Api.getPersonsLight flags GetPersonResp
        , Api.getEquipments flags "" GetEquipResp
        , Api.getFolders flags "" False GetFolderResp
        , Cmd.map CustomFieldMsg (Comp.CustomFieldMultiInput.initCmd flags)
        , Cmd.map ItemDatePickerMsg dpc
        , Cmd.map DueDatePickerMsg dpc
        ]


isFolderMember : Model -> Bool
isFolderMember model =
    let
        selected =
            Comp.Dropdown.getSelected model.folderModel
                |> List.head
                |> Maybe.map .id
    in
    Util.Folder.isFolderMember model.allFolders selected



--- Update


type alias UpdateResult =
    { model : Model
    , cmd : Cmd Msg
    , sub : Sub Msg
    , change : FormChange
    }


resultNoCmd : FormChange -> Model -> UpdateResult
resultNoCmd change model =
    UpdateResult model Cmd.none Sub.none change


resultNone : Model -> UpdateResult
resultNone model =
    resultNoCmd NoFormChange model


update : Flags -> Msg -> Model -> UpdateResult
update flags msg model =
    case msg of
        ConfirmMsg flag ->
            resultNoCmd (ConfirmChange flag) model

        TagDropdownMsg m ->
            let
                ( m2, _ ) =
                    Comp.Dropdown.update m model.tagModel

                newModel =
                    { model | tagModel = m2 }

                mkChange list =
                    case model.tagEditMode of
                        AddTags ->
                            AddTagChange list

                        RemoveTags ->
                            RemoveTagChange list

                        ReplaceTags ->
                            ReplaceTagChange list

                change =
                    if isDropdownChangeMsg m then
                        Comp.Dropdown.getSelected newModel.tagModel
                            |> Util.List.distinct
                            |> List.map (\t -> IdName t.id t.name)
                            |> ReferenceList
                            |> mkChange

                    else
                        NoFormChange
            in
            resultNoCmd change newModel

        ToggleTagEditMode ->
            let
                ( m2, _ ) =
                    Comp.Dropdown.update (Comp.Dropdown.SetSelection []) model.tagModel

                newModel =
                    { model | tagModel = m2 }
            in
            case model.tagEditMode of
                AddTags ->
                    resultNone { newModel | tagEditMode = RemoveTags }

                RemoveTags ->
                    resultNone { newModel | tagEditMode = ReplaceTags }

                ReplaceTags ->
                    resultNone { newModel | tagEditMode = AddTags }

        GetTagsResp (Ok tags) ->
            let
                tagList =
                    Comp.Dropdown.SetOptions tags.items
            in
            update flags (TagDropdownMsg tagList) model

        GetTagsResp (Err _) ->
            resultNone model

        FolderDropdownMsg m ->
            let
                ( m2, _ ) =
                    Comp.Dropdown.update m model.folderModel

                newModel =
                    { model | folderModel = m2 }

                idref =
                    Comp.Dropdown.getSelected m2 |> List.head

                change =
                    if isDropdownChangeMsg m then
                        FolderChange idref

                    else
                        NoFormChange
            in
            resultNoCmd change newModel

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
            update flags (FolderDropdownMsg opts) model_

        GetFolderResp (Err _) ->
            resultNone model

        DirDropdownMsg m ->
            let
                ( m2, _ ) =
                    Comp.Dropdown.update m model.directionModel

                newModel =
                    { model | directionModel = m2 }

                change =
                    if isDropdownChangeMsg m then
                        let
                            dir =
                                Comp.Dropdown.getSelected m2 |> List.head
                        in
                        case dir of
                            Just d ->
                                DirectionChange d

                            Nothing ->
                                NoFormChange

                    else
                        NoFormChange
            in
            resultNoCmd change newModel

        OrgDropdownMsg m ->
            let
                ( m2, _ ) =
                    Comp.Dropdown.update m model.corrOrgModel

                newModel =
                    { model | corrOrgModel = m2 }

                idref =
                    Comp.Dropdown.getSelected m2 |> List.head

                change =
                    if isDropdownChangeMsg m then
                        OrgChange idref

                    else
                        NoFormChange
            in
            resultNoCmd change newModel

        GetOrgResp (Ok orgs) ->
            let
                opts =
                    Comp.Dropdown.SetOptions orgs.items
            in
            update flags (OrgDropdownMsg opts) model

        GetOrgResp (Err _) ->
            resultNone model

        CorrPersonMsg m ->
            let
                ( m2, _ ) =
                    Comp.Dropdown.update m model.corrPersonModel

                newModel =
                    { model | corrPersonModel = m2 }

                idref =
                    Comp.Dropdown.getSelected m2 |> List.head

                change =
                    if isDropdownChangeMsg m then
                        CorrPersonChange idref

                    else
                        NoFormChange
            in
            resultNoCmd change newModel

        ConcPersonMsg m ->
            let
                ( m2, _ ) =
                    Comp.Dropdown.update m model.concPersonModel

                newModel =
                    { model | concPersonModel = m2 }

                idref =
                    Comp.Dropdown.getSelected m2 |> List.head

                change =
                    if isDropdownChangeMsg m then
                        ConcPersonChange idref

                    else
                        NoFormChange
            in
            resultNoCmd change newModel

        GetPersonResp (Ok ps) ->
            let
                opts =
                    Comp.Dropdown.SetOptions ps.items

                res1 =
                    update flags (CorrPersonMsg opts) model

                res2 =
                    update flags (ConcPersonMsg opts) res1.model
            in
            res2

        GetPersonResp (Err _) ->
            resultNone model

        ConcEquipMsg m ->
            let
                ( m2, _ ) =
                    Comp.Dropdown.update m model.concEquipModel

                newModel =
                    { model | concEquipModel = m2 }

                idref =
                    Comp.Dropdown.getSelected m2 |> List.head

                change =
                    if isDropdownChangeMsg m then
                        EquipChange idref

                    else
                        NoFormChange
            in
            resultNoCmd change newModel

        GetEquipResp (Ok equips) ->
            let
                opts =
                    Comp.Dropdown.SetOptions
                        (List.map (\e -> IdName e.id e.name)
                            equips.items
                        )
            in
            update flags (ConcEquipMsg opts) model

        GetEquipResp (Err _) ->
            resultNone model

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
                    resultNoCmd (ItemDateChange newModel.itemDate) newModel

                _ ->
                    resultNone { model | itemDatePicker = dp }

        RemoveDate ->
            resultNoCmd (ItemDateChange Nothing) { model | itemDate = Nothing }

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
                    resultNoCmd (DueDateChange newModel.dueDate) newModel

                _ ->
                    resultNone { model | dueDatePicker = dp }

        RemoveDueDate ->
            resultNoCmd (DueDateChange Nothing) { model | dueDate = Nothing }

        SetName str ->
            case Util.Maybe.fromString str of
                Just newName ->
                    let
                        cmd_ =
                            Task.succeed ()
                                |> Task.perform (\_ -> SaveName)

                        ( newThrottle, cmd ) =
                            Throttle.try cmd_ model.nameSaveThrottle

                        newModel =
                            { model
                                | nameSaveThrottle = newThrottle
                                , nameModel = newName
                            }

                        sub =
                            nameThrottleSub newModel
                    in
                    UpdateResult newModel cmd sub NoFormChange

                Nothing ->
                    resultNone { model | nameModel = str }

        SaveName ->
            case Util.Maybe.fromString model.nameModel of
                Just n ->
                    resultNoCmd (NameChange n) model

                Nothing ->
                    resultNone model

        UpdateThrottle ->
            let
                ( newThrottle, cmd ) =
                    Throttle.update model.nameSaveThrottle

                newModel =
                    { model | nameSaveThrottle = newThrottle }

                sub =
                    nameThrottleSub newModel
            in
            UpdateResult newModel cmd sub NoFormChange

        CustomFieldMsg lm ->
            let
                res =
                    Comp.CustomFieldMultiInput.update lm model.customFieldModel

                model_ =
                    { model | customFieldModel = res.model }

                cmd_ =
                    Cmd.map CustomFieldMsg res.cmd

                sub_ =
                    Sub.map CustomFieldMsg res.subs

                change =
                    case res.result of
                        NoResult ->
                            NoFormChange

                        FieldValueRemove cf ->
                            RemoveCustomValue cf

                        FieldValueChange cf value ->
                            CustomValueChange cf value

                        FieldCreateNew ->
                            NoFormChange
            in
            UpdateResult model_ cmd_ sub_ change


nameThrottleSub : Model -> Sub Msg
nameThrottleSub model =
    Throttle.ifNeeded
        (Time.every 400 (\_ -> UpdateThrottle))
        model.nameSaveThrottle



--- View


type alias ViewConfig =
    { menuClass : String
    , nameState : SaveNameState
    }


defaultViewConfig : ViewConfig
defaultViewConfig =
    { menuClass = "ui vertical segment"
    , nameState = SaveSuccess
    }


view : ViewConfig -> UiSettings -> Model -> Html Msg
view =
    renderEditForm


renderEditForm : ViewConfig -> UiSettings -> Model -> Html Msg
renderEditForm cfg settings model =
    let
        fieldVisible field =
            Data.UiSettings.fieldVisible settings field

        optional fields html =
            if
                List.map fieldVisible fields
                    |> List.foldl (||) False
            then
                html

            else
                span [ class "invisible hidden" ] []

        tagModeIcon =
            case model.tagEditMode of
                AddTags ->
                    i [ class "grey plus link icon" ] []

                RemoveTags ->
                    i [ class "grey eraser link icon" ] []

                ReplaceTags ->
                    i [ class "grey redo alternate link icon" ] []

        tagModeMsg =
            case model.tagEditMode of
                AddTags ->
                    "Tags chosen here are *added* to all selected items."

                RemoveTags ->
                    "Tags chosen here are *removed* from all selected items."

                ReplaceTags ->
                    "Tags chosen here *replace* those on selected items."

        customFieldSettings =
            Comp.CustomFieldMultiInput.ViewSettings False "field"
    in
    div [ class cfg.menuClass ]
        [ div [ class "ui form warning" ]
            [ div [ class "field" ]
                [ div
                    [ class "ui fluid buttons"
                    ]
                    [ button
                        [ class "ui primary button"
                        , onClick (ConfirmMsg True)
                        ]
                        [ text "Confirm"
                        ]
                    , div [ class "or" ] []
                    , button
                        [ class "ui secondary button"
                        , onClick (ConfirmMsg False)
                        ]
                        [ text "Unconfirm"
                        ]
                    ]
                ]
            , optional [ Data.Fields.Tag ] <|
                div [ class "field" ]
                    [ label []
                        [ Icons.tagsIcon "grey"
                        , text "Tags"
                        , a
                            [ class "right-float"
                            , href "#"
                            , title "Change tag edit mode"
                            , onClick ToggleTagEditMode
                            ]
                            [ tagModeIcon
                            ]
                        ]
                    , Html.map TagDropdownMsg (Comp.Dropdown.view settings model.tagModel)
                    , Markdown.toHtml [ class "small-info" ] tagModeMsg
                    ]
            , div [ class " field" ]
                [ label [] [ text "Name" ]
                , div [ class "ui icon input" ]
                    [ input [ type_ "text", value model.nameModel, onInput SetName ] []
                    , i
                        [ classList
                            [ ( "green check icon", cfg.nameState == SaveSuccess )
                            , ( "red exclamation triangle icon", cfg.nameState == SaveFailed )
                            , ( "sync loading icon", cfg.nameState == Saving )
                            ]
                        ]
                        []
                    ]
                ]
            , optional [ Data.Fields.Folder ] <|
                div [ class "field" ]
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
            , optional [ Data.Fields.CustomFields ] <|
                h4 [ class "ui dividing header" ]
                    [ Icons.customFieldIcon ""
                    , text "Custom Fields"
                    ]
            , optional [ Data.Fields.CustomFields ] <|
                Html.map CustomFieldMsg
                    (Comp.CustomFieldMultiInput.view customFieldSettings model.customFieldModel)
            , optional [ Data.Fields.Date, Data.Fields.DueDate ] <|
                h4 [ class "ui dividing header" ]
                    [ Icons.itemDatesIcon ""
                    , text "Item Dates"
                    ]
            , optional [ Data.Fields.Date ] <|
                div [ class "field" ]
                    [ label []
                        [ Icons.dateIcon "grey"
                        , text "Date"
                        ]
                    , div [ class "ui left icon action input" ]
                        [ Html.map ItemDatePickerMsg
                            (Comp.DatePicker.viewTime
                                model.itemDate
                                actionInputDatePicker
                                model.itemDatePicker
                            )
                        , a [ class "ui icon button", href "", onClick RemoveDate ]
                            [ i [ class "trash alternate outline icon" ] []
                            ]
                        , Icons.dateIcon ""
                        ]
                    ]
            , optional [ Data.Fields.DueDate ] <|
                div [ class " field" ]
                    [ label []
                        [ Icons.dueDateIcon "grey"
                        , text "Due Date"
                        ]
                    , div [ class "ui left icon action input" ]
                        [ Html.map DueDatePickerMsg
                            (Comp.DatePicker.viewTime
                                model.dueDate
                                actionInputDatePicker
                                model.dueDatePicker
                            )
                        , a [ class "ui icon button", href "", onClick RemoveDueDate ]
                            [ i [ class "trash alternate outline icon" ] [] ]
                        , Icons.dueDateIcon ""
                        ]
                    ]
            , optional [ Data.Fields.CorrOrg, Data.Fields.CorrPerson ] <|
                h4 [ class "ui dividing header" ]
                    [ Icons.correspondentIcon ""
                    , text "Correspondent"
                    ]
            , optional [ Data.Fields.CorrOrg ] <|
                div [ class "field" ]
                    [ label []
                        [ Icons.organizationIcon "grey"
                        , text "Organization"
                        ]
                    , Html.map OrgDropdownMsg (Comp.Dropdown.view settings model.corrOrgModel)
                    ]
            , optional [ Data.Fields.CorrPerson ] <|
                div [ class "field" ]
                    [ label []
                        [ Icons.personIcon "grey"
                        , text "Person"
                        ]
                    , Html.map CorrPersonMsg (Comp.Dropdown.view settings model.corrPersonModel)
                    ]
            , optional [ Data.Fields.ConcPerson, Data.Fields.ConcEquip ] <|
                h4 [ class "ui dividing header" ]
                    [ Icons.concernedIcon
                    , text "Concerning"
                    ]
            , optional [ Data.Fields.ConcPerson ] <|
                div [ class "field" ]
                    [ label []
                        [ Icons.personIcon "grey"
                        , text "Person"
                        ]
                    , Html.map ConcPersonMsg (Comp.Dropdown.view settings model.concPersonModel)
                    ]
            , optional [ Data.Fields.ConcEquip ] <|
                div [ class "field" ]
                    [ label []
                        [ Icons.equipmentIcon "grey"
                        , text "Equipment"
                        ]
                    , Html.map ConcEquipMsg (Comp.Dropdown.view settings model.concEquipModel)
                    ]
            , optional [ Data.Fields.Direction ] <|
                div [ class "field" ]
                    [ label []
                        [ Icons.directionIcon "grey"
                        , text "Direction"
                        ]
                    , Html.map DirDropdownMsg (Comp.Dropdown.view settings model.directionModel)
                    ]
            ]
        ]


actionInputDatePicker : DatePicker.Settings
actionInputDatePicker =
    let
        ds =
            Comp.DatePicker.defaultSettings
    in
    { ds | containerClassList = [ ( "ui action input", True ) ] }
