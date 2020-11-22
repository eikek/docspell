module Comp.SearchMenu exposing
    ( Model
    , Msg(..)
    , NextState
    , getItemSearch
    , init
    , update
    , updateDrop
    , view
    , viewDrop
    )

import Api
import Api.Model.Equipment exposing (Equipment)
import Api.Model.EquipmentList exposing (EquipmentList)
import Api.Model.FolderItem exposing (FolderItem)
import Api.Model.FolderList exposing (FolderList)
import Api.Model.IdName exposing (IdName)
import Api.Model.ItemSearch exposing (ItemSearch)
import Api.Model.ReferenceList exposing (ReferenceList)
import Api.Model.TagCloud exposing (TagCloud)
import Comp.CustomFieldMultiInput
import Comp.DatePicker
import Comp.Dropdown exposing (isDropdownChangeMsg)
import Comp.FolderSelect
import Comp.TagSelect
import Data.CustomFieldChange exposing (CustomFieldValueCollect)
import Data.Direction exposing (Direction)
import Data.Fields
import Data.Flags exposing (Flags)
import Data.Icons as Icons
import Data.UiSettings exposing (UiSettings)
import DatePicker exposing (DatePicker)
import Html exposing (..)
import Html.Attributes exposing (..)
import Html.Events exposing (onCheck, onClick, onInput)
import Http
import Util.Folder
import Util.Html exposing (KeyCode(..))
import Util.ItemDragDrop as DD
import Util.Maybe



-- Data Model


type alias Model =
    { tagSelectModel : Comp.TagSelect.Model
    , tagSelection : Comp.TagSelect.Selection
    , directionModel : Comp.Dropdown.Model Direction
    , orgModel : Comp.Dropdown.Model IdName
    , corrPersonModel : Comp.Dropdown.Model IdName
    , concPersonModel : Comp.Dropdown.Model IdName
    , concEquipmentModel : Comp.Dropdown.Model Equipment
    , folderList : Comp.FolderSelect.Model
    , selectedFolder : Maybe FolderItem
    , inboxCheckbox : Bool
    , fromDateModel : DatePicker
    , fromDate : Maybe Int
    , untilDateModel : DatePicker
    , untilDate : Maybe Int
    , fromDueDateModel : DatePicker
    , fromDueDate : Maybe Int
    , untilDueDateModel : DatePicker
    , untilDueDate : Maybe Int
    , nameModel : Maybe String
    , allNameModel : Maybe String
    , fulltextModel : Maybe String
    , datePickerInitialized : Bool
    , showNameHelp : Bool
    , customFieldModel : Comp.CustomFieldMultiInput.Model
    , customValues : CustomFieldValueCollect
    }


init : Model
init =
    { tagSelectModel = Comp.TagSelect.init Comp.TagSelect.emptySelection []
    , tagSelection = Comp.TagSelect.emptySelection
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
    , orgModel =
        Comp.Dropdown.makeModel
            { multiple = False
            , searchable = \n -> n > 0
            , makeOption = \e -> { value = e.id, text = e.name, additional = "" }
            , labelColor = \_ -> \_ -> ""
            , placeholder = "Choose an organization"
            }
    , corrPersonModel =
        Comp.Dropdown.makeSingle
            { makeOption = \e -> { value = e.id, text = e.name, additional = "" }
            , placeholder = "Choose a person"
            }
    , concPersonModel =
        Comp.Dropdown.makeSingle
            { makeOption = \e -> { value = e.id, text = e.name, additional = "" }
            , placeholder = "Choose a person"
            }
    , concEquipmentModel =
        Comp.Dropdown.makeModel
            { multiple = False
            , searchable = \n -> n > 0
            , makeOption = \e -> { value = e.id, text = e.name, additional = "" }
            , labelColor = \_ -> \_ -> ""
            , placeholder = "Choose an equipment"
            }
    , folderList = Comp.FolderSelect.init Nothing []
    , selectedFolder = Nothing
    , inboxCheckbox = False
    , fromDateModel = Comp.DatePicker.emptyModel
    , fromDate = Nothing
    , untilDateModel = Comp.DatePicker.emptyModel
    , untilDate = Nothing
    , fromDueDateModel = Comp.DatePicker.emptyModel
    , fromDueDate = Nothing
    , untilDueDateModel = Comp.DatePicker.emptyModel
    , untilDueDate = Nothing
    , nameModel = Nothing
    , allNameModel = Nothing
    , fulltextModel = Nothing
    , datePickerInitialized = False
    , showNameHelp = False
    , customFieldModel = Comp.CustomFieldMultiInput.initWith []
    , customValues = Data.CustomFieldChange.emptyCollect
    }


