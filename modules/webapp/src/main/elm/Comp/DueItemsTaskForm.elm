{-
   Copyright 2020 Eike K. & Contributors

   SPDX-License-Identifier: AGPL-3.0-or-later
-}


module Comp.DueItemsTaskForm exposing
    ( Action(..)
    , Model
    , Msg
    , init
    , initWith
    , update
    , view2
    )

import Api
import Api.Model.PeriodicDueItemsSettings exposing (PeriodicDueItemsSettings)
import Api.Model.TagList exposing (TagList)
import Comp.Basic as B
import Comp.CalEventInput
import Comp.ChannelRefInput
import Comp.IntField
import Comp.MenuBar as MB
import Comp.TagDropdown
import Comp.YesNoDimmer
import Data.CalEvent exposing (CalEvent)
import Data.DropdownStyle as DS
import Data.Flags exposing (Flags)
import Data.TagOrder
import Data.UiSettings exposing (UiSettings)
import Data.Validated exposing (Validated(..))
import Html exposing (..)
import Html.Attributes exposing (..)
import Html.Events exposing (onInput)
import Http
import Markdown
import Messages.Comp.DueItemsTaskForm exposing (Texts)
import Styles as S
import Util.Maybe


type alias Model =
    { settings : PeriodicDueItemsSettings
    , channelModel : Comp.ChannelRefInput.Model
    , tagInclModel : Comp.TagDropdown.Model
    , tagExclModel : Comp.TagDropdown.Model
    , remindDays : Maybe Int
    , remindDaysModel : Comp.IntField.Model
    , capOverdue : Bool
    , enabled : Bool
    , schedule : Maybe CalEvent
    , scheduleModel : Comp.CalEventInput.Model
    , formState : FormState
    , loading : Int
    , yesNoDelete : Comp.YesNoDimmer.Model
    , summary : Maybe String
    }


type FormState
    = FormStateInitial
    | FormStateHttpError Http.Error
    | FormStateInvalid ValidateError


type ValidateError
    = ValidateRemindDaysRequired
    | ValidateCalEventInvalid
    | ValidateChannelRequired


type Action
    = SubmitAction PeriodicDueItemsSettings
    | StartOnceAction PeriodicDueItemsSettings
    | CancelAction
    | DeleteAction String
    | NoAction


type Msg
    = Submit
    | TagIncMsg Comp.TagDropdown.Msg
    | TagExcMsg Comp.TagDropdown.Msg
    | GetTagsResp (Result Http.Error TagList)
    | RemindDaysMsg Comp.IntField.Msg
    | ToggleEnabled
    | ToggleCapOverdue
    | CalEventMsg Comp.CalEventInput.Msg
    | StartOnce
    | Cancel
    | RequestDelete
    | YesNoDeleteMsg Comp.YesNoDimmer.Msg
    | SetSummary String
    | ChannelMsg Comp.ChannelRefInput.Msg


initWith : Flags -> PeriodicDueItemsSettings -> ( Model, Cmd Msg )
initWith flags s =
    let
        ( im, ic ) =
            init flags

        newSchedule =
            Data.CalEvent.fromEvent s.schedule
                |> Maybe.withDefault Data.CalEvent.everyMonth

        ( sm, sc ) =
            Comp.CalEventInput.init flags newSchedule

        ( cfm, cfc ) =
            Comp.ChannelRefInput.initSelected flags s.channels
    in
    ( { im
        | settings = s
        , channelModel = cfm
        , tagExclModel = Comp.TagDropdown.initWith [] s.tagsExclude
        , tagInclModel = Comp.TagDropdown.initWith [] s.tagsInclude
        , remindDays = Just s.remindDays
        , enabled = s.enabled
        , capOverdue = s.capOverdue
        , schedule = Just newSchedule
        , scheduleModel = sm
        , formState = FormStateInitial
        , loading = im.loading
        , yesNoDelete = Comp.YesNoDimmer.emptyModel
        , summary = s.summary
      }
    , Cmd.batch
        [ ic
        , Cmd.map CalEventMsg sc
        , Cmd.map ChannelMsg cfc
        ]
    )


init : Flags -> ( Model, Cmd Msg )
init flags =
    let
        initialSchedule =
            Data.CalEvent.everyMonth

        ( sm, scmd ) =
            Comp.CalEventInput.init flags initialSchedule

        ( cfm, cfc ) =
            Comp.ChannelRefInput.init flags
    in
    ( { settings = Api.Model.PeriodicDueItemsSettings.empty
      , channelModel = cfm
      , tagInclModel = Comp.TagDropdown.initWith [] []
      , tagExclModel = Comp.TagDropdown.initWith [] []
      , remindDays = Just 1
      , remindDaysModel = Comp.IntField.init (Just 1) Nothing True
      , enabled = False
      , capOverdue = False
      , schedule = Just initialSchedule
      , scheduleModel = sm
      , formState = FormStateInitial
      , loading = 1
      , yesNoDelete = Comp.YesNoDimmer.emptyModel
      , summary = Nothing
      }
    , Cmd.batch
        [ Api.getTags flags "" Data.TagOrder.NameAsc GetTagsResp
        , Cmd.map CalEventMsg scmd
        , Cmd.map ChannelMsg cfc
        ]
    )



