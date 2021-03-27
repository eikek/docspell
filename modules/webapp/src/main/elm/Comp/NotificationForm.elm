module Comp.NotificationForm exposing
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
import Api.Model.EmailSettingsList exposing (EmailSettingsList)
import Api.Model.NotificationSettings exposing (NotificationSettings)
import Api.Model.Tag exposing (Tag)
import Api.Model.TagList exposing (TagList)
import Comp.Basic as B
import Comp.CalEventInput
import Comp.Dropdown
import Comp.EmailInput
import Comp.IntField
import Comp.MenuBar as MB
import Comp.YesNoDimmer
import Data.CalEvent exposing (CalEvent)
import Data.DropdownStyle as DS
import Data.Flags exposing (Flags)
import Data.UiSettings exposing (UiSettings)
import Data.Validated exposing (Validated(..))
import Html exposing (..)
import Html.Attributes exposing (..)
import Http
import Styles as S
import Util.Http
import Util.Maybe
import Util.Tag
import Util.Update


type alias Model =
    { settings : NotificationSettings
    , connectionModel : Comp.Dropdown.Model String
    , tagInclModel : Comp.Dropdown.Model Tag
    , tagExclModel : Comp.Dropdown.Model Tag
    , recipients : List String
    , recipientsModel : Comp.EmailInput.Model
    , remindDays : Maybe Int
    , remindDaysModel : Comp.IntField.Model
    , capOverdue : Bool
    , enabled : Bool
    , schedule : Validated CalEvent
    , scheduleModel : Comp.CalEventInput.Model
    , formMsg : Maybe BasicResult
    , loading : Int
    , yesNoDelete : Comp.YesNoDimmer.Model
    }


type Action
    = SubmitAction NotificationSettings
    | StartOnceAction NotificationSettings
    | CancelAction
    | DeleteAction String
    | NoAction


type Msg
    = Submit
    | TagIncMsg (Comp.Dropdown.Msg Tag)
    | TagExcMsg (Comp.Dropdown.Msg Tag)
    | ConnMsg (Comp.Dropdown.Msg String)
    | ConnResp (Result Http.Error EmailSettingsList)
    | RecipientMsg Comp.EmailInput.Msg
    | GetTagsResp (Result Http.Error TagList)
    | RemindDaysMsg Comp.IntField.Msg
    | ToggleEnabled
    | ToggleCapOverdue
    | CalEventMsg Comp.CalEventInput.Msg
    | StartOnce
    | Cancel
    | RequestDelete
    | YesNoDeleteMsg Comp.YesNoDimmer.Msg