getDirection : Model -> Maybe Direction
getDirection model =
    let
        selection =
            Comp.Dropdown.getSelected model.directionModel
    in
    case selection of
        [ d ] ->
            Just d

        _ ->
            Nothing


getItemSearch : Model -> ItemSearch
getItemSearch model =
    let
        e =
            Api.Model.ItemSearch.empty

        amendWildcards s =
            if String.startsWith "\"" s && String.endsWith "\"" s then
                String.dropLeft 1 s
                    |> String.dropRight 1

            else if String.contains "*" s then
                s

            else
                "*" ++ s ++ "*"
    in
    { e
        | tagsInclude = model.tagSelection.includeTags |> List.map .tag |> List.map .id
        , tagsExclude = model.tagSelection.excludeTags |> List.map .tag |> List.map .id
        , corrPerson = Comp.Dropdown.getSelected model.corrPersonModel |> List.map .id |> List.head
        , corrOrg = Comp.Dropdown.getSelected model.orgModel |> List.map .id |> List.head
        , concPerson = Comp.Dropdown.getSelected model.concPersonModel |> List.map .id |> List.head
        , concEquip = Comp.Dropdown.getSelected model.concEquipmentModel |> List.map .id |> List.head
        , folder = model.selectedFolder |> Maybe.map .id
        , direction =
            Comp.Dropdown.getSelected model.directionModel
                |> List.head
                |> Maybe.map Data.Direction.toString
        , inbox = model.inboxCheckbox
        , dateFrom = model.fromDate
        , dateUntil = model.untilDate
        , dueDateFrom = model.fromDueDate
        , dueDateUntil = model.untilDueDate
        , name =
            model.nameModel
                |> Maybe.map amendWildcards
        , allNames =
            model.allNameModel
                |> Maybe.map amendWildcards
        , fullText = model.fulltextModel
        , tagCategoriesInclude = model.tagSelection.includeCats |> List.map .name
        , tagCategoriesExclude = model.tagSelection.excludeCats |> List.map .name
        , customValues = Data.CustomFieldChange.toFieldValues model.customValues
    }


resetModel : Model -> Model
resetModel model =
    let
        emptyDropdown dm =
            Comp.Dropdown.update (Comp.Dropdown.SetSelection []) dm
                |> Tuple.first

        emptyFolder fm =
            Comp.FolderSelect.deselect fm
                |> Maybe.map (\msg -> Comp.FolderSelect.update msg fm)
                |> Maybe.map Tuple.first
                |> Maybe.withDefault fm
    in
    { model
        | tagSelection = Comp.TagSelect.emptySelection
        , tagSelectModel = Comp.TagSelect.reset model.tagSelectModel
        , directionModel = emptyDropdown model.directionModel
        , orgModel = emptyDropdown model.orgModel
        , corrPersonModel = emptyDropdown model.corrPersonModel
        , concPersonModel = emptyDropdown model.concPersonModel
        , concEquipmentModel = emptyDropdown model.concEquipmentModel
        , folderList = emptyFolder model.folderList
        , selectedFolder = Nothing
        , inboxCheckbox = False
        , fromDate = Nothing
        , untilDate = Nothing
        , fromDueDate = Nothing
        , untilDueDate = Nothing
        , nameModel = Nothing
        , allNameModel = Nothing
        , fulltextModel = Nothing
        , customFieldModel =
            Comp.CustomFieldMultiInput.reset
                model.customFieldModel
        , customValues = Data.CustomFieldChange.emptyCollect
    }



-- Update