--- Update


makeSettings : Model -> Result ValidateError PeriodicDueItemsSettings
makeSettings model =
    let
        prev =
            model.settings

        rmdays =
            Maybe.map Ok model.remindDays
                |> Maybe.withDefault (Err ValidateRemindDaysRequired)

        schedule_ =
            case model.schedule of
                Just s ->
                    Ok s

                Nothing ->
                    Err ValidateCalEventInvalid

        channelM =
            let
                list =
                    Comp.ChannelRefInput.getSelected model.channelModel
            in
            if list == [] then
                Err ValidateChannelRequired

            else
                Ok list

        make days timer channels =
            { prev
                | tagsInclude = Comp.TagDropdown.getSelected model.tagInclModel
                , tagsExclude = Comp.TagDropdown.getSelected model.tagExclModel
                , remindDays = days
                , capOverdue = model.capOverdue
                , enabled = model.enabled
                , schedule = Data.CalEvent.makeEvent timer
                , summary = model.summary
                , channels = channels
            }
    in
    Result.map3 make
        rmdays
        schedule_
        channelM


withValidSettings : (PeriodicDueItemsSettings -> Action) -> Model -> ( Model, Action, Cmd Msg )
withValidSettings mkcmd model =
    case makeSettings model of
        Ok set ->
            ( { model | formState = FormStateInitial }
            , mkcmd set
            , Cmd.none
            )

        Err errs ->
            ( { model | formState = FormStateInvalid errs }
            , NoAction
            , Cmd.none
            )


