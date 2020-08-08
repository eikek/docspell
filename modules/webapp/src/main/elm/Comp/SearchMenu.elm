module Comp.SearchMenu exposing
    ( Model
    , Msg(..)
    , NextState
    , getItemSearch
    , init
    , update
    , view
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
import Comp.DatePicker
import Comp.Dropdown exposing (isDropdownChangeMsg)
import Comp.FolderSelect
import Comp.TagSelect
import Data.Direction exposing (Direction)
import Data.Flags exposing (Flags)
import Data.Icons as Icons
import Data.UiSettings exposing (UiSettings)
import DatePicker exposing (DatePicker)
import Html exposing (..)
import Html.Attributes exposing (..)
import Html.Events exposing (onCheck, onClick, onInput)
import Http
import Util.Html exposing (KeyCode(..))
import Util.Maybe
import Util.Update



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
    }


init : Model
init =
    { tagSelectModel = Comp.TagSelect.init []
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
            , searchable = \n -> n > 5
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
            , searchable = \n -> n > 5
            , makeOption = \e -> { value = e.id, text = e.name, additional = "" }
            , labelColor = \_ -> \_ -> ""
            , placeholder = "Choose an equipment"
            }
    , folderList = Comp.FolderSelect.init []
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
    }


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
    }



-- Update


type alias NextState =
    { modelCmd : ( Model, Cmd Msg )
    , stateChange : Bool
    }


noChange : ( Model, Cmd Msg ) -> NextState
noChange p =
    NextState p False


update : Flags -> UiSettings -> Msg -> Model -> NextState
update flags settings msg model =
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
            noChange
                ( mdp
                , Cmd.batch
                    [ Api.getTagCloud flags GetTagsResp
                    , Api.getOrgLight flags GetOrgResp
                    , Api.getEquipments flags "" GetEquipResp
                    , Api.getPersonsLight flags GetPersonResp
                    , Api.getFolders flags "" False GetFolderResp
                    , cdp
                    ]
                )

        ResetForm ->
            let
                next =
                    update flags settings Init init
            in
            { next | stateChange = True }

        GetTagsResp (Ok tags) ->
            let
                selectModel =
                    List.sortBy .count tags.items
                        |> List.reverse
                        |> Comp.TagSelect.init

                model_ =
                    { model | tagSelectModel = selectModel }
            in
            noChange ( model_, Cmd.none )

        GetTagsResp (Err _) ->
            noChange ( model, Cmd.none )

        GetEquipResp (Ok equips) ->
            let
                opts =
                    Comp.Dropdown.SetOptions equips.items
            in
            update flags settings (ConcEquipmentMsg opts) model

        GetEquipResp (Err _) ->
            noChange ( model, Cmd.none )

        GetOrgResp (Ok orgs) ->
            let
                opts =
                    Comp.Dropdown.SetOptions orgs.items
            in
            update flags settings (OrgMsg opts) model

        GetOrgResp (Err _) ->
            noChange ( model, Cmd.none )

        GetPersonResp (Ok ps) ->
            let
                opts =
                    Comp.Dropdown.SetOptions ps.items
            in
            noChange <|
                Util.Update.andThen1
                    [ update flags settings (CorrPersonMsg opts) >> .modelCmd
                    , update flags settings (ConcPersonMsg opts) >> .modelCmd
                    ]
                    model

        GetPersonResp (Err _) ->
            noChange ( model, Cmd.none )

        TagSelectMsg m ->
            let
                ( m_, sel ) =
                    Comp.TagSelect.update m model.tagSelectModel
            in
            NextState
                ( { model
                    | tagSelectModel = m_
                    , tagSelection = sel
                  }
                , Cmd.none
                )
                (sel /= model.tagSelection)

        DirectionMsg m ->
            let
                ( m2, c2 ) =
                    Comp.Dropdown.update m model.directionModel
            in
            NextState
                ( { model | directionModel = m2 }
                , Cmd.map DirectionMsg c2
                )
                (isDropdownChangeMsg m)

        OrgMsg m ->
            let
                ( m2, c2 ) =
                    Comp.Dropdown.update m model.orgModel
            in
            NextState
                ( { model | orgModel = m2 }
                , Cmd.map OrgMsg c2
                )
                (isDropdownChangeMsg m)

        CorrPersonMsg m ->
            let
                ( m2, c2 ) =
                    Comp.Dropdown.update m model.corrPersonModel
            in
            NextState
                ( { model | corrPersonModel = m2 }
                , Cmd.map CorrPersonMsg c2
                )
                (isDropdownChangeMsg m)

        ConcPersonMsg m ->
            let
                ( m2, c2 ) =
                    Comp.Dropdown.update m model.concPersonModel
            in
            NextState
                ( { model | concPersonModel = m2 }
                , Cmd.map ConcPersonMsg c2
                )
                (isDropdownChangeMsg m)

        ConcEquipmentMsg m ->
            let
                ( m2, c2 ) =
                    Comp.Dropdown.update m model.concEquipmentModel
            in
            NextState
                ( { model | concEquipmentModel = m2 }
                , Cmd.map ConcEquipmentMsg c2
                )
                (isDropdownChangeMsg m)

        ToggleInbox ->
            let
                current =
                    model.inboxCheckbox
            in
            NextState ( { model | inboxCheckbox = not current }, Cmd.none ) True

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
            NextState
                ( { model | fromDateModel = dp, fromDate = nextDate }
                , Cmd.none
                )
                (model.fromDate /= nextDate)

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
            NextState
                ( { model | untilDateModel = dp, untilDate = nextDate }
                , Cmd.none
                )
                (model.untilDate /= nextDate)

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
            NextState
                ( { model | fromDueDateModel = dp, fromDueDate = nextDate }
                , Cmd.none
                )
                (model.fromDueDate /= nextDate)

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
            NextState
                ( { model | untilDueDateModel = dp, untilDueDate = nextDate }
                , Cmd.none
                )
                (model.untilDueDate /= nextDate)

        SetName str ->
            let
                next =
                    Util.Maybe.fromString str
            in
            NextState
                ( { model | nameModel = next }
                , Cmd.none
                )
                False

        SetAllName str ->
            let
                next =
                    Util.Maybe.fromString str
            in
            NextState
                ( { model | allNameModel = next }
                , Cmd.none
                )
                False

        SetFulltext str ->
            let
                next =
                    Util.Maybe.fromString str
            in
            NextState
                ( { model | fulltextModel = next }
                , Cmd.none
                )
                False

        KeyUpMsg (Just Enter) ->
            NextState ( model, Cmd.none ) True

        KeyUpMsg _ ->
            NextState ( model, Cmd.none ) False

        ToggleNameHelp ->
            NextState ( { model | showNameHelp = not model.showNameHelp }, Cmd.none ) False

        GetFolderResp (Ok fs) ->
            let
                model_ =
                    { model | folderList = Comp.FolderSelect.init fs.items }
            in
            NextState
                ( model_, Cmd.none )
                False

        GetFolderResp (Err _) ->
            noChange ( model, Cmd.none )

        FolderSelectMsg lm ->
            let
                ( fsm, sel ) =
                    Comp.FolderSelect.update lm model.folderList
            in
            NextState
                ( { model
                    | folderList = fsm
                    , selectedFolder = sel
                  }
                , Cmd.none
                )
                (model.selectedFolder /= sel)



