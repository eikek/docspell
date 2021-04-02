module Comp.ScanMailboxForm exposing
    ( Action(..)
    , Model
    , Msg
    , init
    , initWith
    , update
    , view2
    )

import Api
import Api.Model.BasicResult exposing (BasicResult)
import Api.Model.FolderItem exposing (FolderItem)
import Api.Model.FolderList exposing (FolderList)
import Api.Model.IdName exposing (IdName)
import Api.Model.ImapSettingsList exposing (ImapSettingsList)
import Api.Model.ScanMailboxSettings exposing (ScanMailboxSettings)
import Api.Model.StringList exposing (StringList)
import Api.Model.Tag exposing (Tag)
import Api.Model.TagList exposing (TagList)
import Comp.Basic as B
import Comp.CalEventInput
import Comp.Dropdown exposing (isDropdownChangeMsg)
import Comp.FixedDropdown
import Comp.IntField
import Comp.MenuBar as MB
import Comp.StringListInput
import Comp.Tabs
import Comp.YesNoDimmer
import Data.CalEvent exposing (CalEvent)
import Data.Direction exposing (Direction(..))
import Data.DropdownStyle as DS
import Data.Flags exposing (Flags)
import Data.Language exposing (Language)
import Data.UiSettings exposing (UiSettings)
import Data.Validated exposing (Validated(..))
import Html exposing (..)
import Html.Attributes exposing (..)
import Html.Events exposing (onCheck, onClick, onInput)
import Http
import Markdown
import Messages.LanguageData
import Set exposing (Set)
import Styles as S
import Util.Folder exposing (mkFolderOption)
import Util.Http
import Util.List
import Util.Maybe
import Util.Tag
import Util.Update


type alias Model =
    { settings : ScanMailboxSettings
    , connectionModel : Comp.Dropdown.Model String
    , enabled : Bool
    , deleteMail : Bool
    , receivedHours : Maybe Int
    , receivedHoursModel : Comp.IntField.Model
    , targetFolder : Maybe String
    , foldersModel : Comp.StringListInput.Model
    , folders : List String
    , direction : Maybe Direction
    , schedule : Validated CalEvent
    , scheduleModel : Comp.CalEventInput.Model
    , formMsg : Maybe BasicResult
    , loading : Int
    , yesNoDelete : Comp.YesNoDimmer.Model
    , folderModel : Comp.Dropdown.Model IdName
    , allFolders : List FolderItem
    , itemFolderId : Maybe String
    , tagModel : Comp.Dropdown.Model Tag
    , existingTags : List String
    , fileFilter : Maybe String
    , subjectFilter : Maybe String
    , languageModel : Comp.FixedDropdown.Model Language
    , language : Maybe Language
    , postHandleAll : Bool
    , summary : Maybe String
    , openTabs : Set String
    }


type Action
    = SubmitAction ScanMailboxSettings
    | StartOnceAction ScanMailboxSettings
    | CancelAction
    | DeleteAction String
    | NoAction


type MenuTab
    = TabGeneral
    | TabProcessing
    | TabAdditionalFilter
    | TabPostProcessing
    | TabMetadata
    | TabSchedule


type Msg
    = Submit
    | Cancel
    | RequestDelete
    | ConnMsg (Comp.Dropdown.Msg String)
    | ConnResp (Result Http.Error ImapSettingsList)
    | ToggleEnabled
    | ToggleDeleteMail
    | CalEventMsg Comp.CalEventInput.Msg
    | StartOnce
    | ReceivedHoursMsg Comp.IntField.Msg
    | SetTargetFolder String
    | FoldersMsg Comp.StringListInput.Msg
    | DirectionMsg (Maybe Direction)
    | YesNoDeleteMsg Comp.YesNoDimmer.Msg
    | GetFolderResp (Result Http.Error FolderList)
    | FolderDropdownMsg (Comp.Dropdown.Msg IdName)
    | GetTagResp (Result Http.Error TagList)
    | TagDropdownMsg (Comp.Dropdown.Msg Tag)
    | SetFileFilter String
    | SetSubjectFilter String
    | LanguageMsg (Comp.FixedDropdown.Msg Language)
    | RemoveLanguage
    | TogglePostHandleAll
    | ToggleAkkordionTab String
    | SetSummary String


