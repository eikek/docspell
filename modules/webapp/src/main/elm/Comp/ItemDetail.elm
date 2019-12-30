module Comp.ItemDetail exposing
    ( Model
    , Msg(..)
    , emptyModel
    , update
    , view
    )

import Api
import Api.Model.BasicResult exposing (BasicResult)
import Api.Model.DirectionValue exposing (DirectionValue)
import Api.Model.EquipmentList exposing (EquipmentList)
import Api.Model.IdName exposing (IdName)
import Api.Model.ItemDetail exposing (ItemDetail)
import Api.Model.ItemProposals exposing (ItemProposals)
import Api.Model.OptionalDate exposing (OptionalDate)
import Api.Model.OptionalId exposing (OptionalId)
import Api.Model.OptionalText exposing (OptionalText)
import Api.Model.ReferenceList exposing (ReferenceList)
import Api.Model.Tag exposing (Tag)
import Api.Model.TagList exposing (TagList)
import Browser.Navigation as Nav
import Comp.DatePicker
import Comp.Dropdown exposing (isDropdownChangeMsg)
import Comp.YesNoDimmer
import Data.Direction exposing (Direction)
import Data.Flags exposing (Flags)
import DatePicker exposing (DatePicker)
import Html exposing (..)
import Html.Attributes exposing (..)
import Html.Events exposing (onClick, onInput)
import Http
import Markdown
import Page exposing (Page(..))
import Util.Maybe
import Util.Size
import Util.String
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
    , nameModel : String
    , notesModel : Maybe String
    , notesHidden : Bool
    , deleteConfirm : Comp.YesNoDimmer.Model
    , itemDatePicker : DatePicker
    , itemDate : Maybe Int
    , itemProposals : ItemProposals
    , dueDate : Maybe Int
    , dueDatePicker : DatePicker
    }


