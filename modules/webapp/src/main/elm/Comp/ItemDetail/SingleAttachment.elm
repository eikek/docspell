{-
   Copyright 2020 Eike K. & Contributors

   SPDX-License-Identifier: AGPL-3.0-or-later
-}


module Comp.ItemDetail.SingleAttachment exposing (view)

import Api
import Api.Model.Attachment exposing (Attachment)
import Comp.AttachmentMeta
import Comp.ItemDetail.ConfirmModalView
import Comp.ItemDetail.Model
    exposing
        ( Model
        , Msg(..)
        , NotesField(..)
        , SaveNameState(..)
        , ViewMode(..)
        , isShowQrAttach
        )
import Comp.ItemDetail.ShowQrCode
import Comp.MenuBar as MB
import Data.Flags exposing (Flags)
import Data.Icons as Icons
import Data.UiSettings exposing (UiSettings)
import Dict
import Html exposing (..)
import Html.Attributes exposing (..)
import Html.Events exposing (onClick, onInput)
import Html5.DragDrop as DD
import Messages.Comp.ItemDetail.SingleAttachment exposing (Texts)
import Set
import Styles as S
import Util.Maybe
import Util.Size
import Util.String


view : Texts -> Flags -> UiSettings -> Model -> Int -> Attachment -> Html Msg
view texts flags settings model pos attach =
    let
        fileUrl =
            Api.fileURL attach.id
    in
    div
        [ class "flex flex-col md:relative h-full mb-2"
        , classList
            [ ( "hidden", not (attachmentVisible model pos) )
            ]
        ]
        [ renderModal texts model
        , div
            [ class "flex flex-row px-2 py-2 text-sm"
            , class S.border
            ]
            [ attachHeader texts settings model pos attach
            ]
        , editAttachmentName model attach
        , attachmentSelect texts model pos attach
        , if isAttachMetaOpen model attach.id then
            case Dict.get attach.id model.attachMeta of
                Just am ->
                    Html.map (AttachMetaMsg attach.id)
                        (Comp.AttachmentMeta.view2
                            texts.attachmentMeta
                            [ class "border-r border-l border-b dark:border-slate-600 px-2" ]
                            am
                        )

                Nothing ->
                    span [ class "hidden" ] []

          else if isShowQrAttach model.showQrModel then
            Comp.ItemDetail.ShowQrCode.view1 flags
                "border-r border-l border-b dark:border-slate-600 h-full"
                (Comp.ItemDetail.ShowQrCode.Attach attach.id)

          else
            div
                [ class "flex flex-col relative px-2 pt-2 h-full"
                , class "border-r border-l border-b dark:border-slate-600"
                , id "ds-pdf-view-parent"
                , style "max-height" "calc(100vh - 140px)"
                , style "min-height" "500px"
                ]
                [ embed
                    [ src <| Data.UiSettings.pdfUrl settings flags fileUrl
                    , class "absolute h-full w-full top-0 left-0 mx-0 py-0"
                    , id "ds-pdf-view-iframe"
                    ]
                    []
                ]
        ]


