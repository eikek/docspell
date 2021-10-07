module Comp.UrlCopy exposing (..)

import Comp.Basic as B
import Html exposing (..)
import Html.Attributes exposing (..)
import Html.Events exposing (onClick)
import Ports
import QRCode
import Styles as S
import Svg.Attributes as SvgA


type Msg
    = Print String


update : Msg -> Cmd msg
update msg =
    case msg of
        Print id ->
            Ports.printElement id


initCopy : String -> Cmd msg
initCopy data =
    Ports.initClipboard <| clipboardData data


clipboardData : String -> ( String, String )
clipboardData data =
    ( "share-url", "#button-share-url" )


view : String -> Html Msg
view data =
    let
        ( elementId, buttonId ) =
            clipboardData data

        btnId =
            String.dropLeft 1 buttonId

        printId =
            "print-qr-code"
    in
    div [ class "flex flex-col items-center" ]
        [ div
            [ class S.border
            , class S.qrCode
            , id printId
            ]
            [ qrCodeView data
            ]
        , div
            [ class "flex w-64"
            ]
            [ p
                [ id elementId
                , class "font-mono text-xs py-2 mx-auto break-all"
                ]
                [ text data
                ]
            ]
        , div [ class "flex flex-row mt-1 space-x-2 items-center w-full" ]
            [ B.primaryButton
                { label = "Copy"
                , icon = "fa fa-copy"
                , handler = href "#"
                , disabled = False
                , attrs =
                    [ id btnId
                    , class "flex flex-grow items-center justify-center"
                    , attribute "data-clipboard-target" ("#" ++ elementId)
                    ]
                }
            , B.primaryButton
                { label = "Print"
                , icon = "fa fa-print"
                , handler = onClick (Print printId)
                , disabled = False
                , attrs =
                    [ href "#"
                    , class "flex flex-grow items-center justify-center"
                    ]
                }
            ]
        ]


qrCodeView : String -> Html msg
qrCodeView message =
    QRCode.fromString message
        |> Result.map (QRCode.toSvg [ SvgA.class "w-64 h-64" ])
        |> Result.withDefault
            (text "Error generating QR code")