emptyModel : Model
emptyModel =
    { item = Api.Model.ItemDetail.empty
    , visibleAttach = 0
    , menuOpen = False
    , tagModel =
        Comp.Dropdown.makeMultiple
            { makeOption = \tag -> { value = tag.id, text = tag.name }
            , labelColor =
                \tag ->
                    if Util.Maybe.nonEmpty tag.category then
                        "basic blue"

                    else
                        ""
            }
    , directionModel =
        Comp.Dropdown.makeSingleList
            { makeOption =
                \entry ->
                    { value = Data.Direction.toString entry
                    , text = Data.Direction.toString entry
                    }
            , options = Data.Direction.all
            , placeholder = "Choose a direction…"
            , selected = Nothing
            }
    , corrOrgModel =
        Comp.Dropdown.makeSingle
            { makeOption = \e -> { value = e.id, text = e.name }
            , placeholder = ""
            }
    , corrPersonModel =
        Comp.Dropdown.makeSingle
            { makeOption = \e -> { value = e.id, text = e.name }
            , placeholder = ""
            }
    , concPersonModel =
        Comp.Dropdown.makeSingle
            { makeOption = \e -> { value = e.id, text = e.name }
            , placeholder = ""
            }
    , concEquipModel =
        Comp.Dropdown.makeSingle
            { makeOption = \e -> { value = e.id, text = e.name }
            , placeholder = ""
            }
    , nameModel = ""
    , notesModel = Nothing
    , notesHidden = False
    , deleteConfirm = Comp.YesNoDimmer.emptyModel
    , itemDatePicker = Comp.DatePicker.emptyModel
    , itemDate = Nothing
    , itemProposals = Api.Model.ItemProposals.empty
    , dueDate = Nothing
    , dueDatePicker = Comp.DatePicker.emptyModel
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
    | YesNoMsg Comp.YesNoDimmer.Msg
    | RequestDelete
    | SaveResp (Result Http.Error BasicResult)
    | DeleteResp (Result Http.Error BasicResult)
    | GetItemResp (Result Http.Error ItemDetail)
    | GetProposalResp (Result Http.Error ItemProposals)
    | RemoveDueDate
    | RemoveDate



-- update


getOptions : Flags -> Cmd Msg
getOptions flags =
    Cmd.batch
        [ Api.getTags flags GetTagsResp
        , Api.getOrgLight flags GetOrgResp
        , Api.getPersonsLight flags GetPersonResp
        , Api.getEquipments flags GetEquipResp
        ]


saveTags : Flags -> Model -> Cmd Msg
saveTags flags model =
    let
        tags =
            Comp.Dropdown.getSelected model.tagModel
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
    if model.notesModel == Nothing then
        Cmd.none

    else
        Api.setItemNotes flags model.item.id text SaveResp


setDate : Flags -> Model -> Maybe Int -> Cmd Msg
setDate flags model date =
    Api.setItemDate flags model.item.id (OptionalDate date) SaveResp


setDueDate : Flags -> Model -> Maybe Int -> Cmd Msg
setDueDate flags model date =
    Api.setItemDueDate flags model.item.id (OptionalDate date) SaveResp


update : Nav.Key -> Flags -> Maybe String -> Msg -> Model -> ( Model, Cmd Msg )
update key flags next msg model =
    case msg of
        Init ->
            let
                ( dp, dpc ) =
                    Comp.DatePicker.init
            in
            ( { model | itemDatePicker = dp, dueDatePicker = dp }
            , Cmd.batch
                [ getOptions flags
                , Cmd.map ItemDatePickerMsg dpc
                , Cmd.map DueDatePickerMsg dpc
                ]
            )

        SetItem item ->
            let
                ( m1, c1 ) =
                    update key flags next (TagDropdownMsg (Comp.Dropdown.SetSelection item.tags)) model

                ( m2, c2 ) =
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

                ( m3, c3 ) =
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

                ( m4, c4 ) =
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

                ( m5, c5 ) =
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

                proposalCmd =
                    if item.state == "created" then
                        Api.getItemProposals flags item.id GetProposalResp

                    else
                        Cmd.none
            in
            ( { m5
                | item = item
                , nameModel = item.name
                , notesModel = item.notes
                , itemDate = item.itemDate
                , dueDate = item.dueDate
              }
            , Cmd.batch [ c1, c2, c3, c4, c5, getOptions flags, proposalCmd ]
            )

        SetActiveAttachment pos ->
            ( { model | visibleAttach = pos }, Cmd.none )

        ToggleMenu ->
            ( { model | menuOpen = not model.menuOpen }, Cmd.none )

        ReloadItem ->
            if model.item.id == "" then
                ( model, Cmd.none )

            else
                ( model, Api.itemDetail flags model.item.id GetItemResp )

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
            ( newModel, Cmd.batch [ save, Cmd.map TagDropdownMsg c2 ] )

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
            ( newModel, Cmd.batch [ save, Cmd.map DirDropdownMsg c2 ] )

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
            ( newModel, Cmd.batch [ save, Cmd.map OrgDropdownMsg c2 ] )

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
            ( newModel, Cmd.batch [ save, Cmd.map CorrPersonMsg c2 ] )

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
            ( newModel, Cmd.batch [ save, Cmd.map ConcPersonMsg c2 ] )

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
            ( newModel, Cmd.batch [ save, Cmd.map ConcEquipMsg c2 ] )

        SetName str ->
            ( { model | nameModel = str }, Cmd.none )

        SaveName ->
            ( model, setName flags model )

        SetNotes str ->
            ( { model
                | notesModel =
                    if str == "" then
                        Nothing

                    else
                        Just str
              }
            , Cmd.none
            )

        ToggleNotes ->
            ( { model | notesHidden = not model.notesHidden }
            , Cmd.none
            )

        SaveNotes ->
            ( model, setNotes flags model )

        ConfirmItem ->
            ( model, Api.setConfirmed flags model.item.id SaveResp )

        UnconfirmItem ->
            ( model, Api.setUnconfirmed flags model.item.id SaveResp )

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
                    ( newModel, setDate flags newModel newModel.itemDate )

                _ ->
                    ( { model | itemDatePicker = dp }, Cmd.none )

        RemoveDate ->
            ( { model | itemDate = Nothing }, setDate flags model Nothing )

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
                    ( newModel, setDueDate flags newModel newModel.dueDate )

                _ ->
                    ( { model | dueDatePicker = dp }, Cmd.none )

        RemoveDueDate ->
            ( { model | dueDate = Nothing }, setDueDate flags model Nothing )

        YesNoMsg m ->
            let
                ( cm, confirmed ) =
                    Comp.YesNoDimmer.update m model.deleteConfirm

                cmd =
                    if confirmed then
                        Api.deleteItem flags model.item.id DeleteResp

                    else
                        Cmd.none
            in
            ( { model | deleteConfirm = cm }, cmd )

        RequestDelete ->
            update key flags next (YesNoMsg Comp.YesNoDimmer.activate) model

        SetCorrOrgSuggestion idname ->
            ( model, setCorrOrg flags model (Just idname) )

        SetCorrPersonSuggestion idname ->
            ( model, setCorrPerson flags model (Just idname) )

        SetConcPersonSuggestion idname ->
            ( model, setConcPerson flags model (Just idname) )

        SetConcEquipSuggestion idname ->
            ( model, setConcEquip flags model (Just idname) )

        SetItemDateSuggestion date ->
            ( model, setDate flags model (Just date) )

        SetDueDateSuggestion date ->
            ( model, setDueDate flags model (Just date) )

        GetTagsResp (Ok tags) ->
            let
                tagList =
                    Comp.Dropdown.SetOptions tags.items

                ( m1, c1 ) =
                    update key flags next (TagDropdownMsg tagList) model
            in
            ( m1, c1 )

        GetTagsResp (Err _) ->
            ( model, Cmd.none )

        GetOrgResp (Ok orgs) ->
            let
                opts =
                    Comp.Dropdown.SetOptions orgs.items
            in
            update key flags next (OrgDropdownMsg opts) model

        GetOrgResp (Err _) ->
            ( model, Cmd.none )

        GetPersonResp (Ok ps) ->
            let
                opts =
                    Comp.Dropdown.SetOptions ps.items

                ( m1, c1 ) =
                    update key flags next (CorrPersonMsg opts) model

                ( m2, c2 ) =
                    update key flags next (ConcPersonMsg opts) m1
            in
            ( m2, Cmd.batch [ c1, c2 ] )

        GetPersonResp (Err _) ->
            ( model, Cmd.none )

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
            ( model, Cmd.none )

        SaveResp (Ok res) ->
            if res.success then
                ( model, Api.itemDetail flags model.item.id GetItemResp )

            else
                ( model, Cmd.none )

        SaveResp (Err _) ->
            ( model, Cmd.none )

        DeleteResp (Ok res) ->
            if res.success then
                case next of
                    Just id ->
                        ( model, Page.set key (ItemDetailPage id) )

                    Nothing ->
                        ( model, Page.set key HomePage )

            else
                ( model, Cmd.none )

        DeleteResp (Err _) ->
            ( model, Cmd.none )

        GetItemResp (Ok item) ->
            update key flags next (SetItem item) model

        GetItemResp (Err _) ->
            ( model, Cmd.none )

        GetProposalResp (Ok ip) ->
            ( { model | itemProposals = ip }, Cmd.none )

        GetProposalResp (Err _) ->
            ( model, Cmd.none )



-- view


actionInputDatePicker : DatePicker.Settings
actionInputDatePicker =
    let
        ds =
            Comp.DatePicker.defaultSettings
    in
    { ds | containerClassList = [ ( "ui action input", True ) ] }


view : { prev : Maybe String, next : Maybe String } -> Model -> Html Msg
view inav model =
    div []
        [ renderItemInfo model
        , div
            [ classList
                [ ( "ui ablue-comp menu", True )
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
                , title "Expand Menu"
                , onClick ToggleMenu
                , href ""
                ]
                [ i [ class "edit icon" ] []
                ]
            ]
        , div [ class "ui grid" ]
            [ Html.map YesNoMsg (Comp.YesNoDimmer.view model.deleteConfirm)
            , div
                [ classList
                    [ ( "four wide column", True )
                    , ( "invisible", not model.menuOpen )
                    ]
                ]
                (if model.menuOpen then
                    renderEditMenu model

                 else
                    []
                )
            , div
                [ classList
                    [ ( "twelve", model.menuOpen )
                    , ( "sixteen", not model.menuOpen )
                    , ( "wide column", True )
                    ]
                ]
              <|
                List.concat
                    [ renderNotes model
                    , [ renderAttachmentsTabMenu model
                      ]
                    , renderAttachmentsTabBody model
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


renderNotes : Model -> List (Html Msg)
renderNotes model =
    case model.item.notes of
        Nothing ->
            []

        Just str ->
            if model.notesHidden then
                [ div [ class "ui segment" ]
                    [ a
                        [ class "ui top left attached label"
                        , onClick ToggleNotes
                        , href "#"
                        ]
                        [ i [ class "eye icon" ] []
                        , text "Show notes…"
                        ]
                    ]
                ]

            else
                [ div [ class "ui segment" ]
                    [ Markdown.toHtml [ class "item-notes" ] str
                    , a
                        [ class "ui right corner label"
                        , onClick ToggleNotes
                        , href "#"
                        ]
                        [ i [ class "delete icon" ] []
                        ]
                    ]
                ]


renderAttachmentsTabMenu : Model -> Html Msg
renderAttachmentsTabMenu model =
    div [ class "ui top attached tabular menu" ]
        (List.indexedMap
            (\pos ->
                \a ->
                    div
                        [ classList
                            [ ( "item", True )
                            , ( "active", pos == model.visibleAttach )
                            ]
                        , onClick (SetActiveAttachment pos)
                        ]
                        [ a.name |> Maybe.withDefault "No Name" |> text
                        , text " ("
                        , text (Util.Size.bytesReadable Util.Size.B (toFloat a.size))
                        , text ")"
                        ]
            )
            model.item.attachments
        )


renderAttachmentsTabBody : Model -> List (Html Msg)
renderAttachmentsTabBody model =
    List.indexedMap
        (\pos ->
            \a ->
                div
                    [ classList
                        [ ( "ui attached tab segment", True )
                        , ( "active", pos == model.visibleAttach )
                        ]
                    ]
                    [ div [ class "ui 4:3 embed doc-embed" ]
                        [ embed [ src ("/api/v1/sec/attachment/" ++ a.id), type_ a.contentType ]
                            []
                        ]
                    ]
        )
        model.item.attachments


renderItemInfo : Model -> Html Msg
renderItemInfo model =
    let
        date =
            div [ class "item" ]
                [ Maybe.withDefault model.item.created model.item.itemDate
                    |> Util.Time.formatDate
                    |> text
                ]

        duedate =
            div [ class "item" ]
                [ i [ class "bell icon" ] []
                , Maybe.map Util.Time.formatDate model.item.dueDate
                    |> Maybe.withDefault ""
                    |> text
                ]

        corr =
            div [ class "item" ]
                [ i [ class "envelope outline icon" ] []
                , List.filterMap identity [ model.item.corrOrg, model.item.corrPerson ]
                    |> List.map .name
                    |> String.join ", "
                    |> Util.String.withDefault "(None)"
                    |> text
                ]

        conc =
            div [ class "item" ]
                [ i [ class "comment outline icon" ] []
                , List.filterMap identity [ model.item.concPerson, model.item.concEquipment ]
                    |> List.map .name
                    |> String.join ", "
                    |> Util.String.withDefault "(None)"
                    |> text
                ]

        src =
            div [ class "item" ]
                [ text model.item.source
                ]
    in
    div [ class "ui fluid container" ]
        (h2 [ class "ui header" ]
            [ i [ class (Data.Direction.iconFromString model.item.direction) ] []
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
            :: renderTags model
        )


renderTags : Model -> List (Html Msg)
renderTags model =
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
                                , ( "blue", Util.Maybe.nonEmpty t.category )
                                ]
                            ]
                            [ text t.name
                            ]
                    )
                    model.item.tags
            ]


renderEditMenu : Model -> List (Html Msg)
renderEditMenu model =
    [ renderEditButtons model
    , renderEditForm model
    ]


renderEditButtons : Model -> Html Msg
renderEditButtons model =
    div [ class "ui top attached right aligned segment" ]
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
            [ i [ class "delete icon" ] []
            , text "Delete"
            ]
        ]


