port module Ports exposing
    ( removeAccount
    , setAccount
    , setAllProgress
    , setProgress
    )

import Api.Model.AuthResult exposing (AuthResult)


port setAccount : AuthResult -> Cmd msg


port removeAccount : () -> Cmd msg


port setProgress : ( String, Int ) -> Cmd msg


port setAllProgress : ( String, Int ) -> Cmd msg
