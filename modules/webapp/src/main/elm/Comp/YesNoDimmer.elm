module Comp.YesNoDimmer exposing
    ( Model
    , Msg(..)
    , Settings
    , activate
    , defaultSettings
    , defaultSettings2
    , disable
    , emptyModel
    , initActive
    , initInactive
    , update
    , view
    , view2
    , viewN
    )

import Html exposing (..)
import Html.Attributes exposing (..)
import Html.Events exposing (onClick)
import Styles as S


type alias Model =
    { active : Bool
    }


emptyModel : Model
emptyModel =
    { active = False
    }


initInactive : Model
initInactive =
    { active = False
    }


initActive : Model
initActive =
    { active = True
    }


type Msg
    = Activate
    | Disable
    | ConfirmDelete


type alias Settings =
    { message : String
    , headerIcon : String
    , headerClass : String
    , confirmButton : String
    , cancelButton : String
    , extraClass : String
    }


defaultSettings : Settings
defaultSettings =
    { message = "Delete this item permanently?"
    , headerIcon = "exclamation icon"
    , headerClass = "ui inverted icon header"
    , confirmButton = "Yes, do it!"
    , cancelButton = "No"
    , extraClass = ""
    }


defaultSettings2 : String -> Settings
defaultSettings2 msg =
    { message = msg
    , headerIcon = "fa fa-exclamation-circle mr-3"
    , headerClass = "text-2xl font-bold text-center w-full"
    , confirmButton = "Yes, do it!"
    , cancelButton = "No"
    , extraClass = ""
    }


activate : Msg
activate =
    Activate


disable : Msg
disable =
    Disable


update : Msg -> Model -> ( Model, Bool )
update msg model =
    case msg of
        Activate ->
            ( { model | active = True }, False )

        Disable ->
            ( { model | active = False }, False )

        ConfirmDelete ->
            ( { model | active = False }, True )


view : Model -> Html Msg
view model =
    view2 True defaultSettings model


view2 : Bool -> Settings -> Model -> Html Msg
view2 active settings model =
    div
        [ classList
            [ ( "ui dimmer", True )
            , ( settings.extraClass, True )
            , ( "active", active && model.active )
            ]
        ]
        [ div [ class "content" ]
            [ h3 [ class settings.headerClass ]
                [ if settings.headerIcon == "" then
                    span [] []

                  else
                    i [ class settings.headerIcon ] []
                , text settings.message
                ]
            ]
        , div [ class "content" ]
            [ div [ class "ui buttons" ]
                [ a [ class "ui primary button", onClick ConfirmDelete, href "#" ]
                    [ text settings.confirmButton
                    ]
                , div [ class "or" ] []
                , a [ class "ui secondary button", onClick Disable, href "#" ]
                    [ text settings.cancelButton
                    ]
                ]
            ]
        ]


viewN : Bool -> Settings -> Model -> Html Msg
viewN active settings model =
    div
        [ class S.dimmer
        , class settings.extraClass
        , classList
            [ ( "hidden", not active || not model.active )
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
                , onClick ConfirmDelete
                ]
                [ text settings.confirmButton
                ]
            , a
                [ class (S.secondaryButton ++ "block font-semibold")
                , href "#"
                , onClick Disable
                ]
                [ text settings.cancelButton
                ]
            ]
        ]
