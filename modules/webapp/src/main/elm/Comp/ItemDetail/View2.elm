{-
   Copyright 2020 Eike K. & Contributors

   SPDX-License-Identifier: AGPL-3.0-or-later
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
        , isShowQrItem
        )
import Comp.ItemDetail.Notes
import Comp.ItemDetail.RunAddonForm
import Comp.ItemDetail.ShowQrCode
import Comp.ItemDetail.SingleAttachment
import Comp.ItemLinkForm
import Comp.ItemMail
import Comp.MenuBar as MB
import Comp.SentMails
import Data.Environment as Env
import Data.Flags exposing (Flags)
import Data.Icons as Icons
import Data.ItemIds
import Data.ItemNav exposing (ItemNav)
import Data.UiSettings exposing (UiSettings)
import Html exposing (..)
import Html.Attributes exposing (..)
import Html.Events exposing (onClick)
import Messages.Comp.ItemDetail exposing (Texts)
import Page exposing (Page(..))
import Styles as S


view : Texts -> ItemNav -> Env.View -> Model -> Html Msg
view texts inav env model =
    div [ class "flex flex-col h-full" ]
        [ header texts inav env model
        , body texts env.flags inav env.settings model
        , itemModal texts model
        ]


itemModal : Texts -> Model -> Html Msg
itemModal texts model =
    case model.itemModal of
        Just confirm ->
            Comp.ItemDetail.ConfirmModalView.view texts.confirmModal confirm model

        Nothing ->
            span [ class "hidden" ] []


header : Texts -> ItemNav -> Env.View -> Model -> Html Msg
header texts inav env model =
    div [ class "my-3" ]
        [ Comp.ItemDetail.ItemInfoHeader.view texts.itemInfoHeader
            env.settings
            model
            (menuBar texts inav env model)
        ]