initWith : Flags -> ScanMailboxSettings -> ( Model, Cmd Msg )
initWith flags s =
    let
        ( im, _ ) =
            init flags

        imap =
            Util.Maybe.fromString s.imapConnection
                |> Maybe.map List.singleton
                |> Maybe.withDefault []

        ( nm, _, nc ) =
            update flags (ConnMsg (Comp.Dropdown.SetSelection imap)) im

        newSchedule =
            Data.CalEvent.fromEvent s.schedule
                |> Maybe.withDefault Data.CalEvent.everyMonth

        ( sm, sc ) =
            Comp.CalEventInput.init flags newSchedule
    in
    ( { nm
        | settings = s
        , enabled = s.enabled
        , deleteMail = s.deleteMail
        , receivedHours = s.receivedSinceHours
        , targetFolder = s.targetFolder
        , folders = s.folders
        , schedule = Data.Validated.Unknown newSchedule
        , direction = Maybe.andThen Data.Direction.fromString s.direction
        , scheduleModel = sm
        , formMsg = Nothing
        , yesNoDelete = Comp.YesNoDimmer.emptyModel
        , itemFolderId = s.itemFolder
        , tagModel = Util.Tag.makeDropdownModel
        , existingTags =
            Maybe.map .items s.tags
                |> Maybe.withDefault []
        , fileFilter = s.fileFilter
        , subjectFilter = s.subjectFilter
        , languageModel =
            Comp.FixedDropdown.init Data.Language.all
        , language = Maybe.andThen Data.Language.fromString s.language
        , postHandleAll = Maybe.withDefault False s.postHandleAll
        , summary = s.summary
      }
    , Cmd.batch
        [ Api.getImapSettings flags "" ConnResp
        , nc
        , Cmd.map CalEventMsg sc
        , Api.getFolders flags "" False GetFolderResp
        , Api.getTags flags "" GetTagResp
        ]
    )


init : Flags -> ( Model, Cmd Msg )
init flags =
    let
        initialSchedule =
            Data.Validated.Valid Data.CalEvent.everyMonth

        sm =
            Comp.CalEventInput.initDefault
    in
    ( { settings = Api.Model.ScanMailboxSettings.empty
      , connectionModel = Comp.Dropdown.makeSingle
      , enabled = False
      , deleteMail = False
      , receivedHours = Nothing
      , receivedHoursModel = Comp.IntField.init (Just 1) Nothing True "Received Since Hours"
      , foldersModel = Comp.StringListInput.init
      , folders = []
      , targetFolder = Nothing
      , direction = Nothing
      , schedule = initialSchedule
      , scheduleModel = sm
      , formMsg = Nothing
      , loading = 3
      , yesNoDelete = Comp.YesNoDimmer.emptyModel
      , folderModel = Comp.Dropdown.makeSingle
      , allFolders = []
      , itemFolderId = Nothing
      , tagModel = Util.Tag.makeDropdownModel
      , existingTags = []
      , fileFilter = Nothing
      , subjectFilter = Nothing
      , languageModel =
            Comp.FixedDropdown.init Data.Language.all
      , language = Nothing
      , postHandleAll = False
      , summary = Nothing
      , openTabs = Set.insert (tabTitle TabGeneral) Set.empty
      }
    , Cmd.batch
        [ Api.getImapSettings flags "" ConnResp
        , Api.getFolders flags "" False GetFolderResp
        , Api.getTags flags "" GetTagResp
        ]
    )



--- Update


