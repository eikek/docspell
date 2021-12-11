{-
   Copyright 2020 Eike K. & Contributors

   SPDX-License-Identifier: AGPL-3.0-or-later
-}


module Data.NotificationChannel exposing
    ( NotificationChannel(..)
    , asString
    , channelType
    , decoder
    , empty
    , encode
    , setTypeGotify
    , setTypeHttp
    , setTypeMail
    , setTypeMatrix
    )

import Api.Model.NotificationGotify exposing (NotificationGotify)
import Api.Model.NotificationHttp exposing (NotificationHttp)
import Api.Model.NotificationMail exposing (NotificationMail)
import Api.Model.NotificationMatrix exposing (NotificationMatrix)
import Data.ChannelRef exposing (ChannelRef)
import Data.ChannelType exposing (ChannelType)
import Json.Decode as D
import Json.Encode as E


type NotificationChannel
    = Matrix NotificationMatrix
    | Mail NotificationMail
    | Gotify NotificationGotify
    | Http NotificationHttp
    | Ref ChannelRef


empty : ChannelType -> NotificationChannel
empty ct =
    let
        set =
            setType ct
    in
    case ct of
        Data.ChannelType.Mail ->
            Mail <| set Api.Model.NotificationMail.empty

        Data.ChannelType.Matrix ->
            Matrix <| set Api.Model.NotificationMatrix.empty

        Data.ChannelType.Gotify ->
            Gotify <| set Api.Model.NotificationGotify.empty

        Data.ChannelType.Http ->
            Http <| set Api.Model.NotificationHttp.empty


setType ct rec =
    { rec | channelType = Data.ChannelType.asString ct }


setTypeHttp : NotificationHttp -> NotificationHttp
setTypeHttp h =
    setType Data.ChannelType.Http h


setTypeMail : NotificationMail -> NotificationMail
setTypeMail h =
    setType Data.ChannelType.Mail h


setTypeMatrix : NotificationMatrix -> NotificationMatrix
setTypeMatrix h =
    setType Data.ChannelType.Matrix h


setTypeGotify : NotificationGotify -> NotificationGotify
setTypeGotify h =
    setType Data.ChannelType.Gotify h


decoder : D.Decoder NotificationChannel
decoder =
    D.oneOf
        [ D.map Gotify Api.Model.NotificationGotify.decoder
        , D.map Mail Api.Model.NotificationMail.decoder
        , D.map Matrix Api.Model.NotificationMatrix.decoder
        , D.map Http Api.Model.NotificationHttp.decoder
        , D.map Ref Data.ChannelRef.decoder
        ]


encode : NotificationChannel -> E.Value
encode channel =
    case channel of
        Matrix ch ->
            Api.Model.NotificationMatrix.encode ch

        Mail ch ->
            Api.Model.NotificationMail.encode ch

        Gotify ch ->
            Api.Model.NotificationGotify.encode ch

        Http ch ->
            Api.Model.NotificationHttp.encode ch

        Ref ch ->
            Data.ChannelRef.encode ch


channelType : NotificationChannel -> Maybe ChannelType
channelType ch =
    case ch of
        Matrix m ->
            Data.ChannelType.fromString m.channelType

        Mail m ->
            Data.ChannelType.fromString m.channelType

        Gotify m ->
            Data.ChannelType.fromString m.channelType

        Http m ->
            Data.ChannelType.fromString m.channelType

        Ref m ->
            Just m.channelType


asString : NotificationChannel -> String
asString channel =
    case channel of
        Matrix ch ->
            "Matrix @ " ++ ch.homeServer ++ "(" ++ ch.roomId ++ ")"

        Mail ch ->
            "Mail @ " ++ ch.connection ++ " (" ++ String.join ", " ch.recipients ++ ")"

        Gotify ch ->
            "Gotify @ " ++ ch.url

        Http ch ->
            "Http @ " ++ ch.url

        Ref ch ->
            "Ref(" ++ Data.ChannelType.asString ch.channelType ++ "/" ++ ch.id ++ ")"
