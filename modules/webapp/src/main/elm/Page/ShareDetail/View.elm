module Page.ShareDetail.View exposing (viewContent, viewSidebar)

import Api
import Api.Model.VersionInfo exposing (VersionInfo)
import Comp.Basic as B
import Comp.SharePasswordForm
import Data.Flags exposing (Flags)
import Data.Icons as Icons
import Data.ItemTemplate as IT exposing (ItemTemplate)
import Data.UiSettings exposing (UiSettings)
import Html exposing (..)
import Html.Attributes exposing (..)
import Messages.Page.ShareDetail exposing (Texts)
import Page exposing (Page(..))
import Page.ShareDetail.Data exposing (..)
import Styles as S
import Util.CustomField
import Util.Item


viewSidebar : Texts -> Bool -> Flags -> UiSettings -> Model -> Html Msg
viewSidebar texts visible flags settings model =
    div
        [ id "sidebar"
        , class "hidden"
        ]
        []


viewContent : Texts -> Flags -> UiSettings -> VersionInfo -> String -> String -> Model -> Html Msg
viewContent texts flags uiSettings versionInfo shareId itemId model =
    case model.viewMode of
        ViewLoading ->
            div
                [ id "content"
                , class "h-full w-full flex flex-col text-5xl"
                , class S.content
                ]
                [ B.loadingDimmer
                    { active = model.pageError == PageErrorNone
                    , label = ""
                    }
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
        , div [ class "flex flex-col sm:flex-row sm:space-x-4 relative h-full" ]
            [ itemData texts model
            , itemPreview texts flags settings model
            ]
        ]


itemData : Texts -> Model -> Html Msg
itemData texts model =
    let
        boxStyle =
            "mb-4 sm:mb-6 max-w-sm"

        headerStyle =
            "py-2 bg-blue-50 hover:bg-blue-100 dark:bg-bluegray-700 dark:hover:bg-opacity-100 dark:hover:bg-bluegray-600 text-lg font-medium rounded-lg"

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
    div [ class "flex flex-col pr-2 sm:w-1/3" ]
        [ div [ class boxStyle ]
            [ div [ class headerStyle ]
                [ Icons.dateIcon2 "mr-2 ml-2"
                , text "Date"
                ]
            , div [ class "text-lg ml-2" ]
                [ Util.Item.toItemLight model.item
                    |> IT.render IT.dateLong (templateCtx texts)
                    |> text
                ]
            ]
        , div [ class boxStyle ]
            [ div [ class headerStyle ]
                [ Icons.tagsIcon2 "mr-2 ml-2"
                , text "Tags & Fields"
                ]
            , div [ class "flex flex-row items-center flex-wrap font-medium my-1" ]
                (List.map showTag model.item.tags ++ List.map showField model.item.customfields)
            ]
        , div [ class boxStyle ]
            [ div [ class headerStyle ]
                [ Icons.correspondentIcon2 "mr-2 ml-2"
                , text "Correspondent"
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
                , text "Concerning"
                ]
            , div [ class "text-lg ml-2" ]
                [ Util.Item.toItemLight model.item
                    |> IT.render IT.concerning (templateCtx texts)
                    |> text
                ]
            ]
        ]


itemPreview : Texts -> Flags -> UiSettings -> Model -> Html Msg
itemPreview texts flags settings model =
    let
        id =
            List.head model.item.attachments
                |> Maybe.map .id
                |> Maybe.withDefault ""
    in
    div
        [ class "flex flex-grow"
        , style "min-height" "500px"
        ]
        [ embed
            [ src (Data.UiSettings.pdfUrl settings flags (Api.shareFileURL id))
            , class " h-full w-full mx-0 py-0"
            ]
            []
        ]


itemHead : Texts -> String -> Model -> Html Msg
itemHead texts shareId model =
    div [ class "flex flex-col sm:flex-row" ]
        [ div [ class "flex flex-grow items-center" ]
            [ h1 [ class S.header1 ]
                [ text model.item.name
                ]
            ]
        , div [ class "flex flex-row items-center justify-end mb-2 sm:mb-0" ]
            [ B.secondaryBasicButton
                { label = "Close"
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


templateCtx : Texts -> IT.TemplateContext
templateCtx texts =
    { dateFormatLong = texts.formatDateLong
    , dateFormatShort = texts.formatDateShort
    , directionLabel = \_ -> ""
    }
