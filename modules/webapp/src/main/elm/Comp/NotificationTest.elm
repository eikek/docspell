{-
   Copyright 2020 Eike K. & Contributors

   SPDX-License-Identifier: AGPL-3.0-or-later
-}


module Comp.NotificationTest exposing (Model, Msg, ViewConfig, init, update, view)

import Api
import Api.Model.NotificationChannelTestResult exposing (NotificationChannelTestResult)
import Api.Model.NotificationHook exposing (NotificationHook)
import Comp.Basic as B
import Comp.MenuBar as MB
import Data.Flags exposing (Flags)
import Html exposing (..)
import Html.Attributes exposing (..)
import Html.Events exposing (onClick)
import Http


type Model
    = ModelInit
    | ModelResp NotificationChannelTestResult
    | ModelHttpError Http.Error
    | ModelLoading


init : Model
init =
    ModelInit


type Msg
    = RunTest
    | TestResp (Result Http.Error NotificationChannelTestResult)


hasResponse : Model -> Bool
hasResponse model =
    case model of
        ModelResp _ ->
            True

        _ ->
            False



--- Update


update : Flags -> NotificationHook -> Msg -> Model -> ( Model, Cmd Msg )
update flags hook msg model =
    case msg of
        RunTest ->
            case model of
                ModelLoading ->
                    ( model, Cmd.none )

                _ ->
                    ( ModelLoading, Api.testHook flags hook TestResp )

        TestResp (Ok res) ->
            ( ModelResp res, Cmd.none )

        TestResp (Err err) ->
            ( ModelHttpError err, Cmd.none )



--- View


type alias ViewConfig =
    { runDisabled : Bool
    }


styleBase : String
styleBase =
    "bg-gray-100 dark:bg-slate-900 text-gray-900 dark:text-gray-100 text-sm leading-5"


stylePayload : String
stylePayload =
    "px-2 font-mono overflow-auto h-full whitespace-pre "


view : ViewConfig -> Model -> Html Msg
view cfg model =
    div
        [ class "flex flex-col w-full"
        ]
        [ MB.view
            { start =
                case model of
                    ModelResp res ->
                        [ MB.CustomElement <|
                            if res.success then
                                div [ class "text-3xl text-green-500" ]
                                    [ i [ class "fa fa-check" ] []
                                    ]

                            else
                                div [ class "text-3xl text-red-500" ]
                                    [ i [ class "fa fa-times" ] []
                                    ]
                        ]

                    _ ->
                        []
            , end =
                [ MB.CustomElement <|
                    B.primaryButton
                        { label = "Test Delivery"
                        , disabled = cfg.runDisabled || model == ModelLoading
                        , icon =
                            if model == ModelLoading then
                                "fa fa-cog animate-spin"

                            else
                                "fa fa-cog"
                        , handler = onClick RunTest
                        , attrs = [ href "#" ]
                        }
                ]
            , rootClasses = "mb-1"
            }
        , case model of
            ModelResp res ->
                div
                    [ class "flex flex-col py-5 px-2"
                    , class styleBase
                    , class stylePayload
                    ]
                    [ text (String.join "\n" res.messages)
                    ]

            ModelHttpError err ->
                div [ class "" ]
                    []

            _ ->
                span [ class "hidden" ] []
        ]