{-| attachment header

  - toggle thumbs
  - name + size
  - eye icon to open it
  - toggle multi select
  - menu
      - rename
      - meta data
      - download archive
      - download
      - delete
      - native view

-}
attachHeader : Texts -> UiSettings -> Model -> Int -> Attachment -> Html Msg
attachHeader texts settings model _ attach =
    let
        attachName =
            Maybe.withDefault texts.noName attach.name

        fileUrl =
            Api.fileURL attach.id

        hasArchive =
            List.map .id model.item.archives
                |> List.member attach.id

        multiAttach =
            List.length model.item.attachments > 1

        selectPossible =
            multiAttach && model.attachMenuOpen

        selectView =
            case model.viewMode of
                SelectView _ ->
                    True

                SimpleView ->
                    False

        selectToggleText =
            case model.viewMode of
                SelectView _ ->
                    texts.exitSelectMode

                SimpleView ->
                    texts.selectModeTitle

        noAttachmentsSelected =
            List.isEmpty model.item.attachments

        attachSelectToggle mobile =
            a
                [ href "#"
                , onClick ToggleAttachMenu
                , class S.secondaryBasicButton
                , class "mr-2"
                , classList
                    [ ( "bg-gray-200 dark:bg-slate-600 ", model.attachMenuOpen )
                    , ( "hidden", not multiAttach )
                    , ( "sm:hidden", multiAttach && mobile )
                    , ( "hidden sm:block", multiAttach && not mobile )
                    ]
                ]
                [ if model.attachMenuOpen then
                    i [ class "fa fa-chevron-up" ] []

                  else
                    i [ class "fa fa-chevron-down" ] []
                ]
    in
    div [ class "flex flex-col sm:flex-row items-center w-full" ]
        [ attachSelectToggle False
        , div [ class "text-base font-bold flex-grow w-full text-left break-all" ]
            [ text attachName
            , text " ("
            , text (Util.Size.bytesReadable Util.Size.B (toFloat attach.size))
            , text ")"
            ]
        , div [ class "flex flex-row justify-end items-center w-full" ]
            [ attachSelectToggle True
            , a
                [ href fileUrl
                , target "_new"
                , title texts.openFileInNewTab
                , class S.secondaryBasicButton
                , class "ml-2"
                , classList [ ( "hidden", selectView ) ]
                ]
                [ i [ class "fa fa-eye font-thin" ] []
                ]
            , a
                [ classList
                    [ ( S.secondaryBasicButton ++ " text-sm", True )
                    , ( "bg-gray-200 dark:bg-slate-600", selectView )
                    , ( "hidden", not selectPossible )
                    , ( "ml-2", True )
                    ]
                , href "#"
                , title selectToggleText
                , onClick ToggleSelectView
                ]
                [ i [ class "fa fa-tasks" ] []
                ]
            , a
                [ classList
                    [ ( S.deleteButton, True )
                    , ( "disabled", noAttachmentsSelected )
                    , ( "hidden", not selectPossible || not selectView )
                    , ( "ml-2", True )
                    ]
                , href "#"
                , title texts.deleteAttachments
                , onClick RequestDeleteSelected
                ]
                [ i [ class "fa fa-trash" ] []
                ]
            , MB.viewItem <|
                MB.Dropdown
                    { linkIcon = "fa fa-bars"
                    , label = ""
                    , linkClass =
                        [ ( "ml-2", True )
                        , ( S.secondaryBasicButton, True )
                        , ( "hidden", selectView )
                        ]
                    , toggleMenu = ToggleAttachmentDropdown
                    , menuOpen = model.attachmentDropdownOpen
                    , items =
                        [ { icon = i [ class "fa fa-download" ] []
                          , label = texts.downloadFile
                          , disabled = False
                          , attrs =
                                [ download attachName
                                , href fileUrl
                                ]
                          }
                        , { icon = i [ class "fa fa-file" ] []
                          , label = texts.renameFile
                          , disabled = False
                          , attrs =
                                [ href "#"
                                , onClick (EditAttachNameStart attach.id)
                                ]
                          }
                        , { icon = i [ class "fa fa-file-archive" ] []
                          , label = texts.downloadOriginalArchiveFile
                          , disabled = False
                          , attrs =
                                [ href (fileUrl ++ "/archive")
                                , target "_new"
                                , classList [ ( "hidden", not hasArchive ) ]
                                ]
                          }
                        , { icon = i [ class "fa fa-external-link-alt" ] []
                          , label = texts.originalFile
                          , disabled = False
                          , attrs =
                                [ href (fileUrl ++ "/original")
                                , target "_new"
                                , classList [ ( "hidden", not attach.converted ) ]
                                ]
                          }
                        , { icon =
                                if isAttachMetaOpen model attach.id then
                                    i [ class "fa fa-toggle-on" ] []

                                else
                                    i [ class "fa fa-toggle-off" ] []
                          , label = texts.viewExtractedData
                          , disabled = False
                          , attrs =
                                [ onClick (AttachMetaClick attach.id)
                                , href "#"
                                ]
                          }
                        , { icon = i [ class "fa fa-redo-alt" ] []
                          , label = texts.reprocessFile
                          , disabled = False
                          , attrs =
                                [ onClick (RequestReprocessFile attach.id)
                                , href "#"
                                ]
                          }
                        , { icon = i [ class Icons.showQr ] []
                          , label = texts.showQrCode
                          , disabled = False
                          , attrs =
                                [ onClick (ToggleShowQrAttach attach.id)
                                , href "#"
                                ]
                          }
                        , { icon = i [ class "fa fa-trash" ] []
                          , label = texts.deleteThisFile
                          , disabled = False
                          , attrs =
                                [ onClick (RequestDeleteAttachment attach.id)
                                , href "#"
                                ]
                          }
                        ]
                    }
            ]
        ]


