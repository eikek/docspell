{-
   Copyright 2020 Eike K. & Contributors

   SPDX-License-Identifier: AGPL-3.0-or-later
-}


module Comp.ChannelForm exposing (..)

import Api.Model.NotificationGotify exposing (NotificationGotify)
import Api.Model.NotificationHttp exposing (NotificationHttp)
import Api.Model.NotificationMail exposing (NotificationMail)
import Api.Model.NotificationMatrix exposing (NotificationMatrix)
import Comp.NotificationGotifyForm
import Comp.NotificationHttpForm
import Comp.NotificationMailForm
import Comp.NotificationMatrixForm
import Data.ChannelType exposing (ChannelType)
import Data.Flags exposing (Flags)
import Data.NotificationChannel exposing (NotificationChannel)
import Data.UiSettings exposing (UiSettings)
import Html exposing (..)
import Html.Attributes exposing (..)
import Messages.Comp.ChannelForm exposing (Texts)


type alias MatrixModel =
    { form : Comp.NotificationMatrixForm.Model
    , value : Maybe NotificationMatrix
    }


type alias GotifyModel =
    { form : Comp.NotificationGotifyForm.Model
    , value : Maybe NotificationGotify
    }


type alias MailModel =
    { form : Comp.NotificationMailForm.Model
    , value : Maybe NotificationMail
    }


type alias HttpModel =
    { form : Comp.NotificationHttpForm.Model
    , value : Maybe NotificationHttp
    }


type Model
    = Matrix MatrixModel
    | Gotify GotifyModel
    | Mail MailModel
    | Http HttpModel


type Msg
    = MatrixMsg Comp.NotificationMatrixForm.Msg
    | GotifyMsg Comp.NotificationGotifyForm.Msg
    | MailMsg Comp.NotificationMailForm.Msg
    | HttpMsg Comp.NotificationHttpForm.Msg


init : Flags -> ChannelType -> ( Model, Cmd Msg )
init flags ct =
    case ct of
        Data.ChannelType.Matrix ->
            ( Matrix
                { form = Comp.NotificationMatrixForm.init
                , value = Nothing
                }
            , Cmd.none
            )

        Data.ChannelType.Gotify ->
            ( Gotify
                { form = Comp.NotificationGotifyForm.init
                , value = Nothing
                }
            , Cmd.none
            )

        Data.ChannelType.Mail ->
            let
                ( mm, mc ) =
                    Comp.NotificationMailForm.init flags
            in
            ( Mail
                { form = mm
                , value = Nothing
                }
            , Cmd.map MailMsg mc
            )

        Data.ChannelType.Http ->
            ( Http
                { form = Comp.NotificationHttpForm.init
                , value = Nothing
                }
            , Cmd.none
            )


initWith : Flags -> NotificationChannel -> ( Model, Cmd Msg )
initWith flags channel =
    case channel of
        Data.NotificationChannel.Matrix m ->
            ( Matrix
                { form = Comp.NotificationMatrixForm.initWith m
                , value = Just m
                }
            , Cmd.none
            )

        Data.NotificationChannel.Gotify m ->
            ( Gotify
                { form = Comp.NotificationGotifyForm.initWith m
                , value = Just m
                }
            , Cmd.none
            )

        Data.NotificationChannel.Mail m ->
            let
                ( mm, mc ) =
                    Comp.NotificationMailForm.initWith flags m
            in
            ( Mail
                { form = mm
                , value = Just m
                }
            , Cmd.map MailMsg mc
            )

        Data.NotificationChannel.Http m ->
            ( Http
                { form = Comp.NotificationHttpForm.initWith m
                , value = Just m
                }
            , Cmd.none
            )


channelType : Model -> ChannelType
channelType model =
    case model of
        Matrix _ ->
            Data.ChannelType.Matrix

        Gotify _ ->
            Data.ChannelType.Gotify

        Mail _ ->
            Data.ChannelType.Mail

        Http _ ->
            Data.ChannelType.Http


getChannel : Model -> Maybe NotificationChannel
getChannel model =
    case model of
        Matrix mm ->
            Maybe.map Data.NotificationChannel.Matrix mm.value

        Gotify mm ->
            Maybe.map Data.NotificationChannel.Gotify mm.value

        Mail mm ->
            Maybe.map Data.NotificationChannel.Mail mm.value

        Http mm ->
            Maybe.map Data.NotificationChannel.Http mm.value



--- Update


update : Flags -> Msg -> Model -> ( Model, Cmd Msg )
update flags msg model =
    case msg of
        MatrixMsg lm ->
            case model of
                Matrix matrix ->
                    let
                        ( mm, mv ) =
                            Comp.NotificationMatrixForm.update lm matrix.form
                    in
                    ( Matrix { form = mm, value = mv }, Cmd.none )

                _ ->
                    ( model, Cmd.none )

        GotifyMsg lm ->
            case model of
                Gotify gotify ->
                    let
                        ( mm, mv ) =
                            Comp.NotificationGotifyForm.update lm gotify.form
                    in
                    ( Gotify { form = mm, value = mv }, Cmd.none )

                _ ->
                    ( model, Cmd.none )

        MailMsg lm ->
            case model of
                Mail mail ->
                    let
                        ( mm, mc, mv ) =
                            Comp.NotificationMailForm.update flags lm mail.form
                    in
                    ( Mail { form = mm, value = mv }, Cmd.map MailMsg mc )

                _ ->
                    ( model, Cmd.none )

        HttpMsg lm ->
            case model of
                Http http ->
                    let
                        ( mm, mv ) =
                            Comp.NotificationHttpForm.update lm http.form
                    in
                    ( Http { form = mm, value = mv }, Cmd.none )

                _ ->
                    ( model, Cmd.none )



--- View


view : Texts -> UiSettings -> Model -> Html Msg
view texts settings model =
    case model of
        Matrix m ->
            Html.map MatrixMsg
                (Comp.NotificationMatrixForm.view texts.matrixForm m.form)

        Gotify m ->
            Html.map GotifyMsg
                (Comp.NotificationGotifyForm.view texts.gotifyForm m.form)

        Mail m ->
            Html.map MailMsg
                (Comp.NotificationMailForm.view texts.mailForm settings m.form)

        Http m ->
            Html.map HttpMsg
                (Comp.NotificationHttpForm.view texts.httpForm m.form)
