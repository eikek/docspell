{-
   Copyright 2020 Eike K. & Contributors

   SPDX-License-Identifier: AGPL-3.0-or-later
-}


module Comp.BookmarkQueryForm exposing (Model, Msg, get, init, initQuery, update, view)

import Comp.Basic as B
import Comp.PowerSearchInput
import Data.BookmarkedQuery exposing (BookmarkedQueryDef, Location(..))
import Data.Flags exposing (Flags)
import Html exposing (..)
import Html.Attributes exposing (..)
import Html.Events exposing (onCheck, onInput)
import Messages.Comp.BookmarkQueryForm exposing (Texts)
import Styles as S
import Util.Maybe


type alias Model =
    { name : Maybe String
    , queryModel : Comp.PowerSearchInput.Model
    , location : Location
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
      , queryModel = res.model
      , location = User
      }
    , Cmd.batch
        [ Cmd.map QueryMsg res.cmd
        ]
    )


init : ( Model, Cmd Msg )
init =
    initQuery ""


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


update : Flags -> Msg -> Model -> ( Model, Cmd Msg, Sub Msg )
update _ msg model =
    case msg of
        SetName n ->
            ( { model | name = Util.Maybe.fromString n }, Cmd.none, Sub.none )

        SetLocation loc ->
            ( { model | location = loc }, Cmd.none, Sub.none )

        QueryMsg lm ->
            let
                res =
                    Comp.PowerSearchInput.update lm model.queryModel
            in
            ( { model | queryModel = res.model }
            , Cmd.map QueryMsg res.cmd
            , Sub.map QueryMsg res.subs
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
        [ div [ class "mb-4" ]
            [ label
                [ for "sharename"
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
                , id "sharename"
                , class S.textInput
                ]
                []
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
