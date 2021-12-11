{-
   Copyright 2020 Eike K. & Contributors

   SPDX-License-Identifier: AGPL-3.0-or-later
-}


module Comp.PeriodicQueryTaskForm exposing
    ( Action(..)
    , Model
    , Msg
    , UpdateResult
    , init
    , initWith
    , update
    , view
    )

import Comp.Basic as B
import Comp.CalEventInput
import Comp.ChannelForm
import Comp.MenuBar as MB
import Comp.PowerSearchInput
import Data.CalEvent exposing (CalEvent)
import Data.ChannelType exposing (ChannelType)
import Data.Flags exposing (Flags)
import Data.PeriodicQuerySettings exposing (PeriodicQuerySettings)
import Data.UiSettings exposing (UiSettings)
import Data.Validated exposing (Validated(..))
import Html exposing (..)
import Html.Attributes exposing (..)
import Html.Events exposing (onInput)
import Http
import Messages.Comp.PeriodicQueryTaskForm exposing (Texts)
import Styles as S
import Util.Maybe


type alias Model =
    { settings : PeriodicQuerySettings
    , enabled : Bool
    , summary : Maybe String
    , schedule : Maybe CalEvent
    , scheduleModel : Comp.CalEventInput.Model
    , queryModel : Comp.PowerSearchInput.Model
    , channelModel : Comp.ChannelForm.Model
    , formState : FormState
    , loading : Int
    }


type FormState
    = FormStateInitial
    | FormStateHttpError Http.Error
    | FormStateInvalid ValidateError


type ValidateError
    = ValidateCalEventInvalid
    | ValidateQueryStringRequired
    | ValidateChannelRequired


type Action
    = SubmitAction PeriodicQuerySettings
    | StartOnceAction PeriodicQuerySettings
    | CancelAction
    | DeleteAction String
    | NoAction


type Msg
    = Submit
    | ToggleEnabled
    | CalEventMsg Comp.CalEventInput.Msg
    | QueryMsg Comp.PowerSearchInput.Msg
    | ChannelMsg Comp.ChannelForm.Msg
    | StartOnce
    | Cancel
    | RequestDelete
    | SetSummary String


initWith : Flags -> PeriodicQuerySettings -> ( Model, Cmd Msg )
initWith flags s =
    let
        newSchedule =
            Data.CalEvent.fromEvent s.schedule
                |> Maybe.withDefault Data.CalEvent.everyMonth

        ( sm, sc ) =
            Comp.CalEventInput.init flags newSchedule

        res =
            Comp.PowerSearchInput.update
                (Comp.PowerSearchInput.setSearchString s.query)
                Comp.PowerSearchInput.init

        ( cfm, cfc ) =
            Comp.ChannelForm.initWith flags s.channel
    in
    ( { settings = s
      , enabled = s.enabled
      , schedule = Just newSchedule
      , scheduleModel = sm
      , queryModel = res.model
      , channelModel = cfm
      , formState = FormStateInitial
      , loading = 0
      , summary = s.summary
      }
    , Cmd.batch
        [ Cmd.map CalEventMsg sc
        , Cmd.map QueryMsg res.cmd
        , Cmd.map ChannelMsg cfc
        ]
    )


init : Flags -> ChannelType -> ( Model, Cmd Msg )
init flags ct =
    let
        initialSchedule =
            Data.CalEvent.everyMonth

        ( sm, scmd ) =
            Comp.CalEventInput.init flags initialSchedule

        ( cfm, cfc ) =
            Comp.ChannelForm.init flags ct
    in
    ( { settings = Data.PeriodicQuerySettings.empty ct
      , enabled = False
      , schedule = Just initialSchedule
      , scheduleModel = sm
      , queryModel = Comp.PowerSearchInput.init
      , channelModel = cfm
      , formState = FormStateInitial
      , loading = 0
      , summary = Nothing
      }
    , Cmd.batch
        [ Cmd.map CalEventMsg scmd
        , Cmd.map ChannelMsg cfc
        ]
    )



--- Update


type alias UpdateResult =
    { model : Model
    , action : Action
    , cmd : Cmd Msg
    , sub : Sub Msg
    }


makeSettings : Model -> Result ValidateError PeriodicQuerySettings
makeSettings model =
    let
        prev =
            model.settings

        schedule_ =
            case model.schedule of
                Just s ->
                    Ok s

                Nothing ->
                    Err ValidateCalEventInvalid

        queryString =
            Result.fromMaybe ValidateQueryStringRequired model.queryModel.input

        channelM =
            Result.fromMaybe
                ValidateChannelRequired
                (Comp.ChannelForm.getChannel model.channelModel)

        make timer channel query =
            { prev
                | enabled = model.enabled
                , schedule = Data.CalEvent.makeEvent timer
                , summary = model.summary
                , channel = channel
                , query = query
            }
    in
    Result.map3 make
        schedule_
        channelM
        queryString


