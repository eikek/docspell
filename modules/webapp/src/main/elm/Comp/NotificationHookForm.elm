{-
   Copyright 2020 Eike K. & Contributors

   SPDX-License-Identifier: AGPL-3.0-or-later
-}


module Comp.NotificationHookForm exposing
    ( Model
    , Msg(..)
    , channelType
    , getHook
    , init
    , initWith
    , update
    , view
    )

import Comp.Basic as B
import Comp.ChannelForm
import Comp.Dropdown
import Comp.EventSample
import Comp.MenuBar as MB
import Comp.NotificationTest
import Data.ChannelType exposing (ChannelType)
import Data.DropdownStyle as DS
import Data.EventType exposing (EventType)
import Data.Flags exposing (Flags)
import Data.NotificationHook exposing (NotificationHook)
import Data.UiSettings exposing (UiSettings)
import Html exposing (..)
import Html.Attributes exposing (..)
import Html.Events exposing (onInput)
import Messages.Comp.NotificationHookForm exposing (Texts)
import Styles as S
import Util.Maybe


type alias Model =
    { hook : NotificationHook
    , enabled : Bool
    , channelModel : Comp.ChannelForm.Model
    , eventsDropdown : Comp.Dropdown.Model EventType
    , eventSampleModel : Comp.EventSample.Model
    , testDeliveryModel : Comp.NotificationTest.Model
    , allEvents : Bool
    , eventFilter : Maybe String
    }


init : Flags -> ChannelType -> ( Model, Cmd Msg )
init flags ct =
    let
        ( cm, cc ) =
            Comp.ChannelForm.init flags ct

        ( esm, esc ) =
            Comp.EventSample.initWith flags Data.EventType.TagsChanged
    in
    ( { hook = Data.NotificationHook.empty ct
      , enabled = True
      , channelModel = cm
      , eventsDropdown =
            Comp.Dropdown.makeMultipleList
                { options = Data.EventType.all
                , selected = []
                }
      , eventSampleModel = esm
      , testDeliveryModel = Comp.NotificationTest.init
      , allEvents = False
      , eventFilter = Nothing
      }
    , Cmd.batch
        [ Cmd.map ChannelFormMsg cc
        , Cmd.map EventSampleMsg esc
        ]
    )


initWith : Flags -> NotificationHook -> ( Model, Cmd Msg )
initWith flags h =
    let
        ( cm, cc ) =
            Comp.ChannelForm.initWith flags h.channel

        ( esm, esc ) =
            Comp.EventSample.initWith flags Data.EventType.TagsChanged
    in
    ( { hook = h
      , enabled = h.enabled
      , channelModel = cm
      , eventsDropdown =
            Comp.Dropdown.makeMultipleList
                { options = Data.EventType.all
                , selected = h.events
                }
      , eventSampleModel = esm
      , testDeliveryModel = Comp.NotificationTest.init
      , allEvents = h.allEvents
      , eventFilter = h.eventFilter
      }
    , Cmd.batch
        [ Cmd.map ChannelFormMsg cc
        , Cmd.map EventSampleMsg esc
        ]
    )


channelType : Model -> ChannelType
channelType model =
    Comp.ChannelForm.channelType model.channelModel


getHook : Model -> Maybe NotificationHook
getHook model =
    let
        events =
            let
                ev =
                    Comp.Dropdown.getSelected model.eventsDropdown
            in
            if List.isEmpty ev && not model.allEvents then
                Nothing

            else
                Just ev

        channel =
            Comp.ChannelForm.getChannel model.channelModel

        mkHook ev ch =
            NotificationHook model.hook.id model.enabled ch model.allEvents model.eventFilter ev
    in
    Maybe.map2 mkHook events channel


type Msg
    = ToggleEnabled
    | ChannelFormMsg Comp.ChannelForm.Msg
    | EventMsg (Comp.Dropdown.Msg EventType)
    | EventSampleMsg Comp.EventSample.Msg
    | DeliveryTestMsg Comp.NotificationTest.Msg
    | ToggleAllEvents
    | SetEventFilter String


