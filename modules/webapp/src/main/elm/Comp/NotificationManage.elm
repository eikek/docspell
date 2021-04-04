module Comp.NotificationManage exposing
    ( Model
    , Msg
    , init
    , update
    , view2
    )

import Api
import Api.Model.BasicResult exposing (BasicResult)
import Api.Model.NotificationSettings exposing (NotificationSettings)
import Api.Model.NotificationSettingsList exposing (NotificationSettingsList)
import Comp.MenuBar as MB
import Comp.NotificationForm
import Comp.NotificationList
import Data.Flags exposing (Flags)
import Data.UiSettings exposing (UiSettings)
import Html exposing (..)
import Html.Attributes exposing (..)
import Http
import Messages.NotificationManageComp exposing (Texts)
import Styles as S
import Util.Http


type alias Model =
    { listModel : Comp.NotificationList.Model
    , detailModel : Maybe Comp.NotificationForm.Model
    , items : List NotificationSettings
    , result : Maybe BasicResult
    }


type Msg
    = ListMsg Comp.NotificationList.Msg
    | DetailMsg Comp.NotificationForm.Msg
    | GetDataResp (Result Http.Error NotificationSettingsList)
    | NewTask
    | SubmitResp Bool (Result Http.Error BasicResult)
    | DeleteResp (Result Http.Error BasicResult)


initModel : Model
initModel =
    { listModel = Comp.NotificationList.init
    , detailModel = Nothing
    , items = []
    , result = Nothing
    }


initCmd : Flags -> Cmd Msg
initCmd flags =
    Api.getNotifyDueItems flags GetDataResp


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
                    Comp.NotificationList.update lm model.listModel

                ( detail, cmd ) =
                    case action of
                        Comp.NotificationList.NoAction ->
                            ( Nothing, Cmd.none )

                        Comp.NotificationList.EditAction settings ->
                            let
                                ( dm, dc ) =
                                    Comp.NotificationForm.initWith flags settings
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
                            Comp.NotificationForm.update flags lm dm

                        ( model_, cmd_ ) =
                            case action of
                                Comp.NotificationForm.NoAction ->
                                    ( { model | detailModel = Just mm }
                                    , Cmd.none
                                    )

                                Comp.NotificationForm.SubmitAction settings ->
                                    ( { model
                                        | detailModel = Just mm
                                        , result = Nothing
                                      }
                                    , if settings.id == "" then
                                        Api.createNotifyDueItems flags settings (SubmitResp True)

                                      else
                                        Api.updateNotifyDueItems flags settings (SubmitResp True)
                                    )

                                Comp.NotificationForm.CancelAction ->
                                    ( { model
                                        | detailModel = Nothing
                                        , result = Nothing
                                      }
                                    , initCmd flags
                                    )

                                Comp.NotificationForm.StartOnceAction settings ->
                                    ( { model
                                        | detailModel = Just mm
                                        , result = Nothing
                                      }
                                    , Api.startOnceNotifyDueItems flags settings (SubmitResp False)
                                    )

                                Comp.NotificationForm.DeleteAction id ->
                                    ( { model
                                        | detailModel = Just mm
                                        , result = Nothing
                                      }
                                    , Api.deleteNotifyDueItems flags id DeleteResp
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
                    Comp.NotificationForm.init flags
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



--- View2


view2 : Texts -> UiSettings -> Model -> Html Msg
view2 texts settings model =
    div [ class "flex flex-col" ]
        (div
            [ classList
                [ ( S.errorMessage, Maybe.map .success model.result == Just False )
                , ( S.successMessage, Maybe.map .success model.result == Just True )
                , ( "hidden", model.result == Nothing )
                ]
            , class "mb-2"
            ]
            [ Maybe.map .message model.result
                |> Maybe.withDefault ""
                |> text
            ]
            :: (case model.detailModel of
                    Just msett ->
                        viewForm2 texts settings msett

                    Nothing ->
                        viewList2 texts model
               )
        )


viewForm2 : Texts -> UiSettings -> Comp.NotificationForm.Model -> List (Html Msg)
viewForm2 texts settings model =
    [ Html.map DetailMsg
        (Comp.NotificationForm.view2 texts.notificationForm "flex flex-col" settings model)
    ]


viewList2 : Texts -> Model -> List (Html Msg)
viewList2 texts model =
    [ MB.view
        { start =
            [ MB.PrimaryButton
                { tagger = NewTask
                , label = texts.newTask
                , icon = Just "fa fa-plus"
                , title = texts.createNewTask
                }
            ]
        , end = []
        , rootClasses = "mb-4"
        }
    , Html.map ListMsg
        (Comp.NotificationList.view2 texts.notificationTable
            model.listModel
            model.items
        )
    ]