type Msg
    = Init
    | TagSelectMsg Comp.TagSelect.Msg
    | DirectionMsg (Comp.Dropdown.Msg Direction)
    | OrgMsg (Comp.Dropdown.Msg IdName)
    | CorrPersonMsg (Comp.Dropdown.Msg IdName)
    | ConcPersonMsg (Comp.Dropdown.Msg IdName)
    | ConcEquipmentMsg (Comp.Dropdown.Msg Equipment)
    | FromDateMsg Comp.DatePicker.Msg
    | UntilDateMsg Comp.DatePicker.Msg
    | FromDueDateMsg Comp.DatePicker.Msg
    | UntilDueDateMsg Comp.DatePicker.Msg
    | ToggleInbox
    | GetTagsResp (Result Http.Error TagCloud)
    | GetOrgResp (Result Http.Error ReferenceList)
    | GetEquipResp (Result Http.Error EquipmentList)
    | GetPersonResp (Result Http.Error ReferenceList)
    | SetName String
    | SetAllName String
    | SetFulltext String
    | ResetForm
    | KeyUpMsg (Maybe KeyCode)
    | ToggleNameHelp
    | FolderSelectMsg Comp.FolderSelect.Msg
    | GetFolderResp (Result Http.Error FolderList)
    | SetCorrOrg IdName
    | SetCorrPerson IdName
    | SetConcPerson IdName
    | SetConcEquip IdName
    | SetFolder IdName
    | SetTag String
    | CustomFieldMsg Comp.CustomFieldMultiInput.Msg


type alias NextState =
    { model : Model
    , cmd : Cmd Msg
    , stateChange : Bool
    , dragDrop : DD.DragDropData
    }


update : Flags -> UiSettings -> Msg -> Model -> NextState
update =
    updateDrop DD.init


