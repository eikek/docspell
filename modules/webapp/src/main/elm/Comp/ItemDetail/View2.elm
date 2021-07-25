{-
   Copyright 2020 Docspell Contributors

   SPDX-License-Identifier: GPL-3.0-or-later
-}


module Comp.ItemDetail.View2 exposing (view)

import Comp.Basic as B
import Comp.DetailEdit
import Comp.ItemDetail.AddFilesForm
import Comp.ItemDetail.ConfirmModalView
import Comp.ItemDetail.ItemInfoHeader
import Comp.ItemDetail.Model
    exposing
        ( MailSendResult(..)
        , Model
        , Msg(..)
        , NotesField(..)
        , SaveNameState(..)
        )
import Comp.ItemDetail.Notes
import Comp.ItemDetail.SingleAttachment
import Comp.ItemMail
import Comp.MenuBar as MB
import Comp.SentMails
import Data.Icons as Icons
import Data.ItemNav exposing (ItemNav)
import Data.UiSettings exposing (UiSettings)
import Html exposing (..)
import Html.Attributes exposing (..)
import Html.Events exposing (onClick)
import Messages.Comp.ItemDetail exposing (Texts)
import Page exposing (Page(..))
import Styles as S


view : Texts -> ItemNav -> UiSettings -> Model -> Html Msg
view texts inav settings model =
    div [ class "flex flex-col h-full" ]
        [ header texts settings model
        , menuBar texts inav settings model
        , body texts inav settings model
        , itemModal texts model
        ]


itemModal : Texts -> Model -> Html Msg
itemModal texts model =
    case model.itemModal of
        Just confirm ->
            Comp.ItemDetail.ConfirmModalView.view texts.confirmModal confirm model

        Nothing ->
            span [ class "hidden" ] []


header : Texts -> UiSettings -> Model -> Html Msg
header texts settings model =
    div [ class "my-3" ]
        [ Comp.ItemDetail.ItemInfoHeader.view texts.itemInfoHeader settings model ]


menuBar : Texts -> ItemNav -> UiSettings -> Model -> Html Msg
menuBar texts inav settings model =
    let
        keyDescr name =
            if settings.itemDetailShortcuts && model.menuOpen then
                " " ++ texts.key ++ "'" ++ name ++ "'."

            else
                ""
    in
    MB.view
        { start =
            [ MB.CustomElement <|
                a
                    [ class S.secondaryBasicButton
                    , Page.href HomePage
                    , title texts.backToSearchResults
                    ]
                    [ i [ class "fa fa-arrow-left" ] []
                    ]
            , MB.CustomElement <|
                div [ class "inline-flex" ]
                    [ B.genericButton
                        { label = ""
                        , icon = "fa fa-caret-left"
                        , baseStyle = S.secondaryBasicButtonMain ++ " px-4 py-2 border rounded-l"
                        , activeStyle = S.secondaryBasicButtonHover
                        , handler =
                            Maybe.map ItemDetailPage inav.prev
                                |> Maybe.map Page.href
                                |> Maybe.withDefault (href "#")
                        , disabled = inav.prev == Nothing
                        , attrs =
                            [ title (texts.previousItem ++ keyDescr "Ctrl-,")
                            ]
                        }
                    , div
                        [ classList [ ( "hidden", inav.index == Nothing ) ]
                        , class S.secondaryBasicButtonMain
                        , class " px-4 py-2 border-t border-b border-r opacity-75"
                        ]
                        [ Maybe.map ((+) 1) inav.index
                            |> Maybe.map String.fromInt
                            |> Maybe.withDefault ""
                            |> text
                        , text " / "
                        , String.fromInt inav.length
                            |> text
                        ]
                    , B.genericButton
                        { label = ""
                        , icon = "fa fa-caret-right"
                        , baseStyle =
                            S.secondaryBasicButtonMain
                                ++ " px-4 py-2 border-t border-b border-r rounded-r"
                        , activeStyle = S.secondaryBasicButtonHover
                        , handler =
                            Maybe.map ItemDetailPage inav.next
                                |> Maybe.map Page.href
                                |> Maybe.withDefault (href "#")
                        , disabled = inav.next == Nothing
                        , attrs =
                            [ title (texts.nextItem ++ keyDescr "Ctrl-.")
                            ]
                        }
                    ]
            , MB.CustomElement <|
                a
                    [ classList
                        [ ( "bg-gray-200 dark:bg-bluegray-600", model.mailOpen )
                        ]
                    , title texts.sendMail
                    , onClick ToggleMail
                    , class S.secondaryBasicButton
                    , href "#"
                    ]
                    [ i [ class "fa fa-envelope font-thin" ] []
                    ]
            , MB.CustomElement <|
                a
                    [ classList
                        [ ( "bg-gray-200 dark:bg-bluegray-600", model.addFilesOpen )
                        ]
                    , if model.addFilesOpen then
                        title "Close"

                      else
                        title texts.addMoreFiles
                    , onClick AddFilesToggle
                    , class S.secondaryBasicButton
                    , href "#"
                    ]
                    [ Icons.addFilesIcon2 ""
                    ]
            , MB.CustomElement <|
                a
                    [ class S.primaryButton
                    , href "#"
                    , onClick ConfirmItem
                    , title texts.confirmItemMetadata
                    , classList [ ( "hidden", model.item.state /= "created" ) ]
                    ]
                    [ i [ class "fa fa-check mr-2" ] []
                    , text texts.confirm
                    ]
            ]
        , end =
            [ MB.CustomElement <|
                a
                    [ class S.secondaryBasicButton
                    , href "#"
                    , onClick UnconfirmItem
                    , title texts.unconfirmItemMetadata
                    , classList [ ( "hidden", model.item.state == "created" ) ]
                    ]
                    [ i [ class "fa fa-eye-slash font-thin" ] []
                    ]
            , MB.CustomElement <|
                a
                    [ class S.secondaryBasicButton
                    , href "#"
                    , onClick RequestReprocessItem
                    , title texts.reprocessItem
                    ]
                    [ i [ class "fa fa-redo" ] []
                    ]
            , MB.CustomElement <|
                a
                    [ class S.deleteButton
                    , href "#"
                    , onClick RequestDelete
                    , title texts.deleteThisItem
                    ]
                    [ i [ class "fa fa-trash" ] []
                    ]
            ]
        , rootClasses = "mb-2"
        }


