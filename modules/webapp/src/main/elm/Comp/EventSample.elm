{-
   Copyright 2020 Eike K. & Contributors

   SPDX-License-Identifier: AGPL-3.0-or-later
-}


module Comp.EventSample exposing (Model, Msg, init, initWith, update, viewJson, viewMessage)

import Api
import Comp.FixedDropdown
import Data.DropdownStyle as DS
import Data.EventType exposing (EventType)
import Data.Flags exposing (Flags)
import Html exposing (..)
import Html.Attributes exposing (..)
import Http
import Json.Decode as D
import Json.Print
import Markdown
import Messages.Comp.EventSample exposing (Texts)


type alias Model =
    { eventTypeDropdown : Comp.FixedDropdown.Model EventType
    , selectedEventType : Maybe EventType
    , content : String
    }


init : Model
init =
    { eventTypeDropdown = Comp.FixedDropdown.init Data.EventType.all
    , selectedEventType = Nothing
    , content = ""
    }


initWith : Flags -> EventType -> ( Model, Cmd Msg )
initWith flags evt =
    ( { init | selectedEventType = Just evt }
    , Api.sampleEvent flags evt SampleEvent
    )


type Msg
    = EventTypeMsg (Comp.FixedDropdown.Msg EventType)
    | SampleEvent (Result Http.Error String)



--- Update


update : Flags -> Msg -> Model -> ( Model, Cmd Msg )
update flags msg model =
    case msg of
        EventTypeMsg lm ->
            let
                ( evm, evt ) =
                    Comp.FixedDropdown.update lm model.eventTypeDropdown

                sampleCmd =
                    case evt of
                        Just ev ->
                            Api.sampleEvent flags ev SampleEvent

                        Nothing ->
                            Cmd.none
            in
            ( { model
                | eventTypeDropdown = evm
                , selectedEventType = evt
              }
            , sampleCmd
            )

        SampleEvent (Ok str) ->
            ( { model | content = str }, Cmd.none )

        SampleEvent (Err err) ->
            ( model, Cmd.none )



--- View


styleBase : String
styleBase =
    "bg-gray-100 dark:bg-bluegray-900 text-gray-900 dark:text-gray-100 text-sm leading-5"


stylePayload : String
stylePayload =
    "px-2 font-mono overflow-auto max-h-96 h-full whitespace-pre"


styleMessage : String
styleMessage =
    "-my-2 "


jsonPrettyCfg =
    { indent = 2
    , columns = 80
    }


dropdownCfg texts =
    { display = texts.eventType >> .name
    , icon = \_ -> Nothing
    , selectPlaceholder = texts.selectEvent
    , style = DS.mainStyleWith "w-48"
    }


viewJson : Texts -> Model -> Html Msg
viewJson texts model =
    let
        json =
            Result.withDefault ""
                (Json.Print.prettyString jsonPrettyCfg model.content)
    in
    div
        [ class "flex flex-col w-full relative"
        ]
        [ div [ class "flex inline-flex items-center absolute top-2 right-4" ]
            [ Html.map EventTypeMsg
                (Comp.FixedDropdown.viewStyled2 (dropdownCfg texts)
                    False
                    model.selectedEventType
                    model.eventTypeDropdown
                )
            ]
        , div
            [ class "flex pt-5"
            , class styleBase
            , class stylePayload
            , classList [ ( "hidden", json == "" ) ]
            ]
            [ text json
            ]
        ]


viewMessage : Texts -> Model -> Html Msg
viewMessage texts model =
    let
        titleDecoder =
            D.at [ "message", "title" ] D.string

        bodyDecoder =
            D.at [ "message", "body" ] D.string

        title =
            D.decodeString titleDecoder model.content

        body =
            D.decodeString bodyDecoder model.content
    in
    div
        [ class "flex flex-col w-full relative"
        ]
        [ div [ class "flex inline-flex items-center absolute top-2 right-4" ]
            [ Html.map EventTypeMsg
                (Comp.FixedDropdown.viewStyled2 (dropdownCfg texts)
                    False
                    model.selectedEventType
                    model.eventTypeDropdown
                )
            ]
        , div
            [ class "flex flex-col py-5 px-2 markdown-preview"
            , class styleBase
            ]
            [ Markdown.toHtml [ class styleMessage ]
                (Result.withDefault "" title)
            , Markdown.toHtml [ class styleMessage ]
                (Result.withDefault "" body)
            ]
        ]