makeSettings : Model -> Validated ScanMailboxSettings
makeSettings model =
    let
        prev =
            model.settings

        conn =
            Comp.Dropdown.getSelected model.connectionModel
                |> List.head
                |> Maybe.map Valid
                |> Maybe.withDefault (Invalid [ "Connection missing" ] "")

        infolders =
            if model.folders == [] then
                Invalid [ "No processing folders given" ] []

            else
                Valid model.folders

        make imap timer folders =
            { prev
                | imapConnection = imap
                , enabled = model.enabled
                , receivedSinceHours = model.receivedHours
                , deleteMail = model.deleteMail
                , targetFolder = model.targetFolder
                , folders = folders
                , direction = Maybe.map Data.Direction.toString model.direction
                , schedule = Data.CalEvent.makeEvent timer
                , itemFolder = model.itemFolderId
                , fileFilter = model.fileFilter
                , subjectFilter = model.subjectFilter
                , tags =
                    case Comp.Dropdown.getSelected model.tagModel of
                        [] ->
                            Nothing

                        els ->
                            List.map .id els
                                |> StringList
                                |> Just
                , language = Maybe.map Data.Language.toIso3 model.language
                , postHandleAll = Just model.postHandleAll
                , summary = model.summary
            }
    in
    Data.Validated.map3 make
        conn
        model.schedule
        infolders


withValidSettings : (ScanMailboxSettings -> Action) -> Model -> ( Model, Action, Cmd Msg )
withValidSettings mkAction model =
    case makeSettings model of
        Valid set ->
            ( { model | formMsg = Nothing }
            , mkAction set
            , Cmd.none
            )

        Invalid errs _ ->
            let
                errMsg =
                    String.join ", " errs
            in
            ( { model | formMsg = Just (BasicResult False errMsg) }
            , NoAction
            , Cmd.none
            )

        Unknown _ ->
            ( { model | formMsg = Just (BasicResult False "An unknown error occured") }
            , NoAction
            , Cmd.none
            )