body : Texts -> ItemNav -> UiSettings -> Model -> Html Msg
body texts _ settings model =
    div [ class "grid gap-2 grid-cols-1 md:grid-cols-3 h-full" ]
        [ leftArea texts settings model
        , rightArea texts settings model
        ]


leftArea : Texts -> UiSettings -> Model -> Html Msg
leftArea texts settings model =
    div [ class "w-full md:order-first md:mr-2 flex flex-col" ]
        [ addDetailForm texts settings model
        , sendMailForm texts settings model
        , Comp.ItemDetail.AddFilesForm.view texts.addFilesForm model
        , Comp.ItemDetail.Notes.view texts.notes model
        , div
            [ classList
                [ ( "hidden", Comp.SentMails.isEmpty model.sentMails )
                ]
            , class "mt-4 "
            ]
            [ h3 [ class "flex flex-row items-center border-b dark:border-bluegray-600 font-bold text-lg" ]
                [ text texts.sentEmails
                ]
            , Html.map SentMailsMsg (Comp.SentMails.view2 texts.sentMails model.sentMails)
            ]
        , div [ class "flex-grow" ] []
        , itemIdInfo texts model
        ]


rightArea : Texts -> UiSettings -> Model -> Html Msg
rightArea texts settings model =
    div [ class "md:col-span-2 h-full" ]
        (attachmentsBody texts settings model)


attachmentsBody : Texts -> UiSettings -> Model -> List (Html Msg)
attachmentsBody texts settings model =
    List.indexedMap (Comp.ItemDetail.SingleAttachment.view texts.singleAttachment settings model)
        model.item.attachments


sendMailForm : Texts -> UiSettings -> Model -> Html Msg
sendMailForm texts settings model =
    div
        [ classList
            [ ( "hidden", not model.mailOpen )
            ]
        , class S.box
        , class "mb-4 px-2 py-2"
        ]
        [ div [ class "text-lg font-bold" ]
            [ text texts.sendThisItemViaEmail
            ]
        , B.loadingDimmer
            { active = model.mailSending
            , label = texts.sendingMailNow
            }
        , Html.map ItemMailMsg (Comp.ItemMail.view2 texts.itemMail settings model.itemMail)
        , div
            [ classList
                [ ( S.errorMessage, model.mailSendResult /= MailSendSuccessful )
                , ( S.successMessage, model.mailSendResult == MailSendSuccessful )
                , ( "hidden", model.mailSendResult == MailSendResultInitial )
                ]
            , class "mt-2"
            ]
            [ case model.mailSendResult of
                MailSendSuccessful ->
                    text texts.mailSendSuccessful

                MailSendHttpError err ->
                    text (texts.httpError err)

                MailSendFailed m ->
                    text m

                MailSendResultInitial ->
                    text ""
            ]
        ]


itemIdInfo : Texts -> Model -> Html msg
itemIdInfo texts model =
    div [ class "flex flex-col opacity-50 text-xs pb-1 mt-3 border-t dark:border-bluegray-600" ]
        [ div
            [ class "inline-flex items-center"
            , title texts.itemId
            ]
            [ i [ class "fa fa-bullseye mr-2" ] []
            , text model.item.id
            ]
        , div
            [ class "inline-flex items-center"
            , title texts.createdOn
            ]
            [ i [ class "fa fa-sun font-thin mr-2" ] []
            , texts.formatDateTime model.item.created |> text
            ]
        , div
            [ class "inline-flex items-center"
            , title texts.lastUpdateOn
            ]
            [ i [ class "fa fa-pencil-alt mr-2" ] []
            , texts.formatDateTime model.item.updated |> text
            ]
        ]


addDetailForm : Texts -> UiSettings -> Model -> Html Msg
addDetailForm texts settings model =
    case model.modalEdit of
        Just mm ->
            div
                [ class "flex flex-col px-2 py-2 mb-4"
                , class S.box
                ]
                [ Comp.DetailEdit.formHeading texts.detailEdit S.header3 mm
                , Html.map ModalEditMsg (Comp.DetailEdit.view2 texts.detailEdit [] settings mm)
                ]

        Nothing ->
            span [ class "hidden" ] []