initWith : Flags -> NotificationSettings -> ( Model, Cmd Msg )
initWith flags s =
    let
        ( im, ic ) =
            init flags

        smtp =
            Util.Maybe.fromString s.smtpConnection
                |> Maybe.map List.singleton
                |> Maybe.withDefault []

        removeAction ( tm, _, tc ) =
            ( tm, tc )

        ( nm, nc ) =
            Util.Update.andThen1
                [ update flags (ConnMsg (Comp.Dropdown.SetSelection smtp)) >> removeAction
                , update flags (TagIncMsg (Comp.Dropdown.SetSelection s.tagsInclude)) >> removeAction
                , update flags (TagExcMsg (Comp.Dropdown.SetSelection s.tagsExclude)) >> removeAction
                ]
                im

        newSchedule =
            Data.CalEvent.fromEvent s.schedule
                |> Maybe.withDefault Data.CalEvent.everyMonth

        ( sm, sc ) =
            Comp.CalEventInput.init flags newSchedule
    in
    ( { nm
        | settings = s
        , recipients = s.recipients
        , remindDays = Just s.remindDays
        , enabled = s.enabled
        , capOverdue = s.capOverdue
        , schedule = Data.Validated.Unknown newSchedule
        , scheduleModel = sm
        , formMsg = Nothing
        , loading = im.loading
        , yesNoDelete = Comp.YesNoDimmer.emptyModel
      }
    , Cmd.batch
        [ nc
        , ic
        , Cmd.map CalEventMsg sc
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
    ( { settings = Api.Model.NotificationSettings.empty
      , connectionModel =
            Comp.Dropdown.makeSingle
                { makeOption = \a -> { value = a, text = a, additional = "" }
                , placeholder = "Select connection..."
                }
      , tagInclModel = Util.Tag.makeDropdownModel2
      , tagExclModel = Util.Tag.makeDropdownModel2
      , recipients = []
      , recipientsModel = Comp.EmailInput.init
      , remindDays = Just 1
      , remindDaysModel = Comp.IntField.init (Just 1) Nothing True "Remind Days"
      , enabled = False
      , capOverdue = False
      , schedule = initialSchedule
      , scheduleModel = sm
      , formMsg = Nothing
      , loading = 2
      , yesNoDelete = Comp.YesNoDimmer.emptyModel
      }
    , Cmd.batch
        [ Api.getMailSettings flags "" ConnResp
        , Api.getTags flags "" GetTagsResp
        ]
    )



--- Update


makeSettings : Model -> Validated NotificationSettings
makeSettings model =
    let
        prev =
            model.settings

        conn =
            Comp.Dropdown.getSelected model.connectionModel
                |> List.head
                |> Maybe.map Valid
                |> Maybe.withDefault (Invalid [ "Connection missing" ] "")

        recp =
            if List.isEmpty model.recipients then
                Invalid [ "No recipients" ] []

            else
                Valid model.recipients

        rmdays =
            Maybe.map Valid model.remindDays
                |> Maybe.withDefault (Invalid [ "Remind Days is required" ] 0)

        make smtp rec days timer =
            { prev
                | smtpConnection = smtp
                , tagsInclude = Comp.Dropdown.getSelected model.tagInclModel
                , tagsExclude = Comp.Dropdown.getSelected model.tagExclModel
                , recipients = rec
                , remindDays = days
                , capOverdue = model.capOverdue
                , enabled = model.enabled
                , schedule = Data.CalEvent.makeEvent timer
            }
    in
    Data.Validated.map4 make
        conn
        recp
        rmdays
        model.schedule


withValidSettings : (NotificationSettings -> Action) -> Model -> ( Model, Action, Cmd Msg )
withValidSettings mkcmd model =
    case makeSettings model of
        Valid set ->
            ( { model | formMsg = Nothing }
            , mkcmd set
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

        RecipientMsg m ->
            let
                ( em, ec, rec ) =
                    Comp.EmailInput.update flags model.recipients m model.recipientsModel
            in
            ( { model
                | recipients = rec
                , recipientsModel = em
                , formMsg = Nothing
              }
            , NoAction
            , Cmd.map RecipientMsg ec
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

                cm =
                    Comp.Dropdown.makeSingleList
                        { makeOption = \a -> { value = a, text = a, additional = "" }
                        , placeholder = "Select Connection..."
                        , options = names
                        , selected = List.head names
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

        TagIncMsg m ->
            let
                ( m2, c2 ) =
                    Comp.Dropdown.update m model.tagInclModel
            in
            ( { model
                | tagInclModel = m2
                , formMsg = Nothing
              }
            , NoAction
            , Cmd.map TagIncMsg c2
            )

        TagExcMsg m ->
            let
                ( m2, c2 ) =
                    Comp.Dropdown.update m model.tagExclModel
            in
            ( { model
                | tagExclModel = m2
                , formMsg = Nothing
              }
            , NoAction
            , Cmd.map TagExcMsg c2
            )

        GetTagsResp (Ok tags) ->
            let
                tagList =
                    Comp.Dropdown.SetOptions tags.items

                removeAction ( tm, _, tc ) =
                    ( tm, tc )

                ( m, c ) =
                    Util.Update.andThen1
                        [ update flags (TagIncMsg tagList) >> removeAction
                        , update flags (TagExcMsg tagList) >> removeAction
                        ]
                        { model | loading = model.loading - 1 }
            in
            ( m, NoAction, c )

        GetTagsResp (Err err) ->
            ( { model
                | loading = model.loading - 1
                , formMsg = Just (BasicResult False (Util.Http.errorToString err))
              }
            , NoAction
            , Cmd.none
            )

        RemindDaysMsg m ->
            let
                ( pm, val ) =
                    Comp.IntField.update m model.remindDaysModel
            in
            ( { model
                | remindDaysModel = pm
                , remindDays = val
                , formMsg = Nothing
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

        ToggleCapOverdue ->
            ( { model
                | capOverdue = not model.capOverdue
                , formMsg = Nothing
              }
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


view2 : String -> UiSettings -> Model -> Html Msg
view2 extraClasses settings model =
    let
        dimmerSettings =
            Comp.YesNoDimmer.defaultSettings2 "Really delete this notification task?"

        startOnceBtn =
            MB.SecondaryButton
                { tagger = StartOnce
                , label = "Start Once"
                , title = "Start this task now"
                , icon = Just "fa fa-play"
                }
    in
    div
        [ class "flex flex-col md:relative"
        , class extraClasses
        ]
        [ Html.map YesNoDeleteMsg
            (Comp.YesNoDimmer.viewN True
                dimmerSettings
                model.yesNoDelete
            )
        , B.loadingDimmer (model.loading > 0)
        , MB.view
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
            , class "mb-4"
            ]
            [ Maybe.map .message model.formMsg
                |> Maybe.withDefault ""
                |> text
            ]
        , div [ class "mb-4" ]
            [ MB.viewItem <|
                MB.Checkbox
                    { tagger = \_ -> ToggleEnabled
                    , label = "Enable or disable this task."
                    , value = model.enabled
                    , id = "notify-enabled"
                    }
            ]
        , div [ class "mb-4" ]
            [ label [ class S.inputLabel ]
                [ text "Send via"
                , B.inputRequired
                ]
            , Html.map ConnMsg
                (Comp.Dropdown.view2
                    DS.mainStyle
                    settings
                    model.connectionModel
                )
            , span [ class "opacity-50 text-sm" ]
                [ text "The SMTP connection to use when sending notification mails."
                ]
            ]
        , div [ class "mb-4" ]
            [ label
                [ class S.inputLabel
                ]
                [ text "Recipient(s)"
                , B.inputRequired
                ]
            , Html.map RecipientMsg
                (Comp.EmailInput.view2
                    DS.mainStyle
                    model.recipients
                    model.recipientsModel
                )
            , span [ class "opacity-50 text-sm" ]
                [ text "One or more mail addresses, confirm each by pressing 'Return'."
                ]
            ]
        , div [ class "mb-4" ]
            [ label [ class S.inputLabel ]
                [ text "Tags Include (and)" ]
            , Html.map TagIncMsg
                (Comp.Dropdown.view2
                    DS.mainStyle
                    settings
                    model.tagInclModel
                )
            , span [ class "opacity-50 text-sm" ]
                [ text "Items must have all the tags specified here."
                ]
            ]
        , div [ class "mb-4" ]
            [ label [ class S.inputLabel ]
                [ text "Tags Exclude (or)" ]
            , Html.map TagExcMsg
                (Comp.Dropdown.view2
                    DS.mainStyle
                    settings
                    model.tagExclModel
                )
            , span [ class "small-info" ]
                [ text "Items must not have any tag specified here."
                ]
            ]
        , Html.map RemindDaysMsg
            (Comp.IntField.viewWithInfo2
                "Select items with a due date *lower than* `today+remindDays`"
                model.remindDays
                "mb-4"
                model.remindDaysModel
            )
        , div [ class "mb-4" ]
            [ MB.viewItem <|
                MB.Checkbox
                    { tagger = \_ -> ToggleCapOverdue
                    , id = "notify-toggle-cap-overdue"
                    , value = model.capOverdue
                    , label = "Cap overdue items"
                    }
            , div [ class "opacity-50 text-sm" ]
                [ text "If checked, only items with a due date"
                , em [ class "font-italic" ]
                    [ text " greater than " ]
                , code [ class "font-mono" ]
                    [ text "today-remindDays" ]
                , text " are considered."
                ]
            ]
        , div [ class "mb-4" ]
            [ label [ class S.inputLabel ]
                [ text "Schedule"
                , a
                    [ class "float-right"
                    , class S.link
                    , href "https://github.com/eikek/calev#what-are-calendar-events"
                    , target "_blank"
                    ]
                    [ i [ class "fa fa-question" ] []
                    , span [ class "pl-2" ]
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