update : Flags -> Msg -> Model -> ( Model, Action, Cmd Msg )
update flags msg model =
    case msg of
        CalEventMsg lmsg ->
            let
                ( cm, cc, cs ) =
                    Comp.CalEventInput.update flags
                        (Data.Validated.value model.schedule)
                        lmsg
                        model.scheduleModel
            in
            ( { model
                | schedule = cs
                , scheduleModel = cm
                , formMsg = Nothing
              }
            , NoAction
            , Cmd.map CalEventMsg cc
            )

        ConnMsg m ->
            let
                ( cm, cc ) =
                    Comp.Dropdown.update m model.connectionModel
            in
            ( { model
                | connectionModel = cm
                , formMsg = Nothing
              }
            , NoAction
            , Cmd.map ConnMsg cc
            )

        ConnResp (Ok list) ->
            let
                names =
                    List.map .name list.items

                defaultConn =
                    case names of
                        h :: [] ->
                            Just h

                        _ ->
                            Nothing

                cm =
                    Comp.Dropdown.makeSingleList
                        { options = names
                        , selected =
                            Util.Maybe.or
                                [ List.head (Comp.Dropdown.getSelected model.connectionModel)
                                , defaultConn
                                ]
                        }
            in
            ( { model
                | connectionModel = cm
                , loading = model.loading - 1
                , formMsg =
                    if names == [] then
                        Just
                            (BasicResult False
                                "No E-Mail connections configured. Goto E-Mail Settings to add one."
                            )

                    else
                        Nothing
              }
            , NoAction
            , Cmd.none
            )

        ConnResp (Err err) ->
            ( { model
                | formMsg = Just (BasicResult False (Util.Http.errorToString err))
                , loading = model.loading - 1
              }
            , NoAction
            , Cmd.none
            )

        ToggleEnabled ->
            ( { model
                | enabled = not model.enabled
                , formMsg = Nothing
              }
            , NoAction
            , Cmd.none
            )

        ToggleDeleteMail ->
            ( { model
                | deleteMail = not model.deleteMail
                , formMsg = Nothing
              }
            , NoAction
            , Cmd.none
            )

        ReceivedHoursMsg m ->
            let
                ( pm, val ) =
                    Comp.IntField.update m model.receivedHoursModel
            in
            ( { model
                | receivedHoursModel = pm
                , receivedHours = val
                , formMsg = Nothing
              }
            , NoAction
            , Cmd.none
            )

        SetTargetFolder str ->
            ( { model | targetFolder = Util.Maybe.fromString str }
            , NoAction
            , Cmd.none
            )

        FoldersMsg lm ->
            let
                ( fm, itemAction ) =
                    Comp.StringListInput.update lm model.foldersModel

                newList =
                    case itemAction of
                        Comp.StringListInput.AddAction s ->
                            Util.List.distinct (s :: model.folders)

                        Comp.StringListInput.RemoveAction s ->
                            List.filter (\e -> e /= s) model.folders

                        Comp.StringListInput.NoAction ->
                            model.folders
            in
            ( { model
                | foldersModel = fm
                , folders = newList
              }
            , NoAction
            , Cmd.none
            )

        DirectionMsg md ->
            ( { model | direction = md }
            , NoAction
            , Cmd.none
            )

        Submit ->
            withValidSettings
                SubmitAction
                model

        StartOnce ->
            withValidSettings
                StartOnceAction
                model

        Cancel ->
            ( model, CancelAction, Cmd.none )

        RequestDelete ->
            let
                ( ym, _ ) =
                    Comp.YesNoDimmer.update
                        Comp.YesNoDimmer.activate
                        model.yesNoDelete
            in
            ( { model | yesNoDelete = ym }
            , NoAction
            , Cmd.none
            )

        YesNoDeleteMsg lm ->
            let
                ( ym, flag ) =
                    Comp.YesNoDimmer.update lm model.yesNoDelete

                act =
                    if flag then
                        DeleteAction model.settings.id

                    else
                        NoAction
            in
            ( { model | yesNoDelete = ym }
            , act
            , Cmd.none
            )

        GetFolderResp (Ok fs) ->
            let
                model_ =
                    { model
                        | allFolders = fs.items
                        , loading = model.loading - 1
                    }

                mkIdName fitem =
                    IdName fitem.id fitem.name

                opts =
                    fs.items
                        |> List.map mkIdName
                        |> Comp.Dropdown.SetOptions

                mkIdNameFromId id =
                    List.filterMap
                        (\f ->
                            if f.id == id then
                                Just (IdName id f.name)

                            else
                                Nothing
                        )
                        fs.items

                sel =
                    case Maybe.map mkIdNameFromId model.itemFolderId of
                        Just idref ->
                            idref

                        Nothing ->
                            []

                removeAction ( a, _, c ) =
                    ( a, c )

                addNoAction ( a, b ) =
                    ( a, NoAction, b )
            in
            Util.Update.andThen1
                [ update flags (FolderDropdownMsg opts) >> removeAction
                , update flags (FolderDropdownMsg (Comp.Dropdown.SetSelection sel)) >> removeAction
                ]
                model_
                |> addNoAction

        GetFolderResp (Err _) ->
            ( { model | loading = model.loading - 1 }
            , NoAction
            , Cmd.none
            )

        FolderDropdownMsg m ->
            let
                ( m2, c2 ) =
                    Comp.Dropdown.update m model.folderModel

                newModel =
                    { model | folderModel = m2 }

                idref =
                    Comp.Dropdown.getSelected m2 |> List.head

                model_ =
                    if isDropdownChangeMsg m then
                        { newModel | itemFolderId = Maybe.map .id idref }

                    else
                        newModel
            in
            ( model_, NoAction, Cmd.map FolderDropdownMsg c2 )

        GetTagResp (Ok list) ->
            let
                contains el =
                    List.member el model.existingTags

                isExistingTag t =
                    contains t.id || contains t.name

                selected =
                    List.filter isExistingTag list.items
                        |> Comp.Dropdown.SetSelection

                opts =
                    Comp.Dropdown.SetOptions list.items

                ( tagModel_, tagcmd ) =
                    Util.Update.andThen1
                        [ Comp.Dropdown.update selected
                        , Comp.Dropdown.update opts
                        ]
                        model.tagModel

                nextModel =
                    { model
                        | loading = model.loading - 1
                        , tagModel = tagModel_
                    }
            in
            ( nextModel
            , NoAction
            , Cmd.map TagDropdownMsg tagcmd
            )

        GetTagResp (Err _) ->
            ( { model | loading = model.loading - 1 }
            , NoAction
            , Cmd.none
            )

        TagDropdownMsg lm ->
            let
                ( m2, c2 ) =
                    Comp.Dropdown.update lm model.tagModel

                newModel =
                    { model | tagModel = m2 }
            in
            ( newModel, NoAction, Cmd.map TagDropdownMsg c2 )

        SetFileFilter str ->
            ( { model | fileFilter = Util.Maybe.fromString str }
            , NoAction
            , Cmd.none
            )

        SetSubjectFilter str ->
            ( { model | subjectFilter = Util.Maybe.fromString str }
            , NoAction
            , Cmd.none
            )

        LanguageMsg lm ->
            let
                ( dm, sel ) =
                    Comp.FixedDropdown.update lm model.languageModel
            in
            ( { model
                | languageModel = dm
                , language = Util.Maybe.or [ sel, model.language ]
              }
            , NoAction
            , Cmd.none
            )

        RemoveLanguage ->
            ( { model | language = Nothing }
            , NoAction
            , Cmd.none
            )

        TogglePostHandleAll ->
            ( { model | postHandleAll = not model.postHandleAll }
            , NoAction
            , Cmd.none
            )

        ToggleAkkordionTab title ->
            let
                tabs =
                    if Set.member title model.openTabs then
                        Set.remove title model.openTabs

                    else
                        Set.insert title model.openTabs
            in
            ( { model | openTabs = tabs }
            , NoAction
            , Cmd.none
            )

        SetSummary str ->
            ( { model | summary = Util.Maybe.fromString str }
            , NoAction
            , Cmd.none
            )