menuBar : Texts -> ItemNav -> Env.View -> Model -> Html Msg
menuBar texts inav env model =
    let
        keyDescr name =
            if env.settings.itemDetailShortcuts && model.menuOpen then
                " " ++ texts.key ++ "'" ++ name ++ "'."

            else
                ""

        isSelected =
            Data.ItemIds.isMember env.selectedItems model.item.id

        foldSelected fsel funsel =
            if isSelected then
                fsel

            else
                funsel
    in
    MB.view
        { start =
            [ MB.CustomElement <|
                a
                    [ class S.secondaryBasicButton
                    , Page.href (SearchPage Nothing)
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
                        [ ( "bg-gray-200 dark:bg-slate-600", model.mailOpen )
                        ]
                    , class "hidden md:block"
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
                        [ ( "bg-gray-200 dark:bg-slate-600", model.addFilesOpen )
                        ]
                    , class "hidden md:block"
                    , if model.addFilesOpen then
                        title texts.close

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
                    [ classList
                        [ ( "bg-gray-200 dark:bg-slate-600", model.showRunAddon )
                        , ( "hidden", not env.flags.config.addonsEnabled || List.isEmpty model.runConfigs )
                        , ( "hidden md:block", env.flags.config.addonsEnabled && not (List.isEmpty model.runConfigs) )
                        ]
                    , if model.showRunAddon then
                        title texts.close

                      else
                        title texts.runAddonTitle
                    , onClick ToggleShowRunAddon
                    , class S.secondaryBasicButton
                    , href "#"
                    ]
                    [ Icons.addonIcon ""
                    ]
            , MB.CustomElement <|
                a
                    [ classList
                        [ ( "bg-gray-200 dark:bg-slate-600", isShowQrItem model.showQrModel )
                        ]
                    , class "hidden md:block"
                    , if isShowQrItem model.showQrModel then
                        title texts.close

                      else
                        title texts.showQrCode
                    , onClick (ToggleShowQrItem model.item.id)
                    , class S.secondaryBasicButton
                    , href "#"
                    ]
                    [ Icons.showQrIcon ""
                    ]
            , MB.CustomElement <|
                div
                    [ class "flex flex-grow md:hidden"
                    ]
                    []
            , MB.CustomElement <|
                a
                    [ class S.primaryButton
                    , href "#"
                    , onClick ConfirmItem
                    , title texts.confirmItemMetadata
                    , classList [ ( "hidden", model.item.state /= "created" ) ]
                    ]
                    [ i [ class "fa fa-check" ] []
                    , span [ class "hidden ml-0 sm:ml-2 sm:inline" ]
                        [ text texts.confirm ]
                    ]
            , MB.Dropdown
                { linkIcon = "fa fa-bars"
                , label = ""
                , linkClass =
                    [ ( "md:hidden", True )
                    , ( S.secondaryBasicButton, True )
                    ]
                , toggleMenu = ToggleMobileItemMenu
                , menuOpen = model.mobileItemMenuOpen
                , items =
                    [ { icon =
                            foldSelected
                                (i [ class "fa fa-check-square dark:text-lime-400 text-lime-600" ] [])
                                (i [ class "fa-regular fa-plus" ] [])
                      , label = foldSelected texts.deselectItem texts.selectItem
                      , disabled = False
                      , attrs =
                            [ href "#"
                            , onClick ToggleSelectItem
                            ]
                      }
                    , { icon = i [ class "fa fa-envelope font-thin" ] []
                      , label = texts.sendMail
                      , disabled = False
                      , attrs =
                            [ href "#"
                            , onClick ToggleMail
                            ]
                      }
                    , { icon = Icons.addFilesIcon2 ""
                      , label = texts.addMoreFiles
                      , disabled = False
                      , attrs =
                            [ href "#"
                            , onClick AddFilesToggle
                            ]
                      }
                    , { icon = Icons.addonIcon ""
                      , label = texts.runAddonLabel
                      , disabled = False
                      , attrs =
                            [ href "#"
                            , onClick ToggleShowRunAddon
                            , classList [ ( "hidden", not env.flags.config.addonsEnabled ) ]
                            ]
                      }
                    , { icon = Icons.showQrIcon ""
                      , label = texts.showQrCode
                      , disabled = False
                      , attrs =
                            [ href "#"
                            , onClick (ToggleShowQrItem model.item.id)
                            ]
                      }
                    , { icon = i [] []
                      , label = "separator"
                      , disabled = False
                      , attrs =
                            []
                      }
                    , { icon = i [ class "fa fa-eye-slash font-thin" ] []
                      , label = texts.unconfirmItemMetadata
                      , disabled = False
                      , attrs =
                            [ href "#"
                            , onClick UnconfirmItem
                            , classList [ ( "hidden", model.item.state == "created" ) ]
                            ]
                      }
                    , { icon = i [ class "fa fa-redo" ] []
                      , label = texts.reprocessItem
                      , disabled = False
                      , attrs =
                            [ href "#"
                            , onClick RequestReprocessItem
                            ]
                      }
                    , if model.item.state == "deleted" then
                        { icon = i [ class "fa fa-trash-restore" ] []
                        , label = texts.undeleteThisItem
                        , disabled = False
                        , attrs =
                            [ href "#"
                            , onClick RestoreItem
                            ]
                        }

                      else
                        { icon = i [ class "fa fa-trash", class "text-red-500 dark:text-orange-500" ] []
                        , label = texts.deleteThisItem
                        , disabled = False
                        , attrs =
                            [ href "#"
                            , onClick RequestDelete
                            ]
                        }
                    ]
                }
            ]
        , end =
            [ MB.CustomElement <|
                a
                    [ href "#"
                    , onClick ToggleSelectItem
                    , title (foldSelected texts.deselectItem texts.selectItem)
                    , class "hidden md:flex flex-row items-center h-full "
                    , classList
                        [ ( S.greenButton, isSelected )
                        , ( S.secondaryBasicButton, not isSelected )
                        ]
                    ]
                    [ foldSelected
                        (i [ class "fa fa-square-check" ] [])
                        (i [ class "fa fa-plus" ] [])
                    ]
            , MB.CustomElement <|
                a
                    [ class S.secondaryBasicButton
                    , href "#"
                    , onClick UnconfirmItem
                    , title texts.unconfirmItemMetadata
                    , class "hidden"
                    , classList [ ( "md:block", model.item.state /= "created" ) ]
                    ]
                    [ i [ class "fa fa-eye-slash font-thin" ] []
                    ]
            , MB.CustomElement <|
                a
                    [ class S.secondaryBasicButton
                    , class "hidden md:block"
                    , href "#"
                    , onClick RequestReprocessItem
                    , title texts.reprocessItem
                    ]
                    [ i [ class "fa fa-redo" ] []
                    ]
            , if model.item.state == "deleted" then
                MB.CustomElement <|
                    a
                        [ class S.undeleteButton
                        , class "hidden md:block"
                        , href "#"
                        , onClick RestoreItem
                        , title texts.undeleteThisItem
                        ]
                        [ i [ class "fa fa-trash-restore" ] []
                        ]

              else
                MB.CustomElement <|
                    a
                        [ class S.deleteButton
                        , class "hidden md:block"
                        , href "#"
                        , onClick RequestDelete
                        , title texts.deleteThisItem
                        ]
                        [ i [ class "fa fa-trash" ] []
                        ]
            ]
        , rootClasses = "mb-2 md:mt-2"
        , sticky = False
        }


body : Texts -> Flags -> ItemNav -> UiSettings -> Model -> Html Msg
body texts flags _ settings model =
    div [ class "grid gap-2 grid-cols-1 md:grid-cols-3 h-full" ]
        [ div [ class "flex flex-col hidden md:block h-full" ]
            [ itemActions texts flags settings model ""
            , notesAndSentMails texts flags settings model "h-full"
            ]
        , attachmentView texts flags settings model "order-2 col-span-2"
        , itemActions texts flags settings model "order-1 md:hidden"
        , notesAndSentMails texts flags settings model "order-3 md:hidden"
        ]


attachmentView : Texts -> Flags -> UiSettings -> Model -> String -> Html Msg
attachmentView texts flags settings model classes =
    div
        [ class "h-full"
        , class classes
        ]
        (attachmentsBody texts flags settings model)


itemActions : Texts -> Flags -> UiSettings -> Model -> String -> Html Msg
itemActions texts flags settings model classes =
    div
        [ class "w-full md:mr-2 flex flex-col"
        , class classes
        ]
        [ addDetailForm texts settings model
        , sendMailForm texts settings model
        , Comp.ItemDetail.AddFilesForm.view texts.addFilesForm model
        , Comp.ItemDetail.ShowQrCode.view flags
            (S.border ++ " mb-4")
            model
            (Comp.ItemDetail.ShowQrCode.Item model.item.id)
        , if flags.config.addonsEnabled then
            Comp.ItemDetail.RunAddonForm.view texts.runAddonForm settings model

          else
            span [ class "hidden" ] []
        ]


notesAndSentMails : Texts -> Flags -> UiSettings -> Model -> String -> Html Msg
notesAndSentMails texts _ settings model classes =
    div
        [ class "w-full md:mr-2 flex flex-col"
        , class classes
        ]
        [ Comp.ItemDetail.Notes.view texts.notes model
        , div [ class "mb-4 mt-4" ]
            [ div [ class "font-bold text-lg" ]
                [ text texts.relatedItems
                ]
            , Html.map ItemLinkFormMsg (Comp.ItemLinkForm.view texts.itemLinkForm settings model.itemLinkModel)
            ]
        , div
            [ classList
                [ ( "hidden", Comp.SentMails.isEmpty model.sentMails )
                ]
            , class "mt-4 "
            ]
            [ h3 [ class "flex flex-row items-center border-b dark:border-slate-600 font-bold text-lg" ]
                [ text texts.sentEmails
                ]
            , Html.map SentMailsMsg (Comp.SentMails.view2 texts.sentMails model.sentMails)
            ]
        , div [ class "flex-grow" ] []
        , itemIdInfo texts model
        ]


attachmentsBody : Texts -> Flags -> UiSettings -> Model -> List (Html Msg)
attachmentsBody texts flags settings model =
    List.indexedMap (Comp.ItemDetail.SingleAttachment.view texts.singleAttachment flags settings model)
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
    div [ class "flex flex-col opacity-50 text-xs pb-1 mt-3 border-t dark:border-slate-600" ]
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
