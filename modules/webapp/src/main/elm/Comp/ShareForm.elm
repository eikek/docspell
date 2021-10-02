{-
   Copyright 2020 Eike K. & Contributors

   SPDX-License-Identifier: AGPL-3.0-or-later
-}


module Comp.ShareForm exposing (Model, Msg, getShare, init, setShare, update, view)

import Api.Model.ShareData exposing (ShareData)
import Api.Model.ShareDetail exposing (ShareDetail)
import Comp.Basic as B
import Comp.DatePicker
import Comp.PasswordInput
import Data.Flags exposing (Flags)
import DatePicker exposing (DatePicker)
import Html exposing (..)
import Html.Attributes exposing (..)
import Html.Events exposing (onCheck, onInput)
import Messages.Comp.ShareForm exposing (Texts)
import Styles as S
import Util.Maybe


type alias Model =
    { share : ShareDetail
    , name : Maybe String
    , query : String
    , enabled : Bool
    , passwordModel : Comp.PasswordInput.Model
    , password : Maybe String
    , passwordSet : Bool
    , clearPassword : Bool
    , untilModel : DatePicker
    , untilDate : Maybe Int
    }


init : ( Model, Cmd Msg )
init =
    let
        ( dp, dpc ) =
            Comp.DatePicker.init
    in
    ( { share = Api.Model.ShareDetail.empty
      , name = Nothing
      , query = ""
      , enabled = False
      , passwordModel = Comp.PasswordInput.init
      , password = Nothing
      , passwordSet = False
      , clearPassword = False
      , untilModel = dp
      , untilDate = Nothing
      }
    , Cmd.map UntilDateMsg dpc
    )


isValid : Model -> Bool
isValid model =
    model.query /= "" && model.untilDate /= Nothing


type Msg
    = SetName String
    | SetQuery String
    | SetShare ShareDetail
    | ToggleEnabled
    | ToggleClearPassword
    | PasswordMsg Comp.PasswordInput.Msg
    | UntilDateMsg Comp.DatePicker.Msg


setShare : ShareDetail -> Msg
setShare share =
    SetShare share


getShare : Model -> Maybe ( String, ShareData )
getShare model =
    if isValid model then
        Just
            ( model.share.id
            , { name = model.name
              , query = model.query
              , enabled = model.enabled
              , password = model.password
              , removePassword =
                    if model.share.id == "" then
                        Nothing

                    else
                        Just model.clearPassword
              , publishUntil = Maybe.withDefault 0 model.untilDate
              }
            )

    else
        Nothing


update : Flags -> Msg -> Model -> ( Model, Cmd Msg )
update _ msg model =
    case msg of
        SetShare s ->
            ( { model
                | share = s
                , name = s.name
                , query = s.query
                , enabled = s.enabled
                , password = Nothing
                , passwordSet = s.password
                , clearPassword = False
                , untilDate =
                    if s.publishUntil > 0 then
                        Just s.publishUntil

                    else
                        Nothing
              }
            , Cmd.none
            )

        SetName n ->
            ( { model | name = Util.Maybe.fromString n }, Cmd.none )

        SetQuery n ->
            ( { model | query = n }, Cmd.none )

        ToggleEnabled ->
            ( { model | enabled = not model.enabled }, Cmd.none )

        ToggleClearPassword ->
            ( { model | clearPassword = not model.clearPassword }, Cmd.none )

        PasswordMsg lm ->
            let
                ( pm, pw ) =
                    Comp.PasswordInput.update lm model.passwordModel
            in
            ( { model
                | passwordModel = pm
                , password = pw
              }
            , Cmd.none
            )

        UntilDateMsg lm ->
            let
                ( dp, event ) =
                    Comp.DatePicker.updateDefault lm model.untilModel

                nextDate =
                    case event of
                        DatePicker.Picked date ->
                            Just (Comp.DatePicker.endOfDay date)

                        _ ->
                            Nothing
            in
            ( { model | untilModel = dp, untilDate = nextDate }
            , Cmd.none
            )



--- View


view : Texts -> Model -> Html Msg
view texts model =
    div
        [ class "flex flex-col" ]
        [ div [ class "mb-4" ]
            [ label
                [ for "sharename"
                , class S.inputLabel
                ]
                [ text texts.basics.name
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
        , div [ class "mb-4" ]
            [ label
                [ for "sharequery"
                , class S.inputLabel
                ]
                [ text texts.queryLabel
                , B.inputRequired
                ]
            , input
                [ type_ "text"
                , onInput SetQuery
                , placeholder texts.queryLabel
                , value model.query
                , id "sharequery"
                , class S.textInput
                , classList
                    [ ( S.inputErrorBorder
                      , not (isValid model)
                      )
                    ]
                ]
                []
            ]
        , div [ class "mb-4" ]
            [ label
                [ class "inline-flex items-center"
                , for "source-enabled"
                ]
                [ input
                    [ type_ "checkbox"
                    , onCheck (\_ -> ToggleEnabled)
                    , checked model.enabled
                    , class S.checkboxInput
                    , id "source-enabled"
                    ]
                    []
                , span [ class "ml-2" ]
                    [ text texts.enabled
                    ]
                ]
            ]
        , div [ class "mb-4" ]
            [ label
                [ class S.inputLabel
                ]
                [ text texts.password
                ]
            , Html.map PasswordMsg
                (Comp.PasswordInput.view2
                    { placeholder = texts.password }
                    model.password
                    False
                    model.passwordModel
                )
            , div
                [ class "mb-2"
                , classList [ ( "hidden", not model.passwordSet ) ]
                ]
                [ label
                    [ class "inline-flex items-center"
                    , for "clear-password"
                    ]
                    [ input
                        [ type_ "checkbox"
                        , onCheck (\_ -> ToggleClearPassword)
                        , checked model.clearPassword
                        , class S.checkboxInput
                        , id "clear-password"
                        ]
                        []
                    , span [ class "ml-2" ]
                        [ text texts.clearPassword
                        ]
                    ]
                ]
            ]
        , div [ class "mb-2 max-w-sm" ]
            [ label [ class S.inputLabel ]
                [ text texts.publishUntil
                , B.inputRequired
                ]
            , div [ class "relative" ]
                [ Html.map UntilDateMsg
                    (Comp.DatePicker.viewTimeDefault
                        model.untilDate
                        model.untilModel
                    )
                , i [ class S.dateInputIcon, class "fa fa-calendar" ] []
                ]
            ]
        ]