attachmentVisible : Model -> Int -> Bool
attachmentVisible model pos =
    not model.sentMailsOpen
        && (if model.visibleAttach >= List.length model.item.attachments then
                pos == 0

            else
                model.visibleAttach == pos
           )


isAttachMetaOpen : Model -> String -> Bool
isAttachMetaOpen model id =
    model.attachMetaOpen && (Dict.get id model.attachMeta /= Nothing)


editAttachmentName : Model -> Attachment -> Html Msg
editAttachmentName model attach =
    let
        am =
            Util.Maybe.filter (\m -> m.id == attach.id) model.attachRename
    in
    case am of
        Just m ->
            div [ class "flex flex-row border-l border-r px-2 py-2 dark:border-slate-600" ]
                [ input
                    [ type_ "text"
                    , value m.newName
                    , onInput EditAttachNameSet
                    , class S.textInput
                    , class "mr-2"
                    ]
                    []
                , button
                    [ class S.primaryButton
                    , onClick EditAttachNameSubmit
                    ]
                    [ i [ class "fa fa-check" ] []
                    ]
                , button
                    [ class S.secondaryButton
                    , onClick EditAttachNameCancel
                    ]
                    [ i [ class "fa fa-times" ] []
                    ]
                ]

        Nothing ->
            span [ class "hidden" ] []


attachmentSelect : Texts -> Model -> Int -> Attachment -> Html Msg
attachmentSelect texts model _ _ =
    div
        [ class "flex flex-row border-l border-r px-2 py-2 dark:border-slate-600 "
        , class "overflow-x-auto overflow-y-none"
        , classList
            [ ( "hidden", not model.attachMenuOpen )
            ]
        ]
        (List.indexedMap (menuItem texts model) model.item.attachments)


menuItem : Texts -> Model -> Int -> Attachment -> Html Msg
menuItem texts model pos attach =
    let
        highlight =
            let
                dropId =
                    DD.getDropId model.attachDD

                dragId =
                    DD.getDragId model.attachDD

                enable =
                    Just attach.id == dropId && dropId /= dragId
            in
            [ ( "bg-gray-300 dark:bg-slate-700 current-drop-target", enable )
            ]

        iconClass =
            case model.viewMode of
                SelectView svm ->
                    if Set.member attach.id svm.ids then
                        "fa fa-check-circle ml-1"

                    else
                        "fa fa-circle ml-1"

                SimpleView ->
                    "fa fa-check-circle ml-1"

        visible =
            case model.viewMode of
                SelectView _ ->
                    True

                SimpleView ->
                    model.visibleAttach == pos

        msg =
            case model.viewMode of
                SelectView _ ->
                    ToggleAttachment attach.id

                SimpleView ->
                    SetActiveAttachment pos
    in
    a
        ([ classList <|
            [ ( "border-blue-500 dark:border-sky-500", pos == 0 )
            , ( "dark:border-slate-600", pos /= 0 )
            ]
                ++ highlight
         , class "flex flex-col relative border rounded px-1 py-1 mr-2"
         , class " hover:shadow dark:hover:border-slate-500"
         , href "#"
         , onClick msg
         ]
            ++ DD.draggable AttachDDMsg attach.id
            ++ DD.droppable AttachDDMsg attach.id
        )
        [ div
            [ classList
                [ ( "hidden", not visible )
                ]
            , class "absolute right-1 top-1 text-blue-400 dark:text-sky-400 text-xl"
            ]
            [ i [ class iconClass ] []
            ]
        , div [ class "flex-grow" ]
            [ img
                [ src (Api.attachmentPreviewURL attach.id)
                , class "block w-20 mx-auto"
                ]
                []
            ]
        , div [ class "mt-1 text-sm break-all w-28 text-center" ]
            [ Maybe.map (Util.String.ellipsis 36) attach.name
                |> Maybe.withDefault texts.noName
                |> text
            ]
        ]


renderModal : Texts -> Model -> Html Msg
renderModal texts model =
    case model.attachModal of
        Just mm ->
            Comp.ItemDetail.ConfirmModalView.view texts.confirmModal mm model

        Nothing ->
            span [ class "hidden" ] []