--- View2


isFormError : Model -> Bool
isFormError model =
    Maybe.map .success model.formMsg
        |> Maybe.map not
        |> Maybe.withDefault False


isFormSuccess : Model -> Bool
isFormSuccess model =
    Maybe.map .success model.formMsg
        |> Maybe.withDefault False


isFolderMember : Model -> Bool
isFolderMember model =
    let
        selected =
            Comp.Dropdown.getSelected model.folderModel
                |> List.head
                |> Maybe.map .id
    in
    Util.Folder.isFolderMember model.allFolders selected


view2 : Flags -> String -> UiSettings -> Model -> Html Msg
view2 flags extraClasses settings model =
    let
        dimmerSettings =
            Comp.YesNoDimmer.defaultSettings2 "Really delete this scan mailbox task?"

        startOnceBtn =
            MB.SecondaryButton
                { tagger = StartOnce
                , label = "Start Once"
                , title = "Start this task now"
                , icon = Just "fa fa-play"
                }

        tabActive t =
            if Set.member t.title model.openTabs then
                ( Comp.Tabs.Open, ToggleAkkordionTab t.title )

            else
                ( Comp.Tabs.Closed, ToggleAkkordionTab t.title )
    in
    div
        [ class extraClasses
        , class "md:relative"
        ]
        [ MB.view
            { start =
                [ MB.PrimaryButton
                    { tagger = Submit
                    , label = "Submit"
                    , title = "Save"
                    , icon = Just "fa fa-save"
                    }
                , MB.SecondaryButton
                    { tagger = Cancel
                    , label = "Cancel"
                    , title = "Back to list"
                    , icon = Just "fa fa-arrow-left"
                    }
                ]
            , end =
                if model.settings.id /= "" then
                    [ startOnceBtn
                    , MB.DeleteButton
                        { tagger = RequestDelete
                        , label = "Delete"
                        , title = "Delete this task"
                        , icon = Just "fa fa-trash"
                        }
                    ]

                else
                    [ startOnceBtn
                    ]
            , rootClasses = "mb-4"
            }
        , div
            [ classList
                [ ( S.successMessage, isFormSuccess model )
                , ( S.errorMessage, isFormError model )
                , ( "hidden", model.formMsg == Nothing )
                ]
            ]
            [ Maybe.map .message model.formMsg
                |> Maybe.withDefault ""
                |> text
            ]
        , Comp.Tabs.akkordion
            Comp.Tabs.defaultStyle
            tabActive
            (formTabs flags settings model)
        , Html.map YesNoDeleteMsg
            (Comp.YesNoDimmer.viewN
                True
                dimmerSettings
                model.yesNoDelete
            )
        , B.loadingDimmer (model.loading > 0)
        ]


