{-
   Copyright 2020 Eike K. & Contributors

   SPDX-License-Identifier: AGPL-3.0-or-later
-}


module Page.ShareDetail.View exposing (viewContent, viewSidebar)

import Api
import Api.Model.Attachment exposing (Attachment)
import Api.Model.VersionInfo exposing (VersionInfo)
import Comp.Basic as B
import Comp.SharePasswordForm
import Comp.UrlCopy
import Data.Fields
import Data.Flags exposing (Flags)
import Data.Icons as Icons
import Data.ItemTemplate as IT exposing (ItemTemplate)
import Data.UiSettings exposing (UiSettings)
import Html exposing (..)
import Html.Attributes exposing (..)
import Html.Events exposing (onClick)
import Messages.Page.ShareDetail exposing (Texts)
import Page exposing (Page(..))
import Page.ShareDetail.Data exposing (..)
import Styles as S
import Util.CustomField
import Util.Item
import Util.List
import Util.Size
import Util.String


viewSidebar : Texts -> Bool -> Flags -> UiSettings -> String -> String -> Model -> Html Msg
viewSidebar texts visible flags settings shareId itemId model =
    div
        [ id "sidebar"
        , classList [ ( "hidden", not visible || model.viewMode /= ViewNormal ) ]
        , class S.sidebar
        ]
        [ div [ class "pt-2" ]
            [ itemData texts flags model shareId itemId
            ]
        ]


viewContent : Texts -> Flags -> UiSettings -> VersionInfo -> String -> String -> Model -> Html Msg
viewContent texts flags uiSettings versionInfo shareId itemId model =
    case model.viewMode of
        ViewLoading ->
            div
                [ id "content"
                , class "h-full w-full flex flex-col text-5xl"
                , class S.content
                ]
                [ div [ class "text-5xl" ]
                    [ B.loadingDimmer
                        { active = model.pageError == PageErrorNone
                        , label = ""
                        }
                    ]
                , div [ class "my-4 text-lg" ]
                    [ errorMessage texts model
                    ]
                ]

        ViewPassword ->
            passwordContent texts flags versionInfo model

        ViewNormal ->
            mainContent texts flags uiSettings shareId model



--- Helper


mainContent : Texts -> Flags -> UiSettings -> String -> Model -> Html Msg
mainContent texts flags settings shareId model =
    div
        [ class "flex flex-col"
        , class S.content
        ]
        [ itemHead texts shareId model
        , errorMessage texts model
        , div [ class "relative h-full" ]
            [ itemPreview texts flags settings model
            ]
        ]


itemData : Texts -> Flags -> Model -> String -> String -> Html Msg
itemData texts flags model shareId itemId =
    let
        boxStyle =
            "mb-4 sm:mb-6"

        headerStyle =
            "py-2 bg-blue-50 hover:bg-blue-100 dark:bg-slate-700 dark:hover:bg-opacity-100 dark:hover:bg-slate-600 text-lg font-medium rounded-lg"

        showTag tag =
            div
                [ class "flex ml-2 mt-1 font-semibold hover:opacity-75"
                , class S.basicLabel
                ]
                [ i [ class "fa fa-tag mr-2" ] []
                , text tag.name
                ]

        showField =
            Util.CustomField.renderValue2
                [ ( S.basicLabel, True )
                , ( "flex ml-2 mt-1 font-semibold hover:opacity-75", True )
                ]
                Nothing
    in
    div [ class "flex flex-col" ]
        [ div [ class boxStyle ]
            [ div [ class headerStyle ]
                [ Icons.dateIcon2 "mr-2 ml-2"
                , text (texts.field Data.Fields.Date)
                ]
            , div [ class "text-lg ml-2" ]
                [ Util.Item.toItemLight model.item
                    |> IT.render IT.dateLong (templateCtx texts)
                    |> text
                ]
            ]
        , div
            [ class boxStyle
            , classList [ ( "hidden", model.item.dueDate == Nothing ) ]
            ]
            [ div [ class headerStyle ]
                [ Icons.dueDateIcon2 "mr-2 ml-2"
                , text (texts.field Data.Fields.DueDate)
                ]
            , div [ class "text-lg ml-2" ]
                [ Util.Item.toItemLight model.item
                    |> IT.render IT.dueDateLong (templateCtx texts)
                    |> text
                ]
            ]
        , div [ class boxStyle ]
            [ div [ class headerStyle ]
                [ Icons.tagsIcon2 "mr-2 ml-2"
                , text texts.tagsAndFields
                ]
            , div [ class "flex flex-row items-center flex-wrap font-medium my-1" ]
                (List.map showTag model.item.tags ++ List.map showField model.item.customfields)
            ]
        , div [ class boxStyle ]
            [ div [ class headerStyle ]
                [ Icons.correspondentIcon2 "mr-2 ml-2"
                , text texts.basics.correspondent
                ]
            , div [ class "text-lg ml-2" ]
                [ Util.Item.toItemLight model.item
                    |> IT.render IT.correspondent (templateCtx texts)
                    |> text
                ]
            ]
        , div [ class boxStyle ]
            [ div [ class headerStyle ]
                [ Icons.concernedIcon2 "mr-2 ml-2"
                , text texts.basics.concerning
                ]
            , div [ class "text-lg ml-2" ]
                [ Util.Item.toItemLight model.item
                    |> IT.render IT.concerning (templateCtx texts)
                    |> text
                ]
            ]
        , div [ class boxStyle ]
            [ div [ class headerStyle ]
                [ i [ class "fa fa-copy mr-2 ml-2" ] []
                , text "Copy URL"
                ]
            , div [ class "flex flex-col items-center py-2" ]
                [ Html.map UrlCopyMsg
                    (Comp.UrlCopy.view
                        (flags.config.baseUrl
                            ++ Page.pageToString
                                (ShareDetailPage shareId itemId)
                        )
                    )
                ]
            ]
        ]