-- View


view : Flags -> UiSettings -> Model -> Html Msg
view flags settings model =
    let
        formHeader icon headline =
            div [ class "ui small dividing header" ]
                [ icon
                , div [ class "content" ]
                    [ text headline
                    ]
                ]

        formHeaderHelp icon headline tagger =
            div [ class "ui small dividing header" ]
                [ a
                    [ class "right-float"
                    , href "#"
                    , onClick tagger
                    ]
                    [ i [ class "small grey help link icon" ] []
                    ]
                , icon
                , div [ class "content" ]
                    [ text headline
                    ]
                ]

        nameIcon =
            i [ class "left align icon" ] []
    in
    div [ class "ui form" ]
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
        , Html.map TagSelectMsg (Comp.TagSelect.view settings model.tagSelectModel)
        , Html.map FolderSelectMsg
            (Comp.FolderSelect.view settings.searchMenuFolderCount model.folderList)
        , formHeaderHelp nameIcon "Names" ToggleNameHelp
        , span
            [ classList
                [ ( "small-info", True )
                , ( "invisible hidden", not model.showNameHelp )
                ]
            ]
            [ text "Use wildcards "
            , code [] [ text "*" ]
            , text " at beginning or end. Added automatically if not "
            , text "present and not quoted. Press "
            , em [] [ text "Enter" ]
            , text " to start searching."
            ]
        , div [ class "field" ]
            [ input
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
                    , ( "invisible hidden", not model.showNameHelp )
                    ]
                ]
                [ text "Looks in correspondents, concerned entities, item name and notes."
                ]
            ]
        , formHeader (Icons.correspondentIcon "")
            (case getDirection model of
                Just Data.Direction.Incoming ->
                    "Sender"

                Just Data.Direction.Outgoing ->
                    "Recipient"

                Nothing ->
                    "Correspondent"
            )
        , div [ class "field" ]
            [ label [] [ text "Organization" ]
            , Html.map OrgMsg (Comp.Dropdown.view settings model.orgModel)
            ]
        , div [ class "field" ]
            [ label [] [ text "Person" ]
            , Html.map CorrPersonMsg (Comp.Dropdown.view settings model.corrPersonModel)
            ]
        , formHeader Icons.concernedIcon "Concerned"
        , div [ class "field" ]
            [ label [] [ text "Person" ]
            , Html.map ConcPersonMsg (Comp.Dropdown.view settings model.concPersonModel)
            ]
        , div [ class "field" ]
            [ label [] [ text "Equipment" ]
            , Html.map ConcEquipmentMsg (Comp.Dropdown.view settings model.concEquipmentModel)
            ]
        , formHeader (Icons.searchIcon "") "Content"
        , div
            [ classList
                [ ( "field", True )
                , ( "invisible hidden", not flags.config.fullTextSearchEnabled )
                ]
            ]
            [ input
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
        , formHeader (Icons.dateIcon "") "Date"
        , div [ class "fields" ]
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
        , formHeader (Icons.dueDateIcon "") "Due Date"
        , div [ class "fields" ]
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
        , formHeader (Icons.directionIcon "") "Direction"
        , div [ class "field" ]
            [ Html.map DirectionMsg (Comp.Dropdown.view settings model.directionModel)
            ]
        ]