update : Flags -> Msg -> Model -> ( Model, Action, Cmd Msg )
update flags msg model =
    case msg of
        ChannelMsg lm ->
            let
                ( cfm, cfc ) =
                    Comp.ChannelRefInput.update lm model.channelModel
            in
            ( { model | channelModel = cfm }
            , NoAction
            , Cmd.map ChannelMsg cfc
            )

        CalEventMsg lmsg ->
            let
                ( cm, cc, cs ) =
                    Comp.CalEventInput.update flags
                        model.schedule
                        lmsg
                        model.scheduleModel
            in
            ( { model
                | schedule = cs
                , scheduleModel = cm
                , formState = FormStateInitial
              }
            , NoAction
            , Cmd.map CalEventMsg cc
            )

        TagIncMsg m ->
            let
                ( m2, c2 ) =
                    Comp.TagDropdown.update m model.tagInclModel
            in
            ( { model
                | tagInclModel = m2
                , formState = FormStateInitial
              }
            , NoAction
            , Cmd.map TagIncMsg c2
            )

        TagExcMsg m ->
            let
                ( m2, c2 ) =
                    Comp.TagDropdown.update m model.tagExclModel
            in
            ( { model
                | tagExclModel = m2
                , formState = FormStateInitial
              }
            , NoAction
            , Cmd.map TagExcMsg c2
            )

        GetTagsResp (Ok tags) ->
            let
                incModel =
                    Comp.TagDropdown.initWith tags.items model.settings.tagsInclude

                excModel =
                    Comp.TagDropdown.initWith tags.items model.settings.tagsExclude

                newModel =
                    { model
                        | loading = model.loading - 1
                        , tagExclModel = excModel
                        , tagInclModel = incModel
                    }
            in
            ( newModel, NoAction, Cmd.none )

        GetTagsResp (Err err) ->
            ( { model
                | loading = model.loading - 1
                , formState = FormStateHttpError err
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
                , formState = FormStateInitial
              }
            , NoAction
            , Cmd.none
            )

        ToggleEnabled ->
            ( { model
                | enabled = not model.enabled
                , formState = FormStateInitial
              }
            , NoAction
            , Cmd.none
            )

        ToggleCapOverdue ->
            ( { model
                | capOverdue = not model.capOverdue
                , formState = FormStateInitial
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

        SetSummary str ->
            ( { model | summary = Util.Maybe.fromString str }
            , NoAction
            , Cmd.none
            )



--- View2


isFormError : Model -> Bool
isFormError model =
    case model.formState of
        FormStateInitial ->
            False

        _ ->
            True


isFormSuccess : Model -> Bool
isFormSuccess model =
    not (isFormError model)


view2 : Texts -> String -> UiSettings -> Model -> Html Msg
view2 texts extraClasses settings model =
    let
        dimmerSettings =
            Comp.YesNoDimmer.defaultSettings texts.reallyDeleteTask
                texts.basics.yes
                texts.basics.no

        startOnceBtn =
            MB.SecondaryButton
                { tagger = StartOnce
                , label = texts.startOnce
                , title = texts.startTaskNow
                , icon = Just "fa fa-play"
                }

        formHeader txt =
            h2 [ class S.formHeader, class "mt-2" ]
                [ text txt
                ]
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
        , B.loadingDimmer
            { active = model.loading > 0
            , label = texts.basics.loading
            }
        , MB.view
            { start =
                [ MB.PrimaryButton
                    { tagger = Submit
                    , label = texts.basics.submit
                    , title = texts.basics.submitThisForm
                    , icon = Just "fa fa-save"
                    }
                , MB.SecondaryButton
                    { tagger = Cancel
                    , label = texts.basics.backToList
                    , title = texts.basics.backToList
                    , icon = Just "fa fa-arrow-left"
                    }
                ]
            , end =
                if model.settings.id /= "" then
                    [ startOnceBtn
                    , MB.DeleteButton
                        { tagger = RequestDelete
                        , label = texts.basics.delete
                        , title = texts.deleteThisTask
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
                , ( "hidden", model.formState == FormStateInitial )
                ]
            , class "mb-4"
            ]
            [ case model.formState of
                FormStateInitial ->
                    text ""

                FormStateHttpError err ->
                    text (texts.httpError err)

                FormStateInvalid ValidateCalEventInvalid ->
                    text texts.invalidCalEvent

                FormStateInvalid ValidateRemindDaysRequired ->
                    text texts.remindDaysRequired

                FormStateInvalid ValidateChannelRequired ->
                    text texts.channelRequired
            ]
        , div [ class "mb-4" ]
            [ MB.viewItem <|
                MB.Checkbox
                    { tagger = \_ -> ToggleEnabled
                    , label = texts.enableDisable
                    , value = model.enabled
                    , id = "notify-enabled"
                    }
            ]
        , div [ class "mb-4" ]
            [ label [ class S.inputLabel ]
                [ text texts.summary
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
                [ text texts.summaryInfo
                ]
            ]
        , div [ class "mb-4" ]
            [ formHeader texts.channelHeader
            , Html.map ChannelMsg
                (Comp.ChannelRefInput.view texts.channelRef settings model.channelModel)
            ]
        , formHeader texts.queryLabel
        , div [ class "mb-4" ]
            [ label [ class S.inputLabel ]
                [ text texts.tagsInclude ]
            , Html.map TagIncMsg
                (Comp.TagDropdown.view
                    texts.tagDropdown
                    settings
                    DS.mainStyle
                    model.tagInclModel
                )
            , span [ class "opacity-50 text-sm" ]
                [ text texts.tagsIncludeInfo
                ]
            ]
        , div [ class "mb-4" ]
            [ label [ class S.inputLabel ]
                [ text texts.tagsExclude ]
            , Html.map TagExcMsg
                (Comp.TagDropdown.view
                    texts.tagDropdown
                    settings
                    DS.mainStyle
                    model.tagExclModel
                )
            , span [ class "opacity-50 text-sm" ]
                [ text texts.tagsExcludeInfo
                ]
            ]
        , Html.map RemindDaysMsg
            (Comp.IntField.view
                { label = texts.remindDaysLabel
                , info = texts.remindDaysInfo
                , number = model.remindDays
                , classes = "mb-4"
                }
                model.remindDaysModel
            )
        , div [ class "mb-4" ]
            [ MB.viewItem <|
                MB.Checkbox
                    { tagger = \_ -> ToggleCapOverdue
                    , id = "notify-toggle-cap-overdue"
                    , value = model.capOverdue
                    , label = texts.capOverdue
                    }
            , div [ class "opacity-50 text-sm" ]
                [ Markdown.toHtml [] texts.capOverdueInfo
                ]
            ]
        , div [ class "mb-4" ]
            [ formHeader texts.schedule
            , label [ class S.inputLabel ]
                [ text texts.schedule
                , a
                    [ class "float-right"
                    , class S.link
                    , href "https://github.com/eikek/calev#what-are-calendar-events"
                    , target "_blank"
                    ]
                    [ i [ class "fa fa-question" ] []
                    , span [ class "pl-2" ]
                        [ text texts.scheduleClickForHelp
                        ]
                    ]
                ]
            , Html.map CalEventMsg
                (Comp.CalEventInput.view2
                    texts.calEventInput
                    ""
                    model.schedule
                    model.scheduleModel
                )
            , span [ class "opacity-50 text-sm" ]
                [ text texts.scheduleInfo
                ]
            ]
        ]