itemPreview : Texts -> Flags -> UiSettings -> Model -> Html Msg
itemPreview texts flags settings model =
    let
        attach =
            Util.List.get model.item.attachments model.visibleAttach
                |> Maybe.withDefault Api.Model.Attachment.empty

        attachName =
            Maybe.withDefault (texts.noName ++ ".pdf") attach.name
    in
    div
        [ class "flex flex-grow flex-col h-full border-t dark:border-slate-600"
        ]
        [ div [ class "flex flex-col sm:flex-row items-center py-1 px-1 border-l border-r dark:border-slate-600" ]
            [ div [ class "text-base font-bold flex-grow w-full text-center sm:text-left break-all" ]
                [ text attachName
                , text " ("
                , text (Util.Size.bytesReadable Util.Size.B (toFloat attach.size))
                , text ")"
                ]
            , div [ class "flex flex-row space-x-2" ]
                [ B.secondaryBasicButton
                    { label = ""
                    , icon = "fa fa-eye"
                    , disabled = False
                    , handler = href (Api.shareFileURL attach.id)
                    , attrs =
                        [ target "_new"
                        ]
                    }
                , B.secondaryBasicButton
                    { label = ""
                    , icon = "fa fa-download"
                    , disabled = False
                    , handler = href (Api.shareFileURL attach.id)
                    , attrs =
                        [ download attachName
                        ]
                    }
                , B.secondaryBasicButton
                    { label = ""
                    , icon = "fa fa-ellipsis-v"
                    , disabled = False
                    , handler = onClick ToggleSelectAttach
                    , attrs =
                        [ href "#"
                        , classList [ ( "hidden", List.length model.item.attachments <= 1 ) ]
                        ]
                    }
                ]
            ]
        , attachmentSelect texts model
        , div
            [ class "flex w-full h-full mb-4 border-b border-l border-r dark:border-slate-600"
            , style "min-height" "500px"
            ]
            [ embed
                [ src (Data.UiSettings.pdfUrl settings flags (Api.shareFileURL attach.id))
                , class " h-full w-full mx-0 py-0"
                ]
                []
            ]
        ]


itemHead : Texts -> String -> Model -> Html Msg
itemHead texts shareId model =
    div [ class "flex flex-col sm:flex-row mt-1" ]
        [ div [ class "flex flex-grow items-center" ]
            [ h1
                [ class S.header1
                , class "items-center flex flex-row"
                ]
                [ text model.item.name
                , span
                    [ classList [ ( "hidden", model.item.state /= "created" ) ]
                    , class S.blueBasicLabel
                    , class "inline ml-4 text-sm"
                    ]
                    [ text texts.unconfirmed
                    ]
                ]
            ]
        , div [ class "flex flex-row items-center justify-end mb-2 sm:mb-0" ]
            [ B.secondaryBasicButton
                { label = texts.basics.back
                , icon = "fa fa-times"
                , disabled = False
                , handler = Page.href (SharePage shareId)
                , attrs = []
                }
            ]
        ]


passwordContent : Texts -> Flags -> VersionInfo -> Model -> Html Msg
passwordContent texts flags versionInfo model =
    div
        [ id "content"
        , class "h-full flex flex-col items-center justify-center w-full"
        , class S.content
        ]
        [ Html.map PasswordMsg
            (Comp.SharePasswordForm.view texts.passwordForm flags versionInfo model.passwordModel)
        ]


attachmentSelect : Texts -> Model -> Html Msg
attachmentSelect texts model =
    div
        [ class "flex flex-row border-l border-t border-r px-2 py-2 dark:border-slate-600 "
        , class "overflow-x-auto overflow-y-none"
        , classList
            [ ( "hidden", not model.attachMenuOpen )
            ]
        ]
        (List.indexedMap (menuItem texts model) model.item.attachments)


menuItem : Texts -> Model -> Int -> Attachment -> Html Msg
menuItem texts model pos attach =
    let
        iconClass =
            "fa fa-circle ml-1"

        visible =
            model.visibleAttach == pos
    in
    a
        [ classList <|
            [ ( "border-blue-500 dark:border-sky-500", pos == 0 )
            , ( "dark:border-slate-600", pos /= 0 )
            ]
        , class "flex flex-col relative border rounded px-1 py-1 mr-2"
        , class " hover:shadow dark:hover:border-slate-500"
        , href "#"
        , onClick (SelectActiveAttachment pos)
        ]
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
                [ src (Api.shareAttachmentPreviewURL attach.id)
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


errorMessage : Texts -> Model -> Html Msg
errorMessage texts model =
    case model.pageError of
        PageErrorNone ->
            span [ class "hidden" ] []

        PageErrorAuthFail ->
            div
                [ class S.errorMessage
                , class "my-4"
                ]
                [ text texts.authFailed
                ]

        PageErrorHttp err ->
            div
                [ class S.errorMessage
                , class "my-4"
                ]
                [ text (texts.httpError err)
                ]


templateCtx : Texts -> IT.TemplateContext
templateCtx texts =
    { dateFormatLong = texts.formatDateLong
    , dateFormatShort = texts.formatDateShort
    , directionLabel = \_ -> ""
    }
