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
    , getRef
    , setTypeGotify
    , setTypeHttp
    , setTypeMail
    , setTypeMatrix
    )

import Api.Model.NotificationChannelRef exposing (NotificationChannelRef)
import Api.Model.NotificationGotify exposing (NotificationGotify)
import Api.Model.NotificationHttp exposing (NotificationHttp)
import Api.Model.NotificationMail exposing (NotificationMail)
import Api.Model.NotificationMatrix exposing (NotificationMatrix)
import Data.ChannelType exposing (ChannelType)
import Json.Decode as D
import Json.Encode as E


type NotificationChannel
    = Matrix NotificationMatrix
    | Mail NotificationMail
    | Gotify NotificationGotify
    | Http NotificationHttp


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
        ]


fold :
    (NotificationMail -> a)
    -> (NotificationGotify -> a)
    -> (NotificationMatrix -> a)
    -> (NotificationHttp -> a)
    -> NotificationChannel
    -> a
fold fa fb fc fd channel =
    case channel of
        Mail ch ->
            fa ch

        Gotify ch ->
            fb ch

        Matrix ch ->
            fc ch

        Http ch ->
            fd ch


encode : NotificationChannel -> E.Value
encode channel =
    fold
        Api.Model.NotificationMail.encode
        Api.Model.NotificationGotify.encode
        Api.Model.NotificationMatrix.encode
        Api.Model.NotificationHttp.encode
        channel


channelType : NotificationChannel -> Maybe ChannelType
channelType ch =
    fold
        (.channelType >> Data.ChannelType.fromString)
        (.channelType >> Data.ChannelType.fromString)
        (.channelType >> Data.ChannelType.fromString)
        (.channelType >> Data.ChannelType.fromString)
        ch


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


getRef : NotificationChannel -> NotificationChannelRef
getRef channel =
    fold
        (\c -> NotificationChannelRef c.id c.channelType c.name)
        (\c -> NotificationChannelRef c.id c.channelType c.name)
        (\c -> NotificationChannelRef c.id c.channelType c.name)
        (\c -> NotificationChannelRef c.id c.channelType c.name)
        channel