update : Flags -> Msg -> Model -> ( Model, Cmd Msg )
update flags msg model =
    case msg of
        SetEventFilter str ->
            ( { model | eventFilter = Util.Maybe.fromString str }, Cmd.none )

        ToggleAllEvents ->
            ( { model | allEvents = not model.allEvents }
            , Cmd.none
            )

        ToggleEnabled ->
            ( { model | enabled = not model.enabled }
            , Cmd.none
            )

        ChannelFormMsg lm ->
            let
                ( cm, cc ) =
                    Comp.ChannelForm.update flags lm model.channelModel
            in
            ( { model | channelModel = cm }, Cmd.map ChannelFormMsg cc )

        EventMsg lm ->
            if model.allEvents then
                ( model, Cmd.none )

            else
                let
                    ( em, ec ) =
                        Comp.Dropdown.update lm model.eventsDropdown
                in
                ( { model | eventsDropdown = em }, Cmd.map EventMsg ec )

        EventSampleMsg lm ->
            let
                ( esm, esc ) =
                    Comp.EventSample.update flags lm model.eventSampleModel
            in
            ( { model | eventSampleModel = esm }, Cmd.map EventSampleMsg esc )

        DeliveryTestMsg lm ->
            case getHook model of
                Just hook ->
                    let
                        ( ntm, ntc ) =
                            Comp.NotificationTest.update flags hook lm model.testDeliveryModel
                    in
                    ( { model | testDeliveryModel = ntm }, Cmd.map DeliveryTestMsg ntc )

                Nothing ->
                    ( model, Cmd.none )



--- View


view : Texts -> UiSettings -> Model -> Html Msg
view texts settings model =
    let
        connectionCfg =
            { makeOption = \a -> { text = (texts.eventType a).name, additional = (texts.eventType a).info }
            , placeholder = texts.selectEvents
            , labelColor = \_ -> \_ -> ""
            , style = DS.mainStyle
            }

        formHeader txt =
            h2 [ class S.formHeader, class "mt-2" ]
                [ text txt
                ]
    in
    div
        [ class "flex flex-col" ]
        [ div [ class "mb-4" ]
            [ MB.viewItem <|
                MB.Checkbox
                    { tagger = \_ -> ToggleEnabled
                    , label = texts.enableDisable
                    , value = model.enabled
                    , id = "notify-enabled"
                    }
            ]
        , div [ class "mb-4" ]
            [ formHeader (texts.channelHeader (Comp.ChannelForm.channelType model.channelModel))
            , Html.map ChannelFormMsg
                (Comp.ChannelForm.view texts.channelForm settings model.channelModel)
            ]
        , div [ class "mb-4" ]
            [ formHeader texts.events
            , MB.viewItem <|
                MB.Checkbox
                    { tagger = \_ -> ToggleAllEvents
                    , label = texts.toggleAllEvents
                    , value = model.allEvents
                    , id = "notify-on-all-events"
                    }
            ]
        , div
            [ class "mb-4"
            , classList [ ( "disabled", model.allEvents ) ]
            ]
            [ label [ class S.inputLabel ]
                [ text texts.events
                , B.inputRequired
                ]
            , Html.map EventMsg
                (Comp.Dropdown.view2
                    connectionCfg
                    settings
                    model.eventsDropdown
                )
            , span [ class "opacity-50 text-sm" ]
                [ text texts.eventsInfo
                ]
            ]
        , div [ class "mb-4" ]
            [ label [ class S.inputLabel ]
                [ text texts.eventFilter
                , a
                    [ class "float-right"
                    , class S.link
                    , href "https://docspell.org/docs/jsonminiquery/"
                    , target "_blank"
                    ]
                    [ i [ class "fa fa-question" ] []
                    , span [ class "pl-2" ]
                        [ text texts.eventFilterClickForHelp
                        ]
                    ]
                ]
            , input
                [ type_ "text"
                , onInput SetEventFilter
                , class S.textInput
                , Maybe.withDefault "" model.eventFilter
                    |> value
                ]
                []
            , span [ class "opacity-50 text-sm" ]
                [ text texts.eventFilterInfo
                ]
            ]
        , div
            [ class "mt-4"
            , classList [ ( "hidden", channelType model /= Data.ChannelType.Http ) ]
            ]
            [ h3 [ class S.header3 ]
                [ text texts.samplePayload
                ]
            , Html.map EventSampleMsg
                (Comp.EventSample.viewJson texts.eventSample model.eventSampleModel)
            ]
        , div
            [ class "mt-4"
            , classList [ ( "hidden", channelType model == Data.ChannelType.Http ) ]
            ]
            [ formHeader texts.samplePayload
            , Html.map EventSampleMsg
                (Comp.EventSample.viewMessage texts.eventSample model.eventSampleModel)
            ]
        , div [ class "mt-4" ]
            [ formHeader "Test Delviery"
            , Html.map DeliveryTestMsg
                (Comp.NotificationTest.view
                    { runDisabled = getHook model == Nothing }
                    model.testDeliveryModel
                )
            ]
        ]