tabTitle : MenuTab -> String
tabTitle tab =
    case tab of
        TabGeneral ->
            "General"

        TabProcessing ->
            "Processing"

        TabAdditionalFilter ->
            "Additional Filter"

        TabPostProcessing ->
            "Post Processing"

        TabMetadata ->
            "Metadata"

        TabSchedule ->
            "Schedule"


formTabs : Flags -> UiSettings -> Model -> List (Comp.Tabs.Tab Msg)
formTabs flags settings model =
    [ { title = tabTitle TabGeneral
      , titleRight = []
      , info = Nothing
      , body = viewGeneral2 settings model
      }
    , { title = tabTitle TabProcessing
      , titleRight = []
      , info = Just "These settings define which mails are fetched from the mail server."
      , body = viewProcessing2 model
      }
    , { title = tabTitle TabAdditionalFilter
      , titleRight = []
      , info = Just "These filters are applied to mails that have been fetched from the mailbox to select those that should be imported."
      , body = viewAdditionalFilter2 model
      }
    , { title = tabTitle TabPostProcessing
      , titleRight = []
      , info = Just "This defines what happens to mails that have been downloaded."
      , body = viewPostProcessing2 model
      }
    , { title = tabTitle TabMetadata
      , titleRight = []
      , info = Just "Define metadata that should be attached to all items created by this task."
      , body = viewMetadata2 flags settings model
      }
    , { title = tabTitle TabSchedule
      , titleRight = []
      , info = Just "Define when mails should be imported."
      , body = viewSchedule2 model
      }
    ]


viewGeneral2 : UiSettings -> Model -> List (Html Msg)
viewGeneral2 settings model =
    let
        connectionCfg =
            { makeOption = \a -> { text = a, additional = "" }
            , placeholder = "Select connection..."
            , labelColor = \_ -> \_ -> ""
            , style = DS.mainStyle
            }
    in
    [ MB.viewItem <|
        MB.Checkbox
            { id = "scanmail-enabled"
            , value = model.enabled
            , tagger = \_ -> ToggleEnabled
            , label = "Enable or disable this task."
            }
    , div [ class "mb-4 mt-4" ]
        [ label [ class S.inputLabel ]
            [ text "Mailbox"
            , B.inputRequired
            ]
        , div [ class "mb-4" ]
            [ label [ class S.inputLabel ]
                [ text "Summary"
                ]
            , input
                [ type_ "text"
                , onInput SetSummary
                , class S.textInput
                , Maybe.withDefault "" model.summary
                    |> value
                ]
                []
            , span [ class "opacity-50 text-sm" ]
                [ text "Some human readable name, only for displaying"
                ]
            ]
        , Html.map ConnMsg
            (Comp.Dropdown.view2
                connectionCfg
                settings
                model.connectionModel
            )
        , span [ class "opacity-50 text-sm" ]
            [ text "The IMAP connection to use when sending notification mails."
            ]
        ]
    ]


viewProcessing2 : Model -> List (Html Msg)
viewProcessing2 model =
    [ div [ class "mb-4" ]
        [ label [ class S.inputLabel ]
            [ text "Folders"
            , B.inputRequired
            ]
        , Html.map FoldersMsg
            (Comp.StringListInput.view2
                model.folders
                model.foldersModel
            )
        , span [ class "opacity-50 text-sm mt-1" ]
            [ text "The folders to look for mails."
            ]
        ]
    , Html.map ReceivedHoursMsg
        (Comp.IntField.viewWithInfo2
            "Select mails newer than `now - receivedHours`"
            model.receivedHours
            "mb-4"
            model.receivedHoursModel
        )
    ]


