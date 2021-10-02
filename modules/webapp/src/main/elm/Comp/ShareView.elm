{-
   Copyright 2020 Eike K. & Contributors

   SPDX-License-Identifier: AGPL-3.0-or-later
-}


module Comp.ShareView exposing (ViewSettings, clipboardData, view, viewDefault)

import Api.Model.ShareDetail exposing (ShareDetail)
import Data.Flags exposing (Flags)
import Html exposing (..)
import Html.Attributes exposing (..)
import Messages.Comp.ShareView exposing (Texts)
import QRCode
import Styles as S


type alias ViewSettings =
    { mainClasses : String
    , showAccessData : Bool
    }


view : ViewSettings -> Texts -> Flags -> ShareDetail -> Html msg
view cfg texts flags share =
    if not share.enabled then
        viewDisabled cfg texts share

    else if share.expired then
        viewExpired cfg texts share

    else
        viewActive cfg texts flags share


viewDefault : Texts -> Flags -> ShareDetail -> Html msg
viewDefault =
    view
        { mainClasses = ""
        , showAccessData = True
        }


clipboardData : ShareDetail -> ( String, String )
clipboardData share =
    ( "app-share-" ++ share.id, "#app-share-url-copy-to-clipboard-btn-" ++ share.id )



--- Helper


viewActive : ViewSettings -> Texts -> Flags -> ShareDetail -> Html msg
viewActive cfg texts flags share =
    let
        clipboard =
            clipboardData share

        appUrl =
            flags.config.baseUrl ++ "/app/share/" ++ share.id

        styleUrl =
            "truncate px-2 py-2 border-0 border-t border-b border-r font-mono text-sm my-auto rounded-r border-gray-400 dark:border-bluegray-500"

        infoLine hidden icon label value =
            div
                [ class "flex flex-row items-center"
                , classList [ ( "hidden", hidden ) ]
                ]
                [ div [ class "flex mr-3" ]
                    [ i [ class icon ] []
                    ]
                , div [ class "flex flex-col" ]
                    [ div [ class "-mb-1" ]
                        [ text value
                        ]
                    , div [ class "opacity-50 text-sm" ]
                        [ text label
                        ]
                    ]
                ]
    in
    div
        [ class cfg.mainClasses
        , class "flex flex-col sm:flex-row "
        ]
        [ div [ class "flex" ]
            [ div
                [ class S.border
                , class S.qrCode
                ]
                [ qrCodeView texts appUrl
                ]
            ]
        , div
            [ class "flex flex-col ml-3 pr-2"

            -- hack for the qr code that is 265px
            , style "max-width" "calc(100% - 265px)"
            ]
            [ div [ class "font-medium text-2xl" ]
                [ text <| Maybe.withDefault texts.noName share.name
                ]
            , div [ class "my-2" ]
                [ div [ class "flex flex-row" ]
                    [ a
                        [ class S.secondaryBasicButtonPlain
                        , class "rounded-l border text-sm px-4 py-2"
                        , title texts.copyToClipboard
                        , href "#"
                        , Tuple.second clipboard
                            |> String.dropLeft 1
                            |> id
                        , attribute "data-clipboard-target" ("#" ++ Tuple.first clipboard)
                        ]
                        [ i [ class "fa fa-copy" ] []
                        ]
                    , a
                        [ class S.secondaryBasicButtonPlain
                        , class "px-4 py-2 border-0 border-t border-b border-r text-sm"
                        , href appUrl
                        , target "_blank"
                        , title texts.openInNewTab
                        ]
                        [ i [ class "fa fa-external-link-alt" ] []
                        ]
                    , div
                        [ id (Tuple.first clipboard)
                        , class styleUrl
                        ]
                        [ text appUrl
                        ]
                    ]
                ]
            , div [ class "text-lg flex flex-col" ]
                [ infoLine False "fa fa-calendar" texts.publishUntil (texts.date share.publishUntil)
                , infoLine False
                    (if share.password then
                        "fa fa-lock"

                     else
                        "fa fa-lock-open"
                    )
                    texts.passwordProtected
                    (if share.password then
                        texts.basics.yes

                     else
                        texts.basics.no
                    )
                , infoLine
                    (not cfg.showAccessData)
                    "fa fa-eye"
                    texts.views
                    (String.fromInt share.views)
                , infoLine
                    (not cfg.showAccessData)
                    "fa fa-calendar-check font-thin"
                    texts.lastAccess
                    (Maybe.map texts.date share.lastAccess |> Maybe.withDefault "-")
                ]
            ]
        ]


viewExpired : ViewSettings -> Texts -> ShareDetail -> Html msg
viewExpired cfg texts share =
    div [ class S.warnMessage ]
        [ text texts.expiredInfo ]


viewDisabled : ViewSettings -> Texts -> ShareDetail -> Html msg
viewDisabled cfg texts share =
    div [ class S.warnMessage ]
        [ text texts.disabledInfo ]


qrCodeView : Texts -> String -> Html msg
qrCodeView texts message =
    QRCode.encode message
        |> Result.map QRCode.toSvg
        |> Result.withDefault
            (Html.text texts.qrCodeError)
