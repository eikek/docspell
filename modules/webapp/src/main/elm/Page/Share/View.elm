{-
   Copyright 2020 Eike K. & Contributors

   SPDX-License-Identifier: AGPL-3.0-or-later
-}


module Page.Share.View exposing (viewContent, viewSidebar)

import Api.Model.VersionInfo exposing (VersionInfo)
import Comp.Basic as B
import Comp.SharePasswordForm
import Data.Flags exposing (Flags)
import Data.Items
import Data.UiSettings exposing (UiSettings)
import Html exposing (..)
import Html.Attributes exposing (..)
import Html.Events exposing (onInput, onSubmit)
import Messages.Page.Share exposing (Texts)
import Page.Share.Data exposing (..)
import Page.Share.Menubar as Menubar
import Page.Share.Results as Results
import Page.Share.Sidebar as Sidebar
import Styles as S


viewSidebar : Texts -> Bool -> Flags -> UiSettings -> Model -> Html Msg
viewSidebar texts visible flags settings model =
    div
        [ id "sidebar"
        , class S.sidebar
        , class S.sidebarBg
        , classList [ ( "hidden", not visible || model.mode /= ModeShare ) ]
        ]
        [ Sidebar.view texts flags settings model
        ]


viewContent : Texts -> Flags -> VersionInfo -> UiSettings -> String -> Model -> Html Msg
viewContent texts flags versionInfo uiSettings shareId model =
    case model.mode of
        ModeInitial ->
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

        ModePassword ->
            passwordContent texts flags versionInfo model

        ModeShare ->
            mainContent texts flags uiSettings shareId model



--- Helpers


mainContent : Texts -> Flags -> UiSettings -> String -> Model -> Html Msg
mainContent texts _ settings shareId model =
    div
        [ id "content"
        , class "h-full flex flex-col"
        , class S.content
        ]
        [ h1
            [ class S.header1
            , classList [ ( "hidden", model.verifyResult.name == Nothing ) ]
            ]
            [ text <| Maybe.withDefault "" model.verifyResult.name
            ]
        , Menubar.view texts model
        , Results.view texts settings shareId model
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
