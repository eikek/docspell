{-
   Copyright 2020 Eike K. & Contributors

   SPDX-License-Identifier: AGPL-3.0-or-later
-}


module Comp.BookmarkQueryForm exposing (Model, Msg, get, init, initQuery, initWith, update, view)

import Api
import Comp.Basic as B
import Comp.PowerSearchInput
import Data.BookmarkedQuery exposing (BookmarkedQueryDef, Location(..))
import Data.Flags exposing (Flags)
import Html exposing (..)
import Html.Attributes exposing (..)
import Html.Events exposing (onCheck, onInput)
import Http
import Messages.Comp.BookmarkQueryForm exposing (Texts)
import Styles as S
import Throttle exposing (Throttle)
import Time
import Util.Maybe


type alias Model =
    { name : Maybe String
    , nameExists : Bool
    , queryModel : Comp.PowerSearchInput.Model
    , location : Location
    , nameExistsThrottle : Throttle Msg
    }


initQuery : String -> ( Model, Cmd Msg )
initQuery q =
    let
        res =
            Comp.PowerSearchInput.update
                (Comp.PowerSearchInput.setSearchString q)
                Comp.PowerSearchInput.init
    in
    ( { name = Nothing
      , nameExists = False
      , queryModel = res.model
      , location = User
      , nameExistsThrottle = Throttle.create 1
      }
    , Cmd.batch
        [ Cmd.map QueryMsg res.cmd
        ]
    )


init : ( Model, Cmd Msg )
init =
    initQuery ""


initWith : BookmarkedQueryDef -> ( Model, Cmd Msg )
initWith bm =
    let
        ( m, c ) =
            initQuery bm.query.query
    in
    ( { m
        | name = Just bm.query.name
        , location = bm.location
      }
    , c
    )


isValid : Model -> Bool
isValid model =
    Comp.PowerSearchInput.isValid model.queryModel
        && model.name
        /= Nothing


get : Model -> Maybe BookmarkedQueryDef
get model =
    let
        qStr =
            Maybe.withDefault "" model.queryModel.input
    in
    if isValid model then
        Just
            { query =
                { query = qStr
                , name = Maybe.withDefault "" model.name
                }
            , location = model.location
            }

    else
        Nothing


type Msg
    = SetName String
    | QueryMsg Comp.PowerSearchInput.Msg
    | SetLocation Location
    | NameExistsResp (Result Http.Error Bool)
    | UpdateThrottle


update : Flags -> Msg -> Model -> ( Model, Cmd Msg, Sub Msg )
update flags msg model =
    let
        nameCheck1 name =
            Api.bookmarkNameExists flags model.location name NameExistsResp

        nameCheck2 loc =
            case model.name of
                Just n ->
                    Api.bookmarkNameExists flags loc n NameExistsResp

                Nothing ->
                    Cmd.none

        throttleSub =
            Throttle.ifNeeded
                (Time.every 150 (\_ -> UpdateThrottle))
                model.nameExistsThrottle
    in
    case msg of
        SetName n ->
            let
                ( newThrottle, cmd ) =
                    Throttle.try (nameCheck1 n) model.nameExistsThrottle
            in
            ( { model | name = Util.Maybe.fromString n, nameExistsThrottle = newThrottle }
            , cmd
            , throttleSub
            )

        SetLocation loc ->
            let
                ( newThrottle, cmd ) =
                    Throttle.try (nameCheck2 loc) model.nameExistsThrottle
            in
            ( { model | location = loc, nameExistsThrottle = newThrottle }, cmd, throttleSub )

        QueryMsg lm ->
            let
                res =
                    Comp.PowerSearchInput.update lm model.queryModel
            in
            ( { model | queryModel = res.model }
            , Cmd.map QueryMsg res.cmd
            , Sub.map QueryMsg res.subs
            )

        NameExistsResp (Ok flag) ->
            ( { model | nameExists = flag }
            , Cmd.none
            , Sub.none
            )

        NameExistsResp (Err err) ->
            ( model, Cmd.none, Sub.none )

        UpdateThrottle ->
            let
                ( newThrottle, cmd ) =
                    Throttle.update model.nameExistsThrottle
            in
            ( { model | nameExistsThrottle = newThrottle }
            , cmd
            , throttleSub
            )



--- View


view : Texts -> Model -> Html Msg
view texts model =
    let
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
    in
    div
        [ class "flex flex-col" ]
        [ div [ class "mb-2" ]
            [ label
                [ for "bookmark-name"
                , class S.inputLabel
                ]
                [ text texts.basics.name
                , B.inputRequired
                ]
            , input
                [ type_ "text"
                , onInput SetName
                , placeholder texts.basics.name
                , value <| Maybe.withDefault "" model.name
                , id "bookmark-name"
                , class S.textInput
                ]
                []
            , span
                [ class S.infoMessagePlain
                , class "font-medium text-sm"
                , classList [ ( "invisible", not model.nameExists ) ]
                ]
                [ text texts.nameExistsWarning
                ]
            ]
        , div [ class "flex flex-col mb-4 " ]
            [ label [ class "inline-flex items-center" ]
                [ input
                    [ type_ "radio"
                    , checked (model.location == User)
                    , onCheck (\_ -> SetLocation User)
                    , class S.radioInput
                    ]
                    []
                , span [ class "ml-2" ] [ text texts.userLocation ]
                , span [ class "ml-3 opacity-75 text-sm" ] [ text texts.userLocationText ]
                ]
            , label [ class "inline-flex items-center" ]
                [ input
                    [ type_ "radio"
                    , checked (model.location == Collective)
                    , class S.radioInput
                    , onCheck (\_ -> SetLocation Collective)
                    ]
                    []
                , span [ class "ml-2" ] [ text texts.collectiveLocation ]
                , span [ class "ml-3 opacity-75 text-sm" ] [ text texts.collectiveLocationText ]
                ]
            ]
        , div [ class "mb-4" ]
            [ label
                [ for "sharequery"
                , class S.inputLabel
                ]
                [ text texts.queryLabel
                , B.inputRequired
                ]
            , queryInput
            ]
        ]
