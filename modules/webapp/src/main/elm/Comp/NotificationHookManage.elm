{-
   Copyright 2020 Eike K. & Contributors

   SPDX-License-Identifier: AGPL-3.0-or-later
-}


module Comp.NotificationHookManage exposing
    ( Model
    , Msg
    , init
    , update
    , view
    )

import Api
import Api.Model.BasicResult exposing (BasicResult)
import Comp.Basic as B
import Comp.ChannelMenu
import Comp.MenuBar as MB
import Comp.NotificationHookForm
import Comp.NotificationHookTable
import Data.ChannelType exposing (ChannelType)
import Data.Flags exposing (Flags)
import Data.NotificationHook exposing (NotificationHook)
import Data.UiSettings exposing (UiSettings)
import Html exposing (..)
import Html.Attributes exposing (..)
import Html.Events exposing (onClick)
import Http
import Messages.Comp.NotificationHookManage exposing (Texts)
import Styles as S


type alias Model =
    { listModel : Comp.NotificationHookTable.Model
    , detailModel : Maybe Comp.NotificationHookForm.Model
    , items : List NotificationHook
    , deleteConfirm : DeleteConfirm
    , loading : Bool
    , formState : FormState
    , newHookMenuOpen : Bool
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
    = TableMsg Comp.NotificationHookTable.Msg
    | DetailMsg Comp.NotificationHookForm.Msg
    | GetDataResp (Result Http.Error (List NotificationHook))
    | ToggleNewHookMenu
    | SubmitResp SubmitType (Result Http.Error BasicResult)
    | NewHookInit ChannelType
    | BackToTable
    | Submit
    | RequestDelete
    | CancelDelete
    | DeleteHookNow String
    | VerifyFilterResp NotificationHook (Result Http.Error BasicResult)


initModel : Model
initModel =
    { listModel = Comp.NotificationHookTable.init
    , detailModel = Nothing
    , items = []
    , loading = False
    , formState = FormStateInitial
    , newHookMenuOpen = False
    , deleteConfirm = DeleteConfirmOff
    , jsonFilterError = Nothing
    }


initCmd : Flags -> Cmd Msg
initCmd flags =
    Api.getHooks flags GetDataResp


init : Flags -> ( Model, Cmd Msg )
init flags =
    ( initModel, initCmd flags )



--- Update


update : Flags -> Msg -> Model -> ( Model, Cmd Msg )
update flags msg model =
    case msg of
        VerifyFilterResp hook (Ok res) ->
            if res.success then
                postHook flags hook model

            else
                ( { model
                    | loading = False
                    , formState = FormErrorInvalid
                    , jsonFilterError = Just res.message
                  }
                , Cmd.none
                )

        VerifyFilterResp _ (Err err) ->
            ( { model | formState = FormErrorHttp err }
            , Cmd.none
            )

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
                    Comp.NotificationHookTable.update flags lm model.listModel

                ( detail, cmd ) =
                    case action of
                        Comp.NotificationHookTable.NoAction ->
                            ( Nothing, Cmd.none )

                        Comp.NotificationHookTable.EditAction hook ->
                            let
                                ( dm, dc ) =
                                    Comp.NotificationHookForm.initWith flags hook
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
                            Comp.NotificationHookForm.update flags lm dm
                    in
                    ( { model | detailModel = Just mm }
                    , Cmd.map DetailMsg mc
                    )

                Nothing ->
                    ( model, Cmd.none )

        ToggleNewHookMenu ->
            ( { model | newHookMenuOpen = not model.newHookMenuOpen }, Cmd.none )

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

        NewHookInit ct ->
            let
                ( mm, mc ) =
                    Comp.NotificationHookForm.init flags ct
            in
            ( { model | detailModel = Just mm, newHookMenuOpen = False }, Cmd.map DetailMsg mc )

        BackToTable ->
            ( { model | detailModel = Nothing }, initCmd flags )

        Submit ->
            case model.detailModel of
                Just dm ->
                    case Comp.NotificationHookForm.getHook dm of
                        Just data ->
                            case data.eventFilter of
                                Nothing ->
                                    postHook flags data model

                                Just jf ->
                                    ( { model | loading = True }, Api.verifyJsonFilter flags jf (VerifyFilterResp data) )

                        Nothing ->
                            ( { model | formState = FormErrorInvalid }, Cmd.none )

                Nothing ->
                    ( model, Cmd.none )

        RequestDelete ->
            ( { model | deleteConfirm = DeleteConfirmOn }, Cmd.none )

        CancelDelete ->
            ( { model | deleteConfirm = DeleteConfirmOff }, Cmd.none )

        DeleteHookNow id ->
            ( { model | deleteConfirm = DeleteConfirmOff, loading = True }
            , Api.deleteHook flags id (SubmitResp SubmitDelete)
            )


postHook : Flags -> NotificationHook -> Model -> ( Model, Cmd Msg )
postHook flags hook model =
    if hook.id == "" then
        ( { model | loading = True }, Api.createHook flags hook (SubmitResp SubmitCreate) )

    else
        ( { model | loading = True }, Api.updateHook flags hook (SubmitResp SubmitUpdate) )



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
            [ ( S.errorMessage, model.formState /= FormStateInitial )
            , ( S.successMessage, isSuccess model.formState )
            , ( "hidden", model.formState == FormStateInitial )
            ]
        , class "mb-2"
        ]
        [ case model.formState of
            FormStateInitial ->
                text ""

            FormSubmitSuccessful SubmitCreate ->
                text texts.hookCreated

            FormSubmitSuccessful SubmitUpdate ->
                text texts.hookUpdated

            FormSubmitSuccessful SubmitDelete ->
                text texts.hookDeleted

            FormErrorSubmit m ->
                text m

            FormErrorHttp err ->
                text (texts.httpError err)

            FormErrorInvalid ->
                case model.jsonFilterError of
                    Just m ->
                        text (texts.invalidJsonFilter m)

                    Nothing ->
                        text texts.formInvalid
        ]