viewAdditionalFilter2 : Model -> List (Html Msg)
viewAdditionalFilter2 model =
    [ div
        [ class "mb-4"
        ]
        [ label
            [ class S.inputLabel
            ]
            [ text "File Filter" ]
        , input
            [ type_ "text"
            , onInput SetFileFilter
            , placeholder "File Filter"
            , model.fileFilter
                |> Maybe.withDefault ""
                |> value
            , class S.textInput
            ]
            []
        , div [ class "opacity-50 text-sm" ]
            [ text "Specify a file glob to filter attachments. For example, to only extract pdf files: "
            , code [ class "font-mono" ]
                [ text "*.pdf"
                ]
            , text ". If you want to include the mail body, allow html files or "
            , code [ class "font-mono" ]
                [ text "mail.html"
                ]
            , text ". Globs can be combined via OR, like this: "
            , code [ class "font-mono" ]
                [ text "*.pdf|mail.html"
                ]
            , text ". No file filter defaults to "
            , code [ class "font-mono" ]
                [ text "*"
                ]
            , text " that includes all"
            ]
        ]
    , div
        [ class "mb-4"
        ]
        [ label [ class S.inputLabel ]
            [ text "Subject Filter" ]
        , input
            [ type_ "text"
            , onInput SetSubjectFilter
            , placeholder "Subject Filter"
            , model.subjectFilter
                |> Maybe.withDefault ""
                |> value
            , class S.textInput
            ]
            []
        , div [ class "opacity-50 text-sm" ]
            [ text "Specify a file glob to filter mails by subject. For example: "
            , code [ class "font-mono" ]
                [ text "*Scanned Document*"
                ]
            , text ". No file filter defaults to "
            , code [ class "font-mono" ]
                [ text "*"
                ]
            , text " that includes all"
            ]
        ]
    ]


viewPostProcessing2 : Model -> List (Html Msg)
viewPostProcessing2 model =
    [ div [ class "mb-4" ]
        [ MB.viewItem <|
            MB.Checkbox
                { id = "scanmail-posthandle-all"
                , value = model.postHandleAll
                , label = "Apply post-processing to all fetched mails."
                , tagger = \_ -> TogglePostHandleAll
                }
        , span [ class "opacity-50 text-sm mt-1" ]
            [ text "When mails are fetched but not imported due to the 'Additional Filters', this flag can "
            , text "control whether they should be moved to a target folder or deleted (whatever is "
            , text "defined here) nevertheless. If unchecked only imported mails "
            , text "are post-processed, others stay where they are."
            ]
        ]
    , div [ class "mb-4" ]
        [ label [ class S.inputLabel ]
            [ text "Target folder"
            ]
        , input
            [ type_ "text"
            , onInput SetTargetFolder
            , Maybe.withDefault "" model.targetFolder |> value
            , class S.textInput
            ]
            []
        , span [ class "opacity-50 text-sm" ]
            [ text "Move mails into this folder."
            ]
        ]
    , div [ class "mb-4" ]
        [ MB.viewItem <|
            MB.Checkbox
                { id = "scanmail-delete-all"
                , label = "Delete imported mails"
                , tagger = \_ -> ToggleDeleteMail
                , value = model.deleteMail
                }
        , span [ class "opacity-50 text-sm" ]
            [ text "Whether to delete all mails fetched by docspell. This only applies if "
            , em [] [ text "target folder" ]
            , text " is not set."
            ]
        ]
    ]


