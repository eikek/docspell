port module Ports exposing (..)

import Api.Model.AuthResult exposing (AuthResult)

port initElements: () -> Cmd msg

port setAccount: AuthResult -> Cmd msg
port removeAccount: String -> Cmd msg
