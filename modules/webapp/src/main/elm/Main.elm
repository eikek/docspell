module Main exposing (init, main)

import Api
import App.Data exposing (..)
import App.Update exposing (..)
import App.View exposing (..)
import Browser exposing (Document)
import Browser.Navigation exposing (Key)
import Data.Flags exposing (Flags)
import Data.UiSettings
import Html exposing (..)
import Html.Attributes exposing (..)
import Html.Events exposing (..)
import Page
import Ports
import Url exposing (Url)



-- MAIN


main : Program Flags Model Msg
main =
    Browser.application
        { init = init
        , view = viewDoc
        , update = update
        , subscriptions = subscriptions
        , onUrlRequest = NavRequest
        , onUrlChange = NavChange
        }



-- MODEL


init : Flags -> Url -> Key -> ( Model, Cmd Msg )
init flags url key =
    let
        ( im, ic ) =
            App.Data.init key url flags Data.UiSettings.defaults

        page =
            checkPage flags im.page

        ( m, cmd, s ) =
            if im.page == page then
                App.Update.initPage im page

            else
                ( im, Page.goto page, Sub.none )

        sessionCheck =
            case m.flags.account of
                Just _ ->
                    Api.loginSession flags SessionCheckResp

                Nothing ->
                    Cmd.none
    in
    ( { m | subs = s }
    , Cmd.batch
        [ cmd
        , ic
        , Api.versionInfo flags VersionResp
        , sessionCheck
        , Ports.getUiSettings flags
        ]
    )


viewDoc : Model -> Document Msg
viewDoc model =
    { title = model.flags.config.appName ++ ": " ++ Page.pageName model.page
    , body = [ view model ]
    }



-- SUBSCRIPTIONS


subscriptions : Model -> Sub Msg
subscriptions model =
    Sub.batch
        [ model.subs
        , Ports.loadUiSettings GetUiSettings
        ]
