{-
   Copyright 2020 Eike K. & Contributors

   SPDX-License-Identifier: AGPL-3.0-or-later
-}


module Comp.BookmarkQueryForm exposing (Model, Msg, get, getName, init, initQuery, initWith, update, view)

import Api
import Api.Model.BookmarkedQuery exposing (BookmarkedQuery)
import Comp.Basic as B
import Comp.PowerSearchInput
import Comp.SimpleTextInput
import Data.Flags exposing (Flags)
import Html exposing (..)
import Html.Attributes exposing (..)
import Html.Events exposing (onCheck)
import Http
import Messages.Comp.BookmarkQueryForm exposing (Texts)
import Styles as S


type alias Model =
    { bookmark : BookmarkedQuery
    , name : Comp.SimpleTextInput.Model
    , nameExists : Bool
    , queryModel : Comp.PowerSearchInput.Model
    , isPersonal : Bool
    }


nameCfg : Comp.SimpleTextInput.Config
nameCfg =
    let
        c =
            Comp.SimpleTextInput.defaultConfig
    in
    { c | delay = 600 }


initQuery : String -> ( Model, Cmd Msg )
initQuery q =
    let
        res =
            Comp.PowerSearchInput.update
                (Comp.PowerSearchInput.setSearchString q)
                Comp.PowerSearchInput.init
    in
    ( { bookmark = Api.Model.BookmarkedQuery.empty
      , name = Comp.SimpleTextInput.init nameCfg Nothing
      , nameExists = False
      , queryModel = res.model
      , isPersonal = True
      }
    , Cmd.batch
        [ Cmd.map QueryMsg res.cmd
        ]
    )


init : ( Model, Cmd Msg )
init =
    initQuery ""


initWith : BookmarkedQuery -> ( Model, Cmd Msg )
initWith bm =
    let
        ( m, c ) =
            initQuery bm.query
    in
    ( { m
        | name = Comp.SimpleTextInput.init nameCfg <| Just bm.name
        , isPersonal = bm.personal
        , bookmark = bm
      }
    , c
    )


isValid : Model -> Bool
isValid model =
    List.all identity
        [ Comp.PowerSearchInput.isValid model.queryModel
        , getName model /= Nothing
        , not model.nameExists
        ]


getName : Model -> Maybe String
getName model =
    Comp.SimpleTextInput.getValue model.name


get : Model -> Maybe BookmarkedQuery
get model =
    let
        qStr =
            Comp.PowerSearchInput.getSearchString model.queryModel
                |> Maybe.withDefault ""

        bm =
            model.bookmark
    in
    if isValid model then
        Just
            { bm
                | query = qStr
                , name = getName model |> Maybe.withDefault ""
                , personal = model.isPersonal
            }

    else
        Nothing


type Msg
    = SetName Comp.SimpleTextInput.Msg
    | QueryMsg Comp.PowerSearchInput.Msg
    | SetPersonal Bool
    | NameExistsResp (Result Http.Error Bool)


update : Flags -> Msg -> Model -> ( Model, Cmd Msg, Sub Msg )
update flags msg model =
    let
        nameCheck1 name =
            Api.bookmarkNameExists flags name NameExistsResp
    in
    case msg of
        SetName lm ->
            let
                result =
                    Comp.SimpleTextInput.update lm model.name

                cmd =
                    case result.change of
                        Comp.SimpleTextInput.ValueUnchanged ->
                            Cmd.none

                        Comp.SimpleTextInput.ValueUpdated v ->
                            Maybe.map nameCheck1 v |> Maybe.withDefault Cmd.none
            in
            ( { model | name = result.model }
            , Cmd.batch [ cmd, Cmd.map SetName result.cmd ]
            , Sub.map SetName result.sub
            )

        SetPersonal flag ->
            ( { model | isPersonal = flag }, Cmd.none, Sub.none )

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

        NameExistsResp (Err _) ->
            ( model, Cmd.none, Sub.none )



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
            , Html.map SetName
                (Comp.SimpleTextInput.view [ placeholder texts.basics.name, class S.textInput, id "bookmark-name" ] model.name)

            -- , input
            --     [ type_ "text"
            --     , onInput SetName
            --     , placeholder texts.basics.name
            --     , value <| Maybe.withDefault "" model.name
            --     , id "bookmark-name"
            --     , class S.textInput
            --     ]
            --     []
            , span
                [ class S.warnMessagePlain
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
                    , checked model.isPersonal
                    , onCheck (\_ -> SetPersonal True)
                    , class S.radioInput
                    ]
                    []
                , span [ class "ml-2" ] [ text texts.userLocation ]
                , span [ class "ml-3 opacity-75 text-sm" ] [ text texts.userLocationText ]
                ]
            , label [ class "inline-flex items-center" ]
                [ input
                    [ type_ "radio"
                    , checked (not model.isPersonal)
                    , class S.radioInput
                    , onCheck (\_ -> SetPersonal False)
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
