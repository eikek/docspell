module Comp.ItemDetail.SingleAttachment exposing (view)

import Api
import Api.Model.Attachment exposing (Attachment)
import Comp.AttachmentMeta
import Comp.ConfirmModal
import Comp.ItemDetail.Model
    exposing
        ( Model
        , Msg(..)
        , NotesField(..)
        , SaveNameState(..)
        )
import Comp.MenuBar as MB
import Data.UiSettings exposing (UiSettings)
import Dict
import Html exposing (..)
import Html.Attributes exposing (..)
import Html.Events exposing (onClick, onInput)
import Html5.DragDrop as DD
import Messages.Comp.ItemDetail.SingleAttachment exposing (Texts)
import Page exposing (Page(..))
import Styles as S
import Util.Maybe
import Util.Size
import Util.String


view : Texts -> UiSettings -> Model -> Int -> Attachment -> Html Msg
view texts settings model pos attach =
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
        [ renderModal model
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
                            [ class "border-r border-l border-b dark:border-bluegray-600 px-2" ]
                            am
                        )

                Nothing ->
                    span [ class "hidden" ] []

          else
            div
                [ class "flex flex-col relative px-2 pt-2 h-full"
                , class "border-r border-l border-b dark:border-bluegray-600"
                , id "ds-pdf-view-parent"
                , style "max-height" "calc(100vh - 140px)"
                , style "min-height" "500px"
                ]
                [ iframe
                    [ if Maybe.withDefault settings.nativePdfPreview model.pdfNativeView then
                        src fileUrl

                      else
                        src (fileUrl ++ "/view")
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

        attachSelectToggle mobile =
            a
                [ href "#"
                , onClick ToggleAttachMenu
                , class S.secondaryBasicButton
                , classList
                    [ ( "bg-gray-200 dark:bg-bluegray-600 ", model.attachMenuOpen )
                    , ( "hidden", not multiAttach )
                    , ( "sm:hidden", multiAttach && mobile )
                    , ( "hidden sm:block", multiAttach && not mobile )
                    ]
                ]
                [ i [ class "fa fa-images font-thin" ] []
                ]
    in
    div [ class "flex flex-col sm:flex-row items-center w-full" ]
        [ attachSelectToggle False
        , div [ class "ml-2 text-base font-bold flex-grow w-full text-center sm:text-left" ]
            [ text attachName
            , text " ("
            , text (Util.Size.bytesReadable Util.Size.B (toFloat attach.size))
            , text ")"
            ]
        , div [ class "flex flex-row justify-end items-center" ]
            [ attachSelectToggle True
            , a
                [ href fileUrl
                , target "_new"
                , title texts.openFileInNewTab
                , class S.secondaryBasicButton
                , class "ml-2"
                ]
                [ i [ class "fa fa-eye font-thin" ] []
                ]
            , MB.viewItem <|
                MB.Dropdown
                    { linkIcon = "fa fa-bars"
                    , linkClass =
                        [ ( "ml-2", True )
                        , ( S.secondaryBasicButton, True )
                        ]
                    , toggleMenu = ToggleAttachmentDropdown
                    , menuOpen = model.attachmentDropdownOpen
                    , items =
                        [ { icon = "fa fa-download"
                          , label = texts.downloadFile
                          , attrs =
                                [ download attachName
                                , href fileUrl
                                ]
                          }
                        , { icon = "fa fa-file"
                          , label = texts.renameFile
                          , attrs =
                                [ href "#"
                                , onClick (EditAttachNameStart attach.id)
                                ]
                          }
                        , { icon = "fa fa-file-archive"
                          , label = texts.downloadOriginalArchiveFile
                          , attrs =
                                [ href (fileUrl ++ "/archive")
                                , target "_new"
                                , classList [ ( "hidden", not hasArchive ) ]
                                ]
                          }
                        , { icon = "fa fa-external-link-alt"
                          , label = texts.originalFile
                          , attrs =
                                [ href (fileUrl ++ "/original")
                                , target "_new"
                                , classList [ ( "hidden", not attach.converted ) ]
                                ]
                          }
                        , { icon =
                                if Maybe.withDefault settings.nativePdfPreview model.pdfNativeView then
                                    "fa fa-toggle-on"

                                else
                                    "fa fa-toggle-off"
                          , label = texts.renderPdfByBrowser
                          , attrs =
                                [ onClick (TogglePdfNativeView settings.nativePdfPreview)
                                , href "#"
                                ]
                          }
                        , { icon =
                                if isAttachMetaOpen model attach.id then
                                    "fa fa-toggle-on"

                                else
                                    "fa fa-toggle-off"
                          , label = texts.viewExtractedData
                          , attrs =
                                [ onClick (AttachMetaClick attach.id)
                                , href "#"
                                ]
                          }
                        , { icon = "fa fa-redo-alt"
                          , label = texts.reprocessFile
                          , attrs =
                                [ onClick (RequestReprocessFile attach.id)
                                , href "#"
                                ]
                          }
                        , { icon = "fa fa-trash"
                          , label = texts.deleteThisFile
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
            div [ class "flex flex-row border-l border-r px-2 py-2 dark:border-bluegray-600" ]
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
        [ class "flex flex-row border-l border-r px-2 py-2 dark:border-bluegray-600 "
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
            [ ( "bg-gray-300 dark:bg-bluegray-700 current-drop-target", enable )
            ]

        active =
            model.visibleAttach == pos
    in
    a
        ([ classList <|
            [ ( "border-blue-500 dark:border-lightblue-500", pos == 0 )
            , ( "dark:border-bluegray-600", pos /= 0 )
            ]
                ++ highlight
         , class "flex flex-col relative border rounded px-1 py-1 mr-2"
         , class " hover:shadow dark:hover:border-bluegray-500"
         , href "#"
         , onClick (SetActiveAttachment pos)
         ]
            ++ DD.draggable AttachDDMsg attach.id
            ++ DD.droppable AttachDDMsg attach.id
        )
        [ div
            [ classList
                [ ( "hidden", not active )
                ]
            , class "absolute right-1 top-1 text-blue-400 dark:text-lightblue-400 text-xl"
            ]
            [ i [ class "fa fa-check-circle ml-1" ] []
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


renderModal : Model -> Html Msg
renderModal model =
    case model.attachModal of
        Just confirmModal ->
            Comp.ConfirmModal.view confirmModal

        Nothing ->
            span [ class "hidden" ] []
