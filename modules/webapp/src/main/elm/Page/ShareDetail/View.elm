module Page.ShareDetail.View exposing (viewContent, viewSidebar)

import Api.Model.VersionInfo exposing (VersionInfo)
import Comp.Basic as B
import Comp.SharePasswordForm
import Data.Flags exposing (Flags)
import Data.UiSettings exposing (UiSettings)
import Html exposing (..)
import Html.Attributes exposing (..)
import Messages.Page.ShareDetail exposing (Texts)
import Page exposing (Page(..))
import Page.ShareDetail.Data exposing (..)
import Styles as S


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
        , div [ class "flex flex-col sm:flex-row" ]
            [ itemData texts model
            , itemPreview texts flags settings model
            ]
        ]


itemData : Texts -> Model -> Html Msg
itemData texts model =
    div [ class "flex" ]
        []


{-| Using ItemDetail Model to be able to reuse SingleAttachment component
-}
itemPreview : Texts -> Flags -> UiSettings -> Model -> Html Msg
itemPreview texts flags settings model =
    div [ class "flex flex-grow" ]
        []


itemHead : Texts -> String -> Model -> Html Msg
itemHead texts shareId model =
    div [ class "flex flex-col sm:flex-row" ]
        [ div [ class "flex flex-grow items-center" ]
            [ h1 [ class S.header1 ]
                [ text model.item.name
                ]
            ]
        , div [ class "flex flex-row items-center justify-end" ]
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