updateDrop : DD.Model -> Flags -> UiSettings -> Msg -> Model -> NextState
updateDrop ddm flags settings msg model =
    let
        resetAndSet : Msg -> NextState
        resetAndSet m =
            let
                reset =
                    resetModel model

                set =
                    updateDrop ddm
                        flags
                        settings
                        m
                        reset
            in
            { model = set.model
            , cmd = set.cmd
            , stateChange = True
            , dragDrop = set.dragDrop
            }
    in
    case msg of
        Init ->
            let
                ( dp, dpc ) =
                    Comp.DatePicker.init

                ( mdp, cdp ) =
                    if model.datePickerInitialized then
                        ( model, Cmd.none )

                    else
                        ( { model
                            | untilDateModel = dp
                            , fromDateModel = dp
                            , untilDueDateModel = dp
                            , fromDueDateModel = dp
                            , datePickerInitialized = True
                          }
                        , Cmd.batch
                            [ Cmd.map UntilDateMsg dpc
                            , Cmd.map FromDateMsg dpc
                            , Cmd.map UntilDueDateMsg dpc
                            , Cmd.map FromDueDateMsg dpc
                            ]
                        )
            in
            { model = mdp
            , cmd =
                Cmd.batch
                    [ Api.getTagCloud flags GetTagsResp
                    , Api.getOrgLight flags GetOrgResp
                    , Api.getEquipments flags "" GetEquipResp
                    , Api.getPersonsLight flags GetPersonResp
                    , Api.getFolders flags "" False GetFolderResp
                    , Cmd.map CustomFieldMsg (Comp.CustomFieldMultiInput.initCmd flags)
                    , cdp
                    ]
            , stateChange = False
            , dragDrop = DD.DragDropData ddm Nothing
            }

        ResetForm ->
            { model = resetModel model
            , cmd = Cmd.none
            , stateChange = True
            , dragDrop = DD.DragDropData ddm Nothing
            }

        SetCorrOrg id ->
            resetAndSet (OrgMsg (Comp.Dropdown.SetSelection [ id ]))

        SetCorrPerson id ->
            resetAndSet (CorrPersonMsg (Comp.Dropdown.SetSelection [ id ]))

        SetConcPerson id ->
            resetAndSet (ConcPersonMsg (Comp.Dropdown.SetSelection [ id ]))

        SetFolder id ->
            case Comp.FolderSelect.setSelected id.id model.folderList of
                Just lm ->
                    resetAndSet (FolderSelectMsg lm)

                Nothing ->
                    { model = model
                    , cmd = Cmd.none
                    , stateChange = False
                    , dragDrop = DD.DragDropData ddm Nothing
                    }

        SetConcEquip id ->
            let
                equip =
                    Equipment id.id id.name 0
            in
            resetAndSet (ConcEquipmentMsg (Comp.Dropdown.SetSelection [ equip ]))

        SetTag id ->
            resetAndSet (TagSelectMsg (Comp.TagSelect.toggleTag id))

        GetTagsResp (Ok tags) ->
            let
                selectModel =
                    List.sortBy .count tags.items
                        |> List.reverse
                        |> Comp.TagSelect.init model.tagSelection

                model_ =
                    { model | tagSelectModel = selectModel }
            in
            { model = model_
            , cmd = Cmd.none
            , stateChange = False
            , dragDrop = DD.DragDropData ddm Nothing
            }

        GetTagsResp (Err _) ->
            { model = model
            , cmd = Cmd.none
            , stateChange = False
            , dragDrop = DD.DragDropData ddm Nothing
            }

        GetEquipResp (Ok equips) ->
            let
                opts =
                    Comp.Dropdown.SetOptions equips.items
            in
            update flags settings (ConcEquipmentMsg opts) model

        GetEquipResp (Err _) ->
            { model = model
            , cmd = Cmd.none
            , stateChange = False
            , dragDrop = DD.DragDropData ddm Nothing
            }

        GetOrgResp (Ok orgs) ->
            let
                opts =
                    Comp.Dropdown.SetOptions orgs.items
            in
            update flags settings (OrgMsg opts) model

        GetOrgResp (Err _) ->
            { model = model
            , cmd = Cmd.none
            , stateChange = False
            , dragDrop = DD.DragDropData ddm Nothing
            }

        GetPersonResp (Ok ps) ->
            let
                opts =
                    Comp.Dropdown.SetOptions ps.items

                next1 =
                    updateDrop ddm flags settings (CorrPersonMsg opts) model

                next2 =
                    updateDrop next1.dragDrop.model flags settings (ConcPersonMsg opts) next1.model
            in
            next2

        GetPersonResp (Err _) ->
            { model = model
            , cmd = Cmd.none
            , stateChange = False
            , dragDrop = DD.DragDropData ddm Nothing
            }

        TagSelectMsg m ->
            let
                ( m_, sel, ddd ) =
                    Comp.TagSelect.updateDrop ddm m model.tagSelectModel
            in
            { model =
                { model
                    | tagSelectModel = m_
                    , tagSelection = sel
                }
            , cmd = Cmd.none
            , stateChange = sel /= model.tagSelection
            , dragDrop = ddd
            }

        DirectionMsg m ->
            let
                ( m2, c2 ) =
                    Comp.Dropdown.update m model.directionModel
            in
            { model = { model | directionModel = m2 }
            , cmd = Cmd.map DirectionMsg c2
            , stateChange = isDropdownChangeMsg m
            , dragDrop = DD.DragDropData ddm Nothing
            }

        OrgMsg m ->
            let
                ( m2, c2 ) =
                    Comp.Dropdown.update m model.orgModel
            in
            { model = { model | orgModel = m2 }
            , cmd = Cmd.map OrgMsg c2
            , stateChange = isDropdownChangeMsg m
            , dragDrop = DD.DragDropData ddm Nothing
            }

        CorrPersonMsg m ->
            let
                ( m2, c2 ) =
                    Comp.Dropdown.update m model.corrPersonModel
            in
            { model = { model | corrPersonModel = m2 }
            , cmd = Cmd.map CorrPersonMsg c2
            , stateChange = isDropdownChangeMsg m
            , dragDrop = DD.DragDropData ddm Nothing
            }

        ConcPersonMsg m ->
            let
                ( m2, c2 ) =
                    Comp.Dropdown.update m model.concPersonModel
            in
            { model = { model | concPersonModel = m2 }
            , cmd = Cmd.map ConcPersonMsg c2
            , stateChange = isDropdownChangeMsg m
            , dragDrop = DD.DragDropData ddm Nothing
            }

        ConcEquipmentMsg m ->
            let
                ( m2, c2 ) =
                    Comp.Dropdown.update m model.concEquipmentModel
            in
            { model = { model | concEquipmentModel = m2 }
            , cmd = Cmd.map ConcEquipmentMsg c2
            , stateChange = isDropdownChangeMsg m
            , dragDrop = DD.DragDropData ddm Nothing
            }

        ToggleInbox ->
            let
                current =
                    model.inboxCheckbox
            in
            { model = { model | inboxCheckbox = not current }
            , cmd = Cmd.none
            , stateChange = True
            , dragDrop = DD.DragDropData ddm Nothing
            }

        FromDateMsg m ->
            let
                ( dp, event ) =
                    Comp.DatePicker.updateDefault m model.fromDateModel

                nextDate =
                    case event of
                        DatePicker.Picked date ->
                            Just (Comp.DatePicker.startOfDay date)

                        _ ->
                            Nothing
            in
            { model = { model | fromDateModel = dp, fromDate = nextDate }
            , cmd = Cmd.none
            , stateChange = model.fromDate /= nextDate
            , dragDrop = DD.DragDropData ddm Nothing
            }

        UntilDateMsg m ->
            let
                ( dp, event ) =
                    Comp.DatePicker.updateDefault m model.untilDateModel

                nextDate =
                    case event of
                        DatePicker.Picked date ->
                            Just (Comp.DatePicker.endOfDay date)

                        _ ->
                            Nothing
            in
            { model = { model | untilDateModel = dp, untilDate = nextDate }
            , cmd = Cmd.none
            , stateChange = model.untilDate /= nextDate
            , dragDrop = DD.DragDropData ddm Nothing
            }

        FromDueDateMsg m ->
            let
                ( dp, event ) =
                    Comp.DatePicker.updateDefault m model.fromDueDateModel

                nextDate =
                    case event of
                        DatePicker.Picked date ->
                            Just (Comp.DatePicker.startOfDay date)

                        _ ->
                            Nothing
            in
            { model = { model | fromDueDateModel = dp, fromDueDate = nextDate }
            , cmd = Cmd.none
            , stateChange = model.fromDueDate /= nextDate
            , dragDrop = DD.DragDropData ddm Nothing
            }

        UntilDueDateMsg m ->
            let
                ( dp, event ) =
                    Comp.DatePicker.updateDefault m model.untilDueDateModel

                nextDate =
                    case event of
                        DatePicker.Picked date ->
                            Just (Comp.DatePicker.endOfDay date)

                        _ ->
                            Nothing
            in
            { model = { model | untilDueDateModel = dp, untilDueDate = nextDate }
            , cmd = Cmd.none
            , stateChange = model.untilDueDate /= nextDate
            , dragDrop = DD.DragDropData ddm Nothing
            }

        SetName str ->
            let
                next =
                    Util.Maybe.fromString str
            in
            { model = { model | nameModel = next }
            , cmd = Cmd.none
            , stateChange = False
            , dragDrop = DD.DragDropData ddm Nothing
            }

        SetAllName str ->
            let
                next =
                    Util.Maybe.fromString str
            in
            { model = { model | allNameModel = next }
            , cmd = Cmd.none
            , stateChange = False
            , dragDrop = DD.DragDropData ddm Nothing
            }

        SetFulltext str ->
            let
                next =
                    Util.Maybe.fromString str
            in
            { model = { model | fulltextModel = next }
            , cmd = Cmd.none
            , stateChange = False
            , dragDrop = DD.DragDropData ddm Nothing
            }

        KeyUpMsg (Just Enter) ->
            { model = model
            , cmd = Cmd.none
            , stateChange = True
            , dragDrop = DD.DragDropData ddm Nothing
            }

        KeyUpMsg _ ->
            { model = model
            , cmd = Cmd.none
            , stateChange = False
            , dragDrop = DD.DragDropData ddm Nothing
            }

        ToggleNameHelp ->
            { model = { model | showNameHelp = not model.showNameHelp }
            , cmd = Cmd.none
            , stateChange = False
            , dragDrop = DD.DragDropData ddm Nothing
            }

        GetFolderResp (Ok fs) ->
            let
                model_ =
                    { model
                        | folderList =
                            Util.Folder.onlyVisible flags fs.items
                                |> Comp.FolderSelect.init model.selectedFolder
                    }
            in
            { model = model_
            , cmd = Cmd.none
            , stateChange = False
            , dragDrop = DD.DragDropData ddm Nothing
            }

        GetFolderResp (Err _) ->
            { model = model
            , cmd = Cmd.none
            , stateChange = False
            , dragDrop = DD.DragDropData ddm Nothing
            }

        FolderSelectMsg lm ->
            let
                ( fsm, sel, ddd ) =
                    Comp.FolderSelect.updateDrop ddm lm model.folderList
            in
            { model =
                { model
                    | folderList = fsm
                    , selectedFolder = sel
                }
            , cmd = Cmd.none
            , stateChange = model.selectedFolder /= sel
            , dragDrop = ddd
            }

        CustomFieldMsg lm ->
            let
                res =
                    Comp.CustomFieldMultiInput.update lm model.customFieldModel
            in
            { model =
                { model
                    | customFieldModel = res.model
                    , customValues = Data.CustomFieldChange.collectValues res.result model.customValues
                }
            , cmd = Cmd.map CustomFieldMsg res.cmd
            , stateChange =
                Data.CustomFieldChange.isValueChange res.result
            , dragDrop = DD.DragDropData ddm Nothing
            }



