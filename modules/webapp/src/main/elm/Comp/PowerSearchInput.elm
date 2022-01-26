{-
   Copyright 2020 Eike K. & Contributors

   SPDX-License-Identifier: AGPL-3.0-or-later
-}


module Comp.PowerSearchInput exposing
    ( Action(..)
    , Model
    , Msg
    , ViewSettings
    , init
    , initWith
    , isValid
    , setSearchString
    , update
    , viewInput
    , viewResult
    )

import Data.QueryParseResult exposing (QueryParseResult)
import Html exposing (..)
import Html.Attributes exposing (..)
import Html.Events exposing (onInput)
import Ports
import Styles as S
import Throttle exposing (Throttle)
import Time
import Util.Html exposing (KeyCode(..))
import Util.Maybe


type alias Model =
    { input : Maybe String
    , result : QueryParseResult
    , parseThrottle : Throttle Msg
    }


init : Model
init =
    { input = Nothing
    , result = Data.QueryParseResult.success
    , parseThrottle = Throttle.create 1
    }


initWith : String -> ( Model, Cmd Msg, Sub Msg )
initWith qstr =
    let
        result =
            update (setSearchString qstr) init
    in
    ( result.model, result.cmd, result.subs )


isValid : Model -> Bool
isValid model =
    model.input /= Nothing && model.result.success


type Msg
    = SetSearch String
    | KeyUpMsg (Maybe KeyCode)
    | ParseResultMsg QueryParseResult
    | UpdateThrottle


type Action
    = NoAction
    | SubmitSearch


type alias Result =
    { model : Model
    , cmd : Cmd Msg
    , action : Action
    , subs : Sub Msg
    }


setSearchString : String -> Msg
setSearchString q =
    SetSearch q



--- Update


update : Msg -> Model -> Result
update msg model =
    case msg of
        SetSearch str ->
            let
                parseCmd =
                    Ports.checkSearchQueryString str

                parseSub =
                    Ports.receiveCheckQueryResult ParseResultMsg

                ( newThrottle, cmd ) =
                    Throttle.try parseCmd model.parseThrottle

                model_ =
                    { model
                        | input = Util.Maybe.fromString str
                        , parseThrottle = newThrottle
                        , result =
                            if str == "" then
                                Data.QueryParseResult.success

                            else
                                model.result
                    }
            in
            { model = model_
            , cmd = cmd
            , action = NoAction
            , subs = Sub.batch [ throttleUpdate model_, parseSub ]
            }

        KeyUpMsg (Just Enter) ->
            Result model Cmd.none SubmitSearch Sub.none

        KeyUpMsg _ ->
            let
                parseSub =
                    Ports.receiveCheckQueryResult ParseResultMsg
            in
            Result model Cmd.none NoAction (Sub.batch [ throttleUpdate model, parseSub ])

        ParseResultMsg lm ->
            Result { model | result = lm } Cmd.none NoAction Sub.none

        UpdateThrottle ->
            let
                parseSub =
                    Ports.receiveCheckQueryResult ParseResultMsg

                ( newThrottle, cmd ) =
                    Throttle.update model.parseThrottle

                model_ =
                    { model | parseThrottle = newThrottle }
            in
            { model = model_
            , cmd = cmd
            , action = NoAction
            , subs = Sub.batch [ throttleUpdate model_, parseSub ]
            }


throttleUpdate : Model -> Sub Msg
throttleUpdate model =
    Throttle.ifNeeded
        (Time.every 100 (\_ -> UpdateThrottle))
        model.parseThrottle



--- View


type alias ViewSettings =
    { placeholder : String
    , extraAttrs : List (Attribute Msg)
    }


viewInput : ViewSettings -> Model -> Html Msg
viewInput cfg model =
    input
        (cfg.extraAttrs
            ++ [ type_ "text"
               , placeholder cfg.placeholder
               , onInput SetSearch
               , Util.Html.onKeyUpCode KeyUpMsg
               , Maybe.map value model.input
                    |> Maybe.withDefault (value "")
               , class S.textInput
               , class "text-sm "
               ]
        )
        []


viewResult : List ( String, Bool ) -> Model -> Html Msg
viewResult classes model =
    div
        [ classList [ ( "hidden", model.result.success ) ]
        , classList classes
        , class resultStyle
        ]
        [ p [ class "font-mono text-sm" ]
            [ text model.result.input
            ]
        , pre [ class "font-mono text-sm" ]
            [ List.repeat model.result.index " "
                |> String.join ""
                |> text
            , text "^"
            ]
        , ul []
            (List.map (\line -> li [] [ text line ]) model.result.messages)
        ]


resultStyle : String
resultStyle =
    S.warnMessageColors ++ " absolute left-0 max-h-44 w-full overflow-y-auto z-50 shadow-lg transition duration-200 top-9 border-0 border-b border-l border-r rounded-b px-2 py-2"
