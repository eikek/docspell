{-
   Copyright 2020 Eike K. & Contributors

   SPDX-License-Identifier: AGPL-3.0-or-later
-}


module Comp.NotificationChannelManage exposing
    ( Model
    , Msg
    , init
    , update
    , view
    )

import Api
import Api.Model.BasicResult exposing (BasicResult)
import Comp.Basic as B
import Comp.ChannelForm
import Comp.ChannelMenu
import Comp.MenuBar as MB
import Comp.NotificationChannelTable
import Data.ChannelType exposing (ChannelType)
import Data.Flags exposing (Flags)
import Data.NotificationChannel exposing (NotificationChannel)
import Data.UiSettings exposing (UiSettings)
import Html exposing (..)
import Html.Attributes exposing (..)
import Html.Events exposing (onClick)
import Http
import Messages.Comp.NotificationChannelManage exposing (Texts)
import Styles as S


type alias Model =
    { listModel : Comp.NotificationChannelTable.Model
    , detailModel : Maybe Comp.ChannelForm.Model
    , items : List NotificationChannel
    , deleteConfirm : DeleteConfirm
    , loading : Bool
    , formState : FormState
    , newChannelMenuOpen : Bool
    , jsonFilterError : Maybe String
    }


type DeleteConfirm
    = DeleteConfirmOff
    | DeleteConfirmOn


type SubmitType
    = SubmitDelete
    | SubmitUpdate
    | SubmitCreate


type FormState
    = FormStateInitial
    | FormErrorHttp Http.Error
    | FormSubmitSuccessful SubmitType
    | FormErrorSubmit String
    | FormErrorInvalid


type Msg
    = TableMsg Comp.NotificationChannelTable.Msg
    | DetailMsg Comp.ChannelForm.Msg
    | GetDataResp (Result Http.Error (List NotificationChannel))
    | ToggleNewChannelMenu
    | SubmitResp SubmitType (Result Http.Error BasicResult)
    | NewChannelInit ChannelType
    | BackToTable
    | Submit
    | RequestDelete
    | CancelDelete
    | DeleteChannelNow String


initModel : Model
initModel =
    { listModel = Comp.NotificationChannelTable.init
    , detailModel = Nothing
    , items = []
    , loading = False
    , formState = FormStateInitial
    , newChannelMenuOpen = False
    , deleteConfirm = DeleteConfirmOff
    , jsonFilterError = Nothing
    }


initCmd : Flags -> Cmd Msg
initCmd flags =
    Api.getChannels flags GetDataResp


init : Flags -> ( Model, Cmd Msg )
init flags =
    ( initModel, initCmd flags )



--- Update


update : Flags -> Msg -> Model -> ( Model, Cmd Msg )
update flags msg model =
    case msg of
        GetDataResp (Ok res) ->
            ( { model
                | items = res
                , formState = FormStateInitial
              }
            , Cmd.none
            )

        GetDataResp (Err err) ->
            ( { model | formState = FormErrorHttp err }
            , Cmd.none
            )

        TableMsg lm ->
            let
                ( mm, action ) =
                    Comp.NotificationChannelTable.update flags lm model.listModel

                ( detail, cmd ) =
                    case action of
                        Comp.NotificationChannelTable.NoAction ->
                            ( Nothing, Cmd.none )

                        Comp.NotificationChannelTable.EditAction channel ->
                            let
                                ( dm, dc ) =
                                    Comp.ChannelForm.initWith flags channel
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
                        ( mm, mc ) =
                            Comp.ChannelForm.update flags lm dm
                    in
                    ( { model | detailModel = Just mm }
                    , Cmd.map DetailMsg mc
                    )

                Nothing ->
                    ( model, Cmd.none )

        ToggleNewChannelMenu ->
            ( { model | newChannelMenuOpen = not model.newChannelMenuOpen }, Cmd.none )

        SubmitResp submitType (Ok res) ->
            ( { model
                | formState =
                    if res.success then
                        FormSubmitSuccessful submitType

                    else
                        FormErrorSubmit res.message
                , detailModel =
                    if submitType == SubmitDelete then
                        Nothing

                    else
                        model.detailModel
                , loading = False
              }
            , if submitType == SubmitDelete then
                initCmd flags

              else
                Cmd.none
            )

        SubmitResp _ (Err err) ->
            ( { model | formState = FormErrorHttp err, loading = False }
            , Cmd.none
            )

        NewChannelInit ct ->
            let
                ( mm, mc ) =
                    Comp.ChannelForm.init flags ct
            in
            ( { model | detailModel = Just mm, newChannelMenuOpen = False }, Cmd.map DetailMsg mc )

        BackToTable ->
            ( { model | detailModel = Nothing }, initCmd flags )

        Submit ->
            case model.detailModel of
                Just dm ->
                    case Comp.ChannelForm.getChannel dm of
                        Just data ->
                            postChannel flags data model

                        Nothing ->
                            ( { model | formState = FormErrorInvalid }, Cmd.none )

                Nothing ->
                    ( model, Cmd.none )

        RequestDelete ->
            ( { model | deleteConfirm = DeleteConfirmOn }, Cmd.none )

        CancelDelete ->
            ( { model | deleteConfirm = DeleteConfirmOff }, Cmd.none )

        DeleteChannelNow id ->
            ( { model | deleteConfirm = DeleteConfirmOff, loading = True }
            , Api.deleteChannel flags id (SubmitResp SubmitDelete)
            )


postChannel : Flags -> NotificationChannel -> Model -> ( Model, Cmd Msg )
postChannel flags channel model =
    if (Data.NotificationChannel.getRef channel |> .id) == "" then
        ( { model | loading = True }, Api.createChannel flags channel (SubmitResp SubmitCreate) )

    else
        ( { model | loading = True }, Api.updateChannel flags channel (SubmitResp SubmitUpdate) )



