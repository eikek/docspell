{-
   Copyright 2020 Docspell Contributors

   SPDX-License-Identifier: GPL-3.0-or-later
-}


module Comp.ItemDetail.ShowQrCode exposing (UrlId(..), qrCodeElementId, view, view1)

import Api
import Comp.Basic as B
import Comp.ItemDetail.Model exposing (Model, Msg(..), isShowQrAttach, isShowQrItem)
import Comp.MenuBar as MB
import Data.Flags exposing (Flags)
import Html exposing (..)
import Html.Attributes exposing (..)
import Html.Events exposing (onClick)
import QRCode
import Styles as S


view : Flags -> String -> Model -> UrlId -> Html Msg
view flags classes model urlId =
    case urlId of
        Attach _ ->
            if isShowQrAttach model.showQrModel then
                view1 flags classes urlId

            else
                span [ class "hidden" ] []

        Item _ ->
            if isShowQrItem model.showQrModel then
                view1 flags classes urlId

            else
                span [ class "hidden" ] []


view1 : Flags -> String -> UrlId -> Html Msg
view1 flags classes urlId =
    let
        docUrl =
            case urlId of
                Attach str ->
                    flags.config.baseUrl ++ Api.fileURL str

                Item str ->
                    flags.config.baseUrl ++ "/app/item/" ++ str

        elementId =
            qrCodeElementId urlId

        toggleShowQr =
            case urlId of
                Attach id ->
                    ToggleShowQrAttach id

                Item id ->
                    ToggleShowQrItem id
    in
    div
        [ class "flex flex-col py-2 px-2 items-center"
        , class classes
        ]
        [ MB.view
            { start =
                [ MB.PrimaryButton
                    { tagger = PrintElement elementId
                    , title = "Print this QR code"
                    , icon = Just "fa fa-print"
                    , label = "Print"
                    }
                ]
            , end =
                [ MB.SecondaryButton
                    { tagger = toggleShowQr
                    , title = "Close"
                    , icon = Just "fa fa-times"
                    , label = "Close"
                    }
                ]
            , rootClasses = "w-full mt-2 mb-4"
            }
        , div [ class "flex flex-col sm:flex-row sm:space-x-2" ]
            [ div
                [ class S.border
                , class S.qrCode
                , id elementId
                ]
                [ qrCodeView docUrl
                ]
            ]
        ]


qrCodeElementId : UrlId -> String
qrCodeElementId urlId =
    case urlId of
        Attach str ->
            "qr-attach-" ++ str

        Item str ->
            "qr-item-" ++ str


type UrlId
    = Attach String
    | Item String


qrCodeView : String -> Html msg
qrCodeView message =
    QRCode.encode message
        |> Result.map QRCode.toSvg
        |> Result.withDefault
            (text "Error generating QR code")
