{-
   Copyright 2020 Eike K. & Contributors

   SPDX-License-Identifier: AGPL-3.0-or-later
-}


module Comp.ShareForm exposing (Model, Msg, getShare, init, initQuery, setShare, update, view)

import Api.Model.ShareData exposing (ShareData)
import Api.Model.ShareDetail exposing (ShareDetail)
import Comp.Basic as B
import Comp.DatePicker
import Comp.PasswordInput
import Comp.PowerSearchInput
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
    , queryModel : Comp.PowerSearchInput.Model
    , enabled : Bool
    , passwordModel : Comp.PasswordInput.Model
    , password : Maybe String
    , passwordSet : Bool
    , clearPassword : Bool
    , untilModel : DatePicker
    , untilDate : Maybe Int
    }


initQuery : String -> ( Model, Cmd Msg )
initQuery q =
    let
        ( dp, dpc ) =
            Comp.DatePicker.init

        res =
            Comp.PowerSearchInput.update
                (Comp.PowerSearchInput.setSearchString q)
                Comp.PowerSearchInput.init
    in
    ( { share = Api.Model.ShareDetail.empty
      , name = Nothing
      , queryModel = res.model
      , enabled = True
      , passwordModel = Comp.PasswordInput.init
      , password = Nothing
      , passwordSet = False
      , clearPassword = False
      , untilModel = dp
      , untilDate = Nothing
      }
    , Cmd.batch
        [ Cmd.map UntilDateMsg dpc
        , Cmd.map QueryMsg res.cmd
        ]
    )


init : ( Model, Cmd Msg )
init =
    initQuery ""


isValid : Model -> Bool
isValid model =
    Comp.PowerSearchInput.isValid model.queryModel
        && model.untilDate
        /= Nothing


type Msg
    = SetName String
    | SetShare ShareDetail
    | ToggleEnabled
    | ToggleClearPassword
    | PasswordMsg Comp.PasswordInput.Msg
    | UntilDateMsg Comp.DatePicker.Msg
    | QueryMsg Comp.PowerSearchInput.Msg


setShare : ShareDetail -> Msg
setShare share =
    SetShare share


getShare : Model -> Maybe ( String, ShareData )
getShare model =
    if isValid model then
        Just
            ( model.share.id
            , { name = model.name
              , query =
                    Comp.PowerSearchInput.getSearchString model.queryModel
                        |> Maybe.withDefault ""
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


update : Flags -> Msg -> Model -> ( Model, Cmd Msg, Sub Msg )
update _ msg model =
    case msg of
        SetShare s ->
            let
                res =
                    Comp.PowerSearchInput.update
                        (Comp.PowerSearchInput.setSearchString s.query)
                        model.queryModel
            in
            ( { model
                | share = s
                , name = s.name
                , queryModel = res.model
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
            , Cmd.map QueryMsg res.cmd
            , Sub.map QueryMsg res.subs
            )

        SetName n ->
            ( { model | name = Util.Maybe.fromString n }, Cmd.none, Sub.none )

        ToggleEnabled ->
            ( { model | enabled = not model.enabled }, Cmd.none, Sub.none )

        ToggleClearPassword ->
            ( { model | clearPassword = not model.clearPassword }, Cmd.none, Sub.none )

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
            , Sub.none
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
            , Sub.none
            )

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
            , queryInput
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
        , div
            [ class "mb-2 max-w-sm"
            ]
            [ label [ class S.inputLabel ]
                [ text texts.publishUntil
                , B.inputRequired
                ]
            , div
                [ class "relative"
                ]
                [ Html.map UntilDateMsg
                    (Comp.DatePicker.viewTimeDefault
                        model.untilDate
                        model.untilModel
                    )
                , i [ class S.dateInputIcon, class "fa fa-calendar" ] []
                ]
            , div
                [ classList
                    [ ( "hidden"
                      , model.untilDate /= Nothing
                      )
                    ]
                , class "mt-1"
                , class S.errorText
                ]
                [ text "This field is required." ]
            ]
        ]