isSuccess : FormState -> Bool
isSuccess state =
    case state of
        FormSubmitSuccessful _ ->
            True

        _ ->
            False


viewForm : Texts -> UiSettings -> Model -> Comp.NotificationHookForm.Model -> List (Html Msg)
viewForm texts settings outerModel model =
    let
        newHook =
            model.hook.id == ""

        headline =
            case Comp.NotificationHookForm.channelType model of
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
        [ Data.ChannelType.icon (Comp.NotificationHookForm.channelType model) "w-8 h-8 inline-block mr-4"
        , if newHook then
            text texts.addWebhook

          else
            text texts.updateWebhook
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
            if not newHook then
                [ MB.DeleteButton
                    { tagger = RequestDelete
                    , title = texts.deleteThisHook
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
        (Comp.NotificationHookForm.view texts.notificationForm settings model)
    , B.loadingDimmer
        { active = outerModel.loading
        , label = texts.basics.loading
        }
    , B.contentDimmer
        (outerModel.deleteConfirm == DeleteConfirmOn)
        (div [ class "flex flex-col" ]
            [ div [ class "text-lg" ]
                [ i [ class "fa fa-info-circle mr-2" ] []
                , text texts.reallyDeleteHook
                ]
            , div [ class "mt-4 flex flex-row items-center" ]
                [ B.deleteButton
                    { label = texts.basics.yes
                    , icon = "fa fa-check"
                    , disabled = False
                    , handler = onClick (DeleteHookNow model.hook.id)
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
            { menuOpen = model.newHookMenuOpen
            , toggleMenu = ToggleNewHookMenu
            , menuLabel = texts.newHook
            , onItem = NewHookInit
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
        (Comp.NotificationHookTable.view texts.notificationTable
            model.listModel
            model.items
        )
    ]