-- View


view : Flags -> UiSettings -> Model -> Html Msg
view =
    viewDrop (DD.DragDropData DD.init Nothing)


viewDrop : DD.DragDropData -> Flags -> UiSettings -> Model -> Html Msg
viewDrop ddd flags settings model =
    let
        formHeader icon headline =
            div [ class "ui tiny header" ]
                [ icon
                , div [ class "content" ]
                    [ text headline
                    ]
                ]

        segmentClass =
            "ui vertical segment"

        fieldVisible field =
            Data.UiSettings.fieldVisible settings field

        fieldHidden field =
            Data.UiSettings.fieldHidden settings field

        optional fields html =
            if
                List.map fieldVisible fields
                    |> List.foldl (||) False
            then
                html

            else
                span [ class "invisible hidden" ] []
    in
    div [ class "ui form" ]
        [ div [ class segmentClass ]
            [ div [ class "inline field" ]
                [ div [ class "ui checkbox" ]
                    [ input
                        [ type_ "checkbox"
                        , onCheck (\_ -> ToggleInbox)
                        , checked model.inboxCheckbox
                        ]
                        []
                    , label []
                        [ text "Only New"
                        ]
                    ]
                ]
            ]
        , div
            [ classList
                [ ( segmentClass, True )
                , ( "invisible hidden", fieldHidden Data.Fields.Tag && fieldHidden Data.Fields.Folder )
                ]
            ]
            [ optional [ Data.Fields.Tag ] <|
                Html.map TagSelectMsg (Comp.TagSelect.viewTagsDrop ddd.model settings model.tagSelectModel)
            , optional [ Data.Fields.Tag ] <|
                Html.map TagSelectMsg (Comp.TagSelect.viewCats settings model.tagSelectModel)
            , optional [ Data.Fields.Folder ] <|
                Html.map FolderSelectMsg
                    (Comp.FolderSelect.viewDrop ddd.model settings.searchMenuFolderCount model.folderList)
            ]
        , div
            [ classList
                [ ( segmentClass, True )
                , ( "hidden invisible", fieldHidden Data.Fields.CorrOrg && fieldHidden Data.Fields.CorrPerson )
                ]
            ]
            [ optional
                [ Data.Fields.CorrOrg
                , Data.Fields.CorrPerson
                ]
              <|
                formHeader (Icons.correspondentIcon "")
                    (case getDirection model of
                        Just Data.Direction.Incoming ->
                            "Sender"

                        Just Data.Direction.Outgoing ->
                            "Recipient"

                        Nothing ->
                            "Correspondent"
                    )
            , optional [ Data.Fields.CorrOrg ] <|
                div [ class "field" ]
                    [ label [] [ text "Organization" ]
                    , Html.map OrgMsg (Comp.Dropdown.view settings model.orgModel)
                    ]
            , optional [ Data.Fields.CorrPerson ] <|
                div [ class "field" ]
                    [ label [] [ text "Person" ]
                    , Html.map CorrPersonMsg (Comp.Dropdown.view settings model.corrPersonModel)
                    ]
            , optional
                [ Data.Fields.ConcPerson
                , Data.Fields.ConcEquip
                ]
              <|
                formHeader Icons.concernedIcon "Concerned"
            , optional [ Data.Fields.ConcPerson ] <|
                div [ class "field" ]
                    [ label [] [ text "Person" ]
                    , Html.map ConcPersonMsg (Comp.Dropdown.view settings model.concPersonModel)
                    ]
            , optional [ Data.Fields.ConcEquip ] <|
                div [ class "field" ]
                    [ label [] [ text "Equipment" ]
                    , Html.map ConcEquipmentMsg (Comp.Dropdown.view settings model.concEquipmentModel)
                    ]
            ]
        , div
            [ classList
                [ ( segmentClass, True )
                , ( "hidden invisible"
                  , fieldHidden Data.Fields.CustomFields
                        || Comp.CustomFieldMultiInput.isEmpty model.customFieldModel
                  )
                ]
            ]
            [ formHeader (Icons.customFieldIcon "") "Custom Fields"
            , Html.map CustomFieldMsg
                (Comp.CustomFieldMultiInput.view
                    (Comp.CustomFieldMultiInput.ViewSettings False "field")
                    model.customFieldModel
                )
            ]
        , div [ class segmentClass ]
            [ formHeader (Icons.searchIcon "") "Text Search"
            , div
                [ classList
                    [ ( "field", True )
                    , ( "invisible hidden", not flags.config.fullTextSearchEnabled )
                    ]
                ]
                [ label [] [ text "Fulltext Search" ]
                , input
                    [ type_ "text"
                    , onInput SetFulltext
                    , Util.Html.onKeyUpCode KeyUpMsg
                    , model.fulltextModel |> Maybe.withDefault "" |> value
                    , placeholder "Fulltext search in results…"
                    ]
                    []
                , span [ class "small-info" ]
                    [ text "Fulltext search in document contents and notes."
                    ]
                ]
            , div [ class "field" ]
                [ label []
                    [ text "Names"
                    , a
                        [ class "right-float"
                        , href "#"
                        , onClick ToggleNameHelp
                        ]
                        [ i [ class "small grey help link icon" ] []
                        ]
                    ]
                , input
                    [ type_ "text"
                    , onInput SetAllName
                    , Util.Html.onKeyUpCode KeyUpMsg
                    , model.allNameModel |> Maybe.withDefault "" |> value
                    , placeholder "Search in various names…"
                    ]
                    []
                , span
                    [ classList
                        [ ( "small-info", True )
                        ]
                    ]
                    [ text "Looks in correspondents, concerned entities, item name and notes."
                    ]
                , p
                    [ classList
                        [ ( "small-info", True )
                        , ( "invisible hidden", not model.showNameHelp )
                        ]
                    ]
                    [ text "Use wildcards "
                    , code [] [ text "*" ]
                    , text " at beginning or end. They are added automatically on both sides "
                    , text "if not present in the search term and the term is not quoted. Press "
                    , em [] [ text "Enter" ]
                    , text " to start searching."
                    ]
                ]
            ]
        , div
            [ classList
                [ ( segmentClass, True )
                , ( "invisible hidden", fieldHidden Data.Fields.Date && fieldHidden Data.Fields.DueDate )
                ]
            ]
            [ optional [ Data.Fields.Date ] <|
                formHeader (Icons.dateIcon "") "Date"
            , optional [ Data.Fields.Date ] <|
                div [ class "fields" ]
                    [ div [ class "field" ]
                        [ label []
                            [ text "From"
                            ]
                        , Html.map FromDateMsg
                            (Comp.DatePicker.viewTimeDefault
                                model.fromDate
                                model.fromDateModel
                            )
                        ]
                    , div [ class "field" ]
                        [ label []
                            [ text "To"
                            ]
                        , Html.map UntilDateMsg
                            (Comp.DatePicker.viewTimeDefault
                                model.untilDate
                                model.untilDateModel
                            )
                        ]
                    ]
            , optional [ Data.Fields.DueDate ] <|
                formHeader (Icons.dueDateIcon "") "Due Date"
            , optional [ Data.Fields.DueDate ] <|
                div [ class "fields" ]
                    [ div [ class "field" ]
                        [ label []
                            [ text "Due From"
                            ]
                        , Html.map FromDueDateMsg
                            (Comp.DatePicker.viewTimeDefault
                                model.fromDueDate
                                model.fromDueDateModel
                            )
                        ]
                    , div [ class "field" ]
                        [ label []
                            [ text "Due To"
                            ]
                        , Html.map UntilDueDateMsg
                            (Comp.DatePicker.viewTimeDefault
                                model.untilDueDate
                                model.untilDueDateModel
                            )
                        ]
                    ]
            ]
        , div
            [ classList
                [ ( segmentClass, True )
                , ( "invisible hidden", fieldHidden Data.Fields.Direction )
                ]
            ]
            [ formHeader (Icons.directionIcon "") "Direction"
            , div [ class "field" ]
                [ Html.map DirectionMsg (Comp.Dropdown.view settings model.directionModel)
                ]
            ]
        ]