viewMetadata2 : Flags -> UiSettings -> Model -> List (Html Msg)
viewMetadata2 flags settings model =
    let
        folderCfg =
            { makeOption = Util.Folder.mkFolderOption flags model.allFolders
            , placeholder = ""
            , labelColor = \_ -> \_ -> ""
            , style = DS.mainStyle
            }

        languageCfg =
            { display = Messages.LanguageData.gb
            , icon = \_ -> Nothing
            , style = DS.mainStyleWith "flex-grow mr-2"
            }
    in
    [ div [ class "mb-4" ]
        [ label [ class S.inputLabel ]
            [ text "Item direction"
            , B.inputRequired
            ]
        , div [ class "flex flex-col " ]
            [ label [ class "inline-flex items-center" ]
                [ input
                    [ type_ "radio"
                    , checked (model.direction == Nothing)
                    , onCheck (\_ -> DirectionMsg Nothing)
                    , class S.radioInput
                    ]
                    []
                , span [ class "ml-2" ] [ text "Automatic" ]
                ]
            , label [ class "inline-flex items-center" ]
                [ input
                    [ type_ "radio"
                    , checked (model.direction == Just Incoming)
                    , class S.radioInput
                    , onCheck (\_ -> DirectionMsg (Just Incoming))
                    ]
                    []
                , span [ class "ml-2" ] [ text "Incoming" ]
                ]
            , label [ class "inline-flex items-center" ]
                [ input
                    [ type_ "radio"
                    , checked (model.direction == Just Outgoing)
                    , onCheck (\_ -> DirectionMsg (Just Outgoing))
                    , class S.radioInput
                    ]
                    []
                , span [ class "ml-2" ] [ text "Outgoing" ]
                ]
            , span [ class "opacity-50 text-sm" ]
                [ text "Sets the direction for an item. If you know all mails are incoming or "
                , text "outgoing, you can set it here. Otherwise it will be guessed from looking "
                , text "at sender and receiver."
                ]
            ]
        ]
    , div [ class "mb-4" ]
        [ label [ class S.inputLabel ]
            [ text "Item Folder"
            ]
        , Html.map FolderDropdownMsg
            (Comp.Dropdown.view2
                folderCfg
                settings
                model.folderModel
            )
        , span [ class "opacity-50 text-sm" ]
            [ text "Put all items from this mailbox into the selected folder"
            ]
        , div
            [ classList
                [ ( "hidden", isFolderMember model )
                ]
            , class S.message
            ]
            [ Markdown.toHtml [] """
You are **not a member** of this folder. Items created from mails in
this mailbox will be **hidden** from any search results. Use a folder
where you are a member of to make items visible. This message will
disappear then.
                      """
            ]
        ]
    , div [ class "mb-4" ]
        [ label [ class S.inputLabel ]
            [ text "Tags" ]
        , Html.map TagDropdownMsg
            (Comp.Dropdown.view2
                (Util.Tag.tagSettings DS.mainStyle)
                settings
                model.tagModel
            )
        , div [ class "opacity-50 text-sm" ]
            [ text "Choose tags that should be applied to items."
            ]
        ]
    , div [ class "mb-4" ]
        [ label [ class S.inputLabel ]
            [ text "Language"
            ]
        , div [ class "flex flex-row" ]
            [ Html.map LanguageMsg
                (Comp.FixedDropdown.viewStyled2
                    languageCfg
                    False
                    model.language
                    model.languageModel
                )
            , a
                [ href "#"
                , onClick RemoveLanguage
                , class S.secondaryBasicButton
                , class "flex-none"
                ]
                [ i [ class "fa fa-trash" ] []
                ]
            ]
        , div [ class "opacity-50 text-sm" ]
            [ text "Used for text extraction and text analysis. The "
            , text "collective's default language is used, if not specified here."
            ]
        ]
    ]


viewSchedule2 : Model -> List (Html Msg)
viewSchedule2 model =
    [ div [ class "mb-4" ]
        [ label [ class S.inputLabel ]
            [ text "Schedule"
            , B.inputRequired
            , a
                [ class "float-right"
                , class S.link
                , href "https://github.com/eikek/calev#what-are-calendar-events"
                , target "_blank"
                ]
                [ i [ class "fa fa-question" ] []
                , span [ class "ml-2" ]
                    [ text "Click here for help"
                    ]
                ]
            ]
        , Html.map CalEventMsg
            (Comp.CalEventInput.view2 ""
                (Data.Validated.value model.schedule)
                model.scheduleModel
            )
        , span [ class "opacity-50 text-sm" ]
            [ text "Specify how often and when this task should run. "
            , text "Use English 3-letter weekdays. Either a single value, "
            , text "a list (ex. 1,2,3), a range (ex. 1..3) or a '*' (meaning all) "
            , text "is allowed for each part."
            ]
        ]
    ]
