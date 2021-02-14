module Comp.ItemDetail.View2 exposing (view)

import Comp.Basic as B
import Comp.DetailEdit
import Comp.ItemDetail.AddFilesForm
import Comp.ItemDetail.ItemInfoHeader
import Comp.ItemDetail.Model
    exposing
        ( Model
        , Msg(..)
        , NotesField(..)
        , SaveNameState(..)
        )
import Comp.ItemDetail.Notes
import Comp.ItemDetail.SingleAttachment
import Comp.ItemMail
import Comp.MenuBar as MB
import Comp.SentMails
import Comp.YesNoDimmer
import Data.Icons as Icons
import Data.ItemNav exposing (ItemNav)
import Data.UiSettings exposing (UiSettings)
import Html exposing (..)
import Html.Attributes exposing (..)
import Html.Events exposing (onClick)
import Page exposing (Page(..))
import Styles as S
import Util.Time


view : ItemNav -> UiSettings -> Model -> Html Msg
view inav settings model =
    div [ class "flex flex-col h-full" ]
        [ header settings model
        , menuBar inav settings model
        , body inav settings model
        , Html.map DeleteItemConfirm
            (Comp.YesNoDimmer.viewN
                True
                (Comp.YesNoDimmer.defaultSettings2 "Really delete the complete item?")
                model.deleteItemConfirm
            )
        ]


header : UiSettings -> Model -> Html Msg
header settings model =
    div [ class "my-3" ]
        [ Comp.ItemDetail.ItemInfoHeader.view settings model ]


menuBar : ItemNav -> UiSettings -> Model -> Html Msg
menuBar inav settings model =
    let
        keyDescr name =
            if settings.itemDetailShortcuts && model.menuOpen then
                " Key '" ++ name ++ "'."

            else
                ""
    in
    MB.view
        { start =
            [ MB.CustomElement <|
                a
                    [ class S.secondaryBasicButton
                    , Page.href HomePage
                    , title "Back to search results"
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
                            [ title ("Previous item." ++ keyDescr "Ctrl-,")
                            ]
                        }
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
                            [ title ("Next item." ++ keyDescr "Ctrl-.")
                            ]
                        }
                    ]
            , MB.CustomElement <|
                a
                    [ classList
                        [ ( "bg-gray-200 dark:bg-bluegray-600", model.mailOpen )
                        ]
                    , title "Send Mail"
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
                        title "Add more files to this item"
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
                    , title "Confirm item metadata"
                    , classList [ ( "hidden", model.item.state /= "created" ) ]
                    ]
                    [ i [ class "fa fa-check mr-2" ] []
                    , text "Confirm"
                    ]
            ]
        , end =
            [ MB.CustomElement <|
                a
                    [ class S.secondaryBasicButton
                    , href "#"
                    , onClick UnconfirmItem
                    , title "Un-confirm item metadata"
                    , classList [ ( "hidden", model.item.state == "created" ) ]
                    ]
                    [ i [ class "fa fa-eye-slash font-thin" ] []
                    ]
            , MB.CustomElement <|
                a
                    [ class S.deleteButton
                    , href "#"
                    , onClick RequestDelete
                    , title "Delete this item"
                    ]
                    [ i [ class "fa fa-trash" ] []
                    ]
            ]
        , rootClasses = "mb-2"
        }


body : ItemNav -> UiSettings -> Model -> Html Msg
body inav settings model =
    div [ class "grid gap-2 grid-cols-1 md:grid-cols-3 h-full" ]
        [ leftArea settings model
        , rightArea settings model
        ]


leftArea : UiSettings -> Model -> Html Msg
leftArea settings model =
    div [ class "w-full md:order-first md:mr-2 flex flex-col" ]
        [ addDetailForm settings model
        , sendMailForm settings model
        , Comp.ItemDetail.AddFilesForm.view model
        , Comp.ItemDetail.Notes.view model
        , div
            [ classList
                [ ( "hidden", Comp.SentMails.isEmpty model.sentMails )
                ]
            , class "mt-4 "
            ]
            [ h3 [ class "flex flex-row items-center border-b dark:border-bluegray-600 font-bold text-lg" ]
                [ text "Sent E-Mails"
                ]
            , Html.map SentMailsMsg (Comp.SentMails.view2 model.sentMails)
            ]
        , div [ class "flex-grow" ] []
        , itemIdInfo model
        ]


rightArea : UiSettings -> Model -> Html Msg
rightArea settings model =
    div [ class "md:col-span-2 h-full" ]
        (attachmentsBody settings model)


attachmentsBody : UiSettings -> Model -> List (Html Msg)
attachmentsBody settings model =
    List.indexedMap (Comp.ItemDetail.SingleAttachment.view settings model)
        model.item.attachments


sendMailForm : UiSettings -> Model -> Html Msg
sendMailForm settings model =
    div
        [ classList
            [ ( "hidden", not model.mailOpen )
            ]
        , class S.box
        , class "mb-4 px-2 py-2"
        ]
        [ div [ class "text-lg font-bold" ]
            [ text "Send this item via E-Mail"
            ]
        , B.loadingDimmer model.mailSending
        , Html.map ItemMailMsg (Comp.ItemMail.view2 settings model.itemMail)
        , div
            [ classList
                [ ( S.errorMessage
                  , Maybe.map .success model.mailSendResult
                        |> Maybe.map not
                        |> Maybe.withDefault False
                  )
                , ( S.successMessage
                  , Maybe.map .success model.mailSendResult
                        |> Maybe.withDefault False
                  )
                , ( "hidden", model.mailSendResult == Nothing )
                ]
            , class "mt-2"
            ]
            [ Maybe.map .message model.mailSendResult
                |> Maybe.withDefault ""
                |> text
            ]
        ]


itemIdInfo : Model -> Html msg
itemIdInfo model =
    div [ class "flex flex-col opacity-50 text-xs pb-1 mt-3 border-t dark:border-bluegray-600" ]
        [ div
            [ class "inline-flex items-center"
            , title "Item ID"
            ]
            [ i [ class "fa fa-bullseye mr-2" ] []
            , text model.item.id
            ]
        , div
            [ class "inline-flex items-center"
            , title "Created on"
            ]
            [ i [ class "fa fa-sun font-thin mr-2" ] []
            , Util.Time.formatDateTime model.item.created |> text
            ]
        , div
            [ class "inline-flex items-center"
            , title "Last update on"
            ]
            [ i [ class "fa fa-pencil-alt mr-2" ] []
            , Util.Time.formatDateTime model.item.updated |> text
            ]
        ]


addDetailForm : UiSettings -> Model -> Html Msg
addDetailForm settings model =
    case model.modalEdit of
        Just mm ->
            div
                [ class "flex flex-col px-2 py-2 mb-4"
                , class S.box
                ]
                [ Comp.DetailEdit.formHeading S.header3 mm
                , Html.map ModalEditMsg (Comp.DetailEdit.view2 [] settings mm)
                ]

        Nothing ->
            span [ class "hidden" ] []
