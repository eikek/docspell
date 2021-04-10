module Comp.ConfirmModal exposing
    ( Settings
    , defaultSettings
    , view
    )

import Html exposing (..)
import Html.Attributes exposing (..)
import Html.Events exposing (onClick)
import Styles as S


type alias Settings msg =
    { enabled : Bool
    , extraClass : String
    , headerIcon : String
    , headerClass : String
    , confirmText : String
    , cancelText : String
    , message : String
    , confirm : msg
    , cancel : msg
    }


defaultSettings : msg -> msg -> String -> String -> String -> Settings msg
defaultSettings confirm cancel okLabel cancelLabel confirmMsg =
    { enabled = True
    , extraClass = ""
    , headerIcon = "fa fa-exclamation-circle mr-3"
    , headerClass = "text-2xl font-bold text-center w-full"
    , confirmText = okLabel
    , cancelText = cancelLabel
    , message = confirmMsg
    , confirm = confirm
    , cancel = cancel
    }


view : Settings msg -> Html msg
view settings =
    div
        [ class S.dimmer
        , class settings.extraClass
        , classList
            [ ( "hidden", not settings.enabled )
            ]
        ]
        [ div [ class settings.headerClass ]
            [ i
                [ class settings.headerIcon
                , class "text-gray-200 font-semibold"
                , classList [ ( "hidden", settings.headerClass == "" ) ]
                ]
                []
            , span [ class "text-gray-200 font-semibold" ]
                [ text settings.message
                ]
            ]
        , div [ class "flex flex-row space-x-2 text-xs mt-2" ]
            [ a
                [ class (S.primaryButton ++ "block font-semibold")
                , href "#"
                , onClick settings.confirm
                ]
                [ text settings.confirmText
                ]
            , a
                [ class (S.secondaryButton ++ "block font-semibold")
                , href "#"
                , onClick settings.cancel
                ]
                [ text settings.cancelText
                ]
            ]
        ]