renderEditForm : Model -> Html Msg
renderEditForm model =
    div [ class "ui attached segment" ]
        [ div [ class "ui form" ]
            [ div [ class "field" ]
                [ label []
                    [ i [ class "tags icon" ] []
                    , text "Tags"
                    ]
                , Html.map TagDropdownMsg (Comp.Dropdown.view model.tagModel)
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
                [ label [] [ text "Direction" ]
                , Html.map DirDropdownMsg (Comp.Dropdown.view model.directionModel)
                ]
            , div [ class " field" ]
                [ label [] [ text "Date" ]
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
                [ label [] [ text "Due Date" ]
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
                [ i [ class "tiny envelope outline icon" ] []
                , text "Correspondent"
                ]
            , div [ class "field" ]
                [ label [] [ text "Organization" ]
                , Html.map OrgDropdownMsg (Comp.Dropdown.view model.corrOrgModel)
                , renderOrgSuggestions model
                ]
            , div [ class "field" ]
                [ label [] [ text "Person" ]
                , Html.map CorrPersonMsg (Comp.Dropdown.view model.corrPersonModel)
                , renderCorrPersonSuggestions model
                ]
            , h4 [ class "ui dividing header" ]
                [ i [ class "tiny comment outline icon" ] []
                , text "Concerning"
                ]
            , div [ class "field" ]
                [ label [] [ text "Person" ]
                , Html.map ConcPersonMsg (Comp.Dropdown.view model.concPersonModel)
                , renderConcPersonSuggestions model
                ]
            , div [ class "field" ]
                [ label [] [ text "Equipment" ]
                , Html.map ConcEquipMsg (Comp.Dropdown.view model.concEquipModel)
                , renderConcEquipSuggestions model
                ]
            , h4 [ class "ui dividing header" ]
                [ i [ class "tiny edit icon" ] []
                , div [ class "content" ]
                    [ text "Notes"
                    , div [ class "sub header" ]
                        [ a
                            [ class "ui link"
                            , target "_blank"
                            , href "https://guides.github.com/features/mastering-markdown"
                            ]
                            [ text "Markdown"
                            ]
                        , text " is supported"
                        ]
                    ]
                ]
            , div [ class "field" ]
                [ div [ class "ui action input" ]
                    [ textarea
                        [ rows 6
                        , autocomplete False
                        , onInput SetNotes
                        ]
                        [ Maybe.withDefault "" model.notesModel |> text ]
                    , button [ class "ui icon button", onClick SaveNotes ]
                        [ i [ class "save outline icon" ] []
                        ]
                    ]
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
