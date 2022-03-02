{-
   Copyright 2020 Eike K. & Contributors

   SPDX-License-Identifier: AGPL-3.0-or-later
-}


module Comp.NotificationHookForm exposing
    ( Model
    , Msg(..)
    , getHook
    , init
    , initWith
    , update
    , view
    )

import Api.Model.NotificationHook exposing (NotificationHook)
import Comp.Basic as B
import Comp.ChannelRefInput
import Comp.Dropdown
import Comp.EventSample
import Comp.MenuBar as MB
import Comp.NotificationTest
import Data.DropdownStyle as DS
import Data.EventType exposing (EventType)
import Data.Flags exposing (Flags)
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
    , channelModel : Comp.ChannelRefInput.Model
    , eventsDropdown : Comp.Dropdown.Model EventType
    , eventSampleModel : Comp.EventSample.Model
    , testDeliveryModel : Comp.NotificationTest.Model
    , allEvents : Bool
    , eventFilter : Maybe String
    }


init : Flags -> ( Model, Cmd Msg )
init flags =
    let
        ( cm, cc ) =
            Comp.ChannelRefInput.init flags

        ( esm, esc ) =
            Comp.EventSample.initWith flags Data.EventType.TagsChanged
    in
    ( { hook = Api.Model.NotificationHook.empty
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
            Comp.ChannelRefInput.initSelected flags h.channels

        ( esm, esc ) =
            Comp.EventSample.initWith flags Data.EventType.TagsChanged
    in
    ( { hook = h
      , enabled = h.enabled
      , channelModel = cm
      , eventsDropdown =
            Comp.Dropdown.makeMultipleList
                { options = Data.EventType.all
                , selected = List.filterMap Data.EventType.fromString h.events
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
                Just (List.map Data.EventType.asString ev)

        channels =
            let
                list =
                    Comp.ChannelRefInput.getSelected model.channelModel
            in
            if list == [] then
                Nothing

            else
                Just list

        mkHook ev ch =
            NotificationHook model.hook.id model.enabled ch model.allEvents model.eventFilter ev
    in
    Maybe.map2 mkHook events channels


type Msg
    = ToggleEnabled
    | ChannelFormMsg Comp.ChannelRefInput.Msg
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
                    Comp.ChannelRefInput.update lm model.channelModel
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
            [ formHeader texts.channelHeader
            , Html.map ChannelFormMsg
                (Comp.ChannelRefInput.view texts.channelRef settings model.channelModel)
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
            ]
            [ formHeader texts.samplePayload
            , div [ class "opacity-80 mb-1" ]
                [ text texts.payloadInfo
                ]
            , Html.map EventSampleMsg
                (Comp.EventSample.viewMessage texts.eventSample True model.eventSampleModel)
            , div [ class "py-2 text-center text-sm" ]
                [ text texts.jsonPayload
                , i [ class "fa fa-arrow-down ml-1 mr-3" ] []
                , i [ class "fa fa-arrow-up mr-1" ] []
                , text texts.messagePayload
                ]
            , Html.map EventSampleMsg
                (Comp.EventSample.viewJson texts.eventSample False model.eventSampleModel)
            ]
        , div [ class "mt-4" ]
            [ formHeader "Test Delivery"
            , Html.map DeliveryTestMsg
                (Comp.NotificationTest.view
                    { runDisabled = getHook model == Nothing }
                    model.testDeliveryModel
                )
            ]
        ]