--- View2


view : Texts -> UiSettings -> Model -> Html Msg
view texts settings model =
    div [ class "flex flex-col" ]
        (case model.detailModel of
            Just msett ->
                viewForm texts settings model msett

            Nothing ->
                viewList texts model
        )


viewState : Texts -> Model -> Html Msg
viewState texts model =
    div
        [ classList
            [ ( S.errorMessage, not (isSuccess model.formState) )
            , ( S.successMessage, isSuccess model.formState )
            , ( "hidden", model.formState == FormStateInitial )
            ]
        , class "mb-2"
        ]
        [ case model.formState of
            FormStateInitial ->
                text ""

            FormSubmitSuccessful SubmitCreate ->
                text texts.channelCreated

            FormSubmitSuccessful SubmitUpdate ->
                text texts.channelUpdated

            FormSubmitSuccessful SubmitDelete ->
                text texts.channelDeleted

            FormErrorSubmit m ->
                text m

            FormErrorHttp err ->
                text (texts.httpError err)

            FormErrorInvalid ->
                text texts.formInvalid
        ]


isSuccess : FormState -> Bool
isSuccess state =
    case state of
        FormSubmitSuccessful _ ->
            True

        _ ->
            False


viewForm : Texts -> UiSettings -> Model -> Comp.ChannelForm.Model -> List (Html Msg)
viewForm texts settings outerModel model =
    let
        channelId =
            Comp.ChannelForm.getChannel model
                |> Maybe.map Data.NotificationChannel.getRef
                |> Maybe.map .id

        newChannel =
            channelId |> (==) (Just "")

        headline =
            case Comp.ChannelForm.channelType model of
                Data.ChannelType.Matrix ->
                    span []
                        [ text texts.integrate
                        , a
                            [ href "https://matrix.org"
                            , target "_blank"
                            , class S.link
                            , class "mx-3"
                            ]
                            [ i [ class "fa fa-external-link-alt mr-1" ] []
                            , text "Matrix"
                            ]
                        , text texts.intoDocspell
                        ]

                Data.ChannelType.Mail ->
                    span []
                        [ text texts.notifyEmailInfo
                        ]

                Data.ChannelType.Gotify ->
                    span []
                        [ text texts.integrate
                        , a
                            [ href "https://gotify.net"
                            , target "_blank"
                            , class S.link
                            , class "mx-3"
                            ]
                            [ i [ class "fa fa-external-link-alt mr-1" ] []
                            , text "Gotify"
                            ]
                        , text texts.intoDocspell
                        ]

                Data.ChannelType.Http ->
                    span []
                        [ text texts.postRequestInfo
                        ]
    in
    [ h1 [ class S.header2 ]
        [ Data.ChannelType.icon (Comp.ChannelForm.channelType model) "w-8 h-8 inline-block mr-2"
        , if newChannel then
            text texts.addChannel

          else
            text texts.updateChannel
        , div [ class "text-xs opacity-50 font-mono" ]
            [ Maybe.withDefault "" channelId |> text
            ]
        ]
    , div [ class "pt-2 pb-4 font-medium" ]
        [ headline
        ]
    , MB.view
        { start =
            [ MB.CustomElement <|
                B.primaryButton
                    { handler = onClick Submit
                    , title = texts.basics.submitThisForm
                    , icon = "fa fa-save"
                    , label = texts.basics.submit
                    , disabled = False
                    , attrs = [ href "#" ]
                    }
            , MB.SecondaryButton
                { tagger = BackToTable
                , title = texts.basics.backToList
                , icon = Just "fa fa-arrow-left"
                , label = texts.basics.backToList
                }
            ]
        , end =
            if not newChannel then
                [ MB.DeleteButton
                    { tagger = RequestDelete
                    , title = texts.deleteThisChannel
                    , icon = Just "fa fa-trash"
                    , label = texts.basics.delete
                    }
                ]

            else
                []
        , rootClasses = "mb-4"
        }
    , div [ class "mt-2" ]
        [ viewState texts outerModel
        ]
    , Html.map DetailMsg
        (Comp.ChannelForm.view texts.notificationForm settings model)
    , B.loadingDimmer
        { active = outerModel.loading
        , label = texts.basics.loading
        }
    , B.contentDimmer
        (outerModel.deleteConfirm == DeleteConfirmOn)
        (div [ class "flex flex-col" ]
            [ div [ class "text-lg" ]
                [ i [ class "fa fa-info-circle mr-2" ] []
                , text texts.reallyDeleteChannel
                ]
            , div [ class "mt-4 flex flex-row items-center" ]
                [ B.deleteButton
                    { label = texts.basics.yes
                    , icon = "fa fa-check"
                    , disabled = False
                    , handler = onClick (DeleteChannelNow (Maybe.withDefault "" channelId))
                    , attrs = [ href "#" ]
                    }
                , B.secondaryButton
                    { label = texts.basics.no
                    , icon = "fa fa-times"
                    , disabled = False
                    , handler = onClick CancelDelete
                    , attrs = [ href "#", class "ml-2" ]
                    }
                ]
            ]
        )
    ]


viewList : Texts -> Model -> List (Html Msg)
viewList texts model =
    let
        menuModel =
            { menuOpen = model.newChannelMenuOpen
            , toggleMenu = ToggleNewChannelMenu
            , menuLabel = texts.newChannel
            , onItem = NewChannelInit
            }
    in
    [ MB.view
        { start = []
        , end =
            [ Comp.ChannelMenu.channelMenu texts.channelType menuModel
            ]
        , rootClasses = "mb-4"
        }
    , Html.map TableMsg
        (Comp.NotificationChannelTable.view texts.notificationTable
            model.listModel
            model.items
        )
    ]