withValidSettings : (PeriodicQuerySettings -> Action) -> Model -> UpdateResult
withValidSettings mkcmd model =
    case makeSettings model of
        Ok set ->
            { model = { model | formState = FormStateInitial }
            , action = mkcmd set
            , cmd = Cmd.none
            , sub = Sub.none
            }

        Err errs ->
            { model = { model | formState = FormStateInvalid errs }
            , action = NoAction
            , cmd = Cmd.none
            , sub = Sub.none
            }


update : Flags -> Msg -> Model -> UpdateResult
update flags msg model =
    case msg of
        CalEventMsg lmsg ->
            let
                ( cm, cc, cs ) =
                    Comp.CalEventInput.update flags
                        model.schedule
                        lmsg
                        model.scheduleModel
            in
            { model =
                { model
                    | schedule = cs
                    , scheduleModel = cm
                    , formState = FormStateInitial
                }
            , action = NoAction
            , cmd = Cmd.map CalEventMsg cc
            , sub = Sub.none
            }

        QueryMsg lm ->
            let
                res =
                    Comp.PowerSearchInput.update lm model.queryModel
            in
            { model = { model | queryModel = res.model }
            , action = NoAction
            , cmd = Cmd.map QueryMsg res.cmd
            , sub = Sub.map QueryMsg res.subs
            }

        ChannelMsg lm ->
            let
                ( cfm, cfc ) =
                    Comp.ChannelForm.update flags lm model.channelModel
            in
            { model = { model | channelModel = cfm }
            , action = NoAction
            , cmd = Cmd.map ChannelMsg cfc
            , sub = Sub.none
            }

        ToggleEnabled ->
            { model =
                { model
                    | enabled = not model.enabled
                    , formState = FormStateInitial
                }
            , action = NoAction
            , cmd = Cmd.none
            , sub = Sub.none
            }

        Submit ->
            withValidSettings
                SubmitAction
                model

        StartOnce ->
            withValidSettings
                StartOnceAction
                model

        Cancel ->
            { model = model
            , action = CancelAction
            , cmd = Cmd.none
            , sub = Sub.none
            }

        RequestDelete ->
            { model = model
            , action = NoAction
            , cmd = Cmd.none
            , sub = Sub.none
            }

        SetSummary str ->
            { model = { model | summary = Util.Maybe.fromString str }
            , action = NoAction
            , cmd = Cmd.none
            , sub = Sub.none
            }



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


view : Texts -> String -> UiSettings -> Model -> Html Msg
view texts extraClasses settings model =
    let
        startOnceBtn =
            MB.SecondaryButton
                { tagger = StartOnce
                , label = texts.startOnce
                , title = texts.startTaskNow
                , icon = Just "fa fa-play"
                }

        queryInput =
            div
                [ class "relative flex flex-grow flex-row" ]
                [ Html.map QueryMsg
                    (Comp.PowerSearchInput.viewInput
                        { placeholder = texts.queryLabel
                        , extraAttrs = []
                        }
                        model.queryModel
                    )
                , Html.map QueryMsg
                    (Comp.PowerSearchInput.viewResult [] model.queryModel)
                ]

        formHeader txt =
            h2 [ class S.formHeader, class "mt-2" ]
                [ text txt
                ]
    in
    div
        [ class "flex flex-col md:relative"
        , class extraClasses
        ]
        [ B.loadingDimmer
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

                FormStateInvalid ValidateChannelRequired ->
                    text texts.channelRequired

                FormStateInvalid ValidateQueryStringRequired ->
                    text texts.queryStringRequired
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
            [ formHeader (texts.channelHeader (Comp.ChannelForm.channelType model.channelModel))
            , Html.map ChannelMsg
                (Comp.ChannelForm.view texts.channelForm settings model.channelModel)
            ]
        , div [ class "mb-4" ]
            [ formHeader texts.queryLabel
            , label
                [ for "sharequery"
                , class S.inputLabel
                ]
                [ text texts.queryLabel
                , B.inputRequired
                ]
            , queryInput
            ]
        , div [ class "mb-4" ]
            [ formHeader texts.schedule
            , label [ class S.inputLabel ]
                [ text texts.schedule
                , B.inputRequired
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
