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
import Comp.BookmarkDropdown
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
import Html.Events exposing (onClick, onInput)
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
    , bookmarkDropdown : Comp.BookmarkDropdown.Model
    , formState : FormState
    , loading : Int
    , deleteRequested : Bool
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
    | BookmarkMsg Comp.BookmarkDropdown.Msg
    | StartOnce
    | Cancel
    | RequestDelete
    | SetSummary String
    | DeleteTaskNow String
    | CancelDelete


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
                (Comp.PowerSearchInput.setSearchString (Maybe.withDefault "" s.query))
                Comp.PowerSearchInput.init

        ( cfm, cfc ) =
            Comp.ChannelForm.initWith flags s.channel

        ( bm, bc ) =
            Comp.BookmarkDropdown.init flags s.bookmark
    in
    ( { settings = s
      , enabled = s.enabled
      , schedule = Just newSchedule
      , scheduleModel = sm
      , queryModel = res.model
      , channelModel = cfm
      , bookmarkDropdown = bm
      , formState = FormStateInitial
      , loading = 0
      , summary = s.summary
      , deleteRequested = False
      }
    , Cmd.batch
        [ Cmd.map CalEventMsg sc
        , Cmd.map QueryMsg res.cmd
        , Cmd.map ChannelMsg cfc
        , Cmd.map BookmarkMsg bc
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

        ( bm, bc ) =
            Comp.BookmarkDropdown.init flags Nothing
    in
    ( { settings = Data.PeriodicQuerySettings.empty ct
      , enabled = False
      , schedule = Just initialSchedule
      , scheduleModel = sm
      , queryModel = Comp.PowerSearchInput.init
      , channelModel = cfm
      , bookmarkDropdown = bm
      , formState = FormStateInitial
      , loading = 0
      , summary = Nothing
      , deleteRequested = False
      }
    , Cmd.batch
        [ Cmd.map CalEventMsg scmd
        , Cmd.map ChannelMsg cfc
        , Cmd.map BookmarkMsg bc
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

        query =
            let
                qstr =
                    model.queryModel.input

                bm =
                    Comp.BookmarkDropdown.getSelectedId model.bookmarkDropdown
            in
            case ( qstr, bm ) of
                ( Nothing, Nothing ) ->
                    Result.Err ValidateQueryStringRequired

                ( _, _ ) ->
                    Result.Ok ( qstr, bm )

        channelM =
            Result.fromMaybe
                ValidateChannelRequired
                (Comp.ChannelForm.getChannel model.channelModel)

        make timer channel q =
            { prev
                | enabled = model.enabled
                , schedule = Data.CalEvent.makeEvent timer
                , summary = model.summary
                , channel = channel
                , query = Tuple.first q
                , bookmark = Tuple.second q
            }
    in
    Result.map3 make
        schedule_
        channelM
        query


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

        BookmarkMsg lm ->
            let
                ( bm, bc ) =
                    Comp.BookmarkDropdown.update lm model.bookmarkDropdown
            in
            { model = { model | bookmarkDropdown = bm }
            , action = NoAction
            , cmd = Cmd.map BookmarkMsg bc
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
            { model = { model | deleteRequested = True }
            , action = NoAction
            , cmd = Cmd.none
            , sub = Sub.none
            }

        DeleteTaskNow id ->
            { model = { model | deleteRequested = False }
            , action = DeleteAction id
            , cmd = Cmd.none
            , sub = Sub.none
            }

        CancelDelete ->
            { model = { model | deleteRequested = False }
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

        formHeader txt req =
            h2 [ class S.formHeader, class "mt-2" ]
                [ text txt
                , if req then
                    B.inputRequired

                  else
                    span [] []
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
        , B.contentDimmer
            model.deleteRequested
            (div [ class "flex flex-col" ]
                [ div [ class "text-lg" ]
                    [ i [ class "fa fa-info-circle mr-2" ] []
                    , text texts.reallyDeleteTask
                    ]
                , div [ class "mt-4 flex flex-row items-center" ]
                    [ B.deleteButton
                        { label = texts.basics.yes
                        , icon = "fa fa-check"
                        , disabled = False
                        , handler = onClick (DeleteTaskNow model.settings.id)
                        , attrs = [ href "#" ]
                        }
                    , B.secondaryButton
                        { label = texts.basics.no
                        , icon = "fa fa-times"
                        , disabled = False
                        , handler = onClick CancelDelete
                        , attrs = [ href "#", class "ml-2" ]
                        }
                    ]
                ]
            )
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
            [ formHeader (texts.channelHeader (Comp.ChannelForm.channelType model.channelModel)) False
            , Html.map ChannelMsg
                (Comp.ChannelForm.view texts.channelForm settings model.channelModel)
            ]
        , div [ class "mb-4" ]
            [ formHeader texts.queryLabel True
            , div [ class "mb-3" ]
                [ label [ class S.inputLabel ]
                    [ text "Bookmark" ]
                , Html.map BookmarkMsg (Comp.BookmarkDropdown.view texts.bookmarkDropdown settings model.bookmarkDropdown)
                ]
            , div [ class "mb-3" ]
                [ label
                    [ for "sharequery"
                    , class S.inputLabel
                    ]
                    [ text texts.queryLabel
                    ]
                , queryInput
                ]
            ]
        , div [ class "mb-4" ]
            [ formHeader texts.schedule False
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
