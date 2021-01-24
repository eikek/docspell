module Comp.ScanMailboxManage exposing
    ( Model
    , Msg
    , init
    , update
    , view
    )

import Api
import Api.Model.BasicResult exposing (BasicResult)
import Api.Model.ScanMailboxSettings exposing (ScanMailboxSettings)
import Api.Model.ScanMailboxSettingsList exposing (ScanMailboxSettingsList)
import Comp.ScanMailboxForm
import Comp.ScanMailboxList
import Data.Flags exposing (Flags)
import Data.UiSettings exposing (UiSettings)
import Html exposing (..)
import Html.Attributes exposing (..)
import Html.Events exposing (onClick)
import Http
import Util.Http


type alias Model =
    { listModel : Comp.ScanMailboxList.Model
    , detailModel : Maybe Comp.ScanMailboxForm.Model
    , items : List ScanMailboxSettings
    , result : Maybe BasicResult
    }


type Msg
    = ListMsg Comp.ScanMailboxList.Msg
    | DetailMsg Comp.ScanMailboxForm.Msg
    | GetDataResp (Result Http.Error ScanMailboxSettingsList)
    | NewTask
    | SubmitResp Bool (Result Http.Error BasicResult)
    | DeleteResp (Result Http.Error BasicResult)


initModel : Model
initModel =
    { listModel = Comp.ScanMailboxList.init
    , detailModel = Nothing
    , items = []
    , result = Nothing
    }


initCmd : Flags -> Cmd Msg
initCmd flags =
    Api.getScanMailbox flags GetDataResp


init : Flags -> ( Model, Cmd Msg )
init flags =
    ( initModel, initCmd flags )



--- Update


update : Flags -> Msg -> Model -> ( Model, Cmd Msg )
update flags msg model =
    case msg of
        GetDataResp (Ok res) ->
            ( { model
                | items = res.items
                , result = Nothing
              }
            , Cmd.none
            )

        GetDataResp (Err err) ->
            ( { model | result = Just (BasicResult False (Util.Http.errorToString err)) }
            , Cmd.none
            )

        ListMsg lm ->
            let
                ( mm, action ) =
                    Comp.ScanMailboxList.update lm model.listModel

                ( detail, cmd ) =
                    case action of
                        Comp.ScanMailboxList.NoAction ->
                            ( Nothing, Cmd.none )

                        Comp.ScanMailboxList.EditAction settings ->
                            let
                                ( dm, dc ) =
                                    Comp.ScanMailboxForm.initWith flags settings
                            in
                            ( Just dm, Cmd.map DetailMsg dc )
            in
            ( { model
                | listModel = mm
                , detailModel = detail
              }
            , cmd
            )

        DetailMsg lm ->
            case model.detailModel of
                Just dm ->
                    let
                        ( mm, action, mc ) =
                            Comp.ScanMailboxForm.update flags lm dm

                        ( model_, cmd_ ) =
                            case action of
                                Comp.ScanMailboxForm.NoAction ->
                                    ( { model | detailModel = Just mm }
                                    , Cmd.none
                                    )

                                Comp.ScanMailboxForm.SubmitAction settings ->
                                    ( { model
                                        | detailModel = Just mm
                                        , result = Nothing
                                      }
                                    , if settings.id == "" then
                                        Api.createScanMailbox flags settings (SubmitResp True)

                                      else
                                        Api.updateScanMailbox flags settings (SubmitResp True)
                                    )

                                Comp.ScanMailboxForm.CancelAction ->
                                    ( { model
                                        | detailModel = Nothing
                                        , result = Nothing
                                      }
                                    , initCmd flags
                                    )

                                Comp.ScanMailboxForm.StartOnceAction settings ->
                                    ( { model
                                        | detailModel = Just mm
                                        , result = Nothing
                                      }
                                    , Api.startOnceScanMailbox flags settings (SubmitResp False)
                                    )

                                Comp.ScanMailboxForm.DeleteAction id ->
                                    ( { model
                                        | detailModel = Just mm
                                        , result = Nothing
                                      }
                                    , Api.deleteScanMailbox flags id DeleteResp
                                    )
                    in
                    ( model_
                    , Cmd.batch
                        [ Cmd.map DetailMsg mc
                        , cmd_
                        ]
                    )

                Nothing ->
                    ( model, Cmd.none )

        NewTask ->
            let
                ( mm, mc ) =
                    Comp.ScanMailboxForm.init flags
            in
            ( { model | detailModel = Just mm }, Cmd.map DetailMsg mc )

        SubmitResp close (Ok res) ->
            ( { model
                | result = Just res
                , detailModel =
                    if close then
                        Nothing

                    else
                        model.detailModel
              }
            , if close then
                initCmd flags

              else
                Cmd.none
            )

        SubmitResp _ (Err err) ->
            ( { model | result = Just (BasicResult False (Util.Http.errorToString err)) }
            , Cmd.none
            )

        DeleteResp (Ok res) ->
            if res.success then
                ( { model | result = Nothing, detailModel = Nothing }
                , initCmd flags
                )

            else
                ( { model | result = Just res }
                , Cmd.none
                )

        DeleteResp (Err err) ->
            ( { model | result = Just (BasicResult False (Util.Http.errorToString err)) }
            , Cmd.none
            )



--- View


view : UiSettings -> Model -> Html Msg
view settings model =
    div []
        [ div [ class "ui menu" ]
            [ a
                [ class "link item"
                , href "#"
                , onClick NewTask
                ]
                [ i [ class "add icon" ] []
                , text "New Task"
                ]
            ]
        , div
            [ classList
                [ ( "ui message", True )
                , ( "error", Maybe.map .success model.result == Just False )
                , ( "success", Maybe.map .success model.result == Just True )
                , ( "invisible hidden", model.result == Nothing )
                ]
            ]
            [ Maybe.map .message model.result
                |> Maybe.withDefault ""
                |> text
            ]
        , case model.detailModel of
            Just msett ->
                viewForm settings msett

            Nothing ->
                viewList model
        ]


viewForm : UiSettings -> Comp.ScanMailboxForm.Model -> Html Msg
viewForm settings model =
    Html.map DetailMsg (Comp.ScanMailboxForm.view "" settings model)


viewList : Model -> Html Msg
viewList model =
    Html.map ListMsg (Comp.ScanMailboxList.view model.listModel model.items)
