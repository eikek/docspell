{-
   Copyright 2020 Eike K. & Contributors

   SPDX-License-Identifier: AGPL-3.0-or-later
-}


module Page.Share.Data exposing (Mode(..), Model, Msg(..), PageError(..), init)

import Api
import Api.Model.ItemLightList exposing (ItemLightList)
import Api.Model.ShareSecret exposing (ShareSecret)
import Api.Model.ShareVerifyResult exposing (ShareVerifyResult)
import Comp.ItemCardList
import Comp.PowerSearchInput
import Comp.SearchMenu
import Data.Flags exposing (Flags)
import Http


type Mode
    = ModeInitial
    | ModePassword
    | ModeShare


type PageError
    = PageErrorNone
    | PageErrorHttp Http.Error
    | PageErrorAuthFail


type alias PasswordModel =
    { password : String
    , passwordFailed : Bool
    }


type alias Model =
    { mode : Mode
    , verifyResult : ShareVerifyResult
    , passwordModel : PasswordModel
    , pageError : PageError
    , items : ItemLightList
    , searchMenuModel : Comp.SearchMenu.Model
    , powerSearchInput : Comp.PowerSearchInput.Model
    , searchInProgress : Bool
    , itemListModel : Comp.ItemCardList.Model
    }


emptyModel : Flags -> Model
emptyModel flags =
    { mode = ModeInitial
    , verifyResult = Api.Model.ShareVerifyResult.empty
    , passwordModel =
        { password = ""
        , passwordFailed = False
        }
    , pageError = PageErrorNone
    , items = Api.Model.ItemLightList.empty
    , searchMenuModel = Comp.SearchMenu.init flags
    , powerSearchInput = Comp.PowerSearchInput.init
    , searchInProgress = False
    , itemListModel = Comp.ItemCardList.init
    }


init : Maybe String -> Flags -> ( Model, Cmd Msg )
init shareId flags =
    case shareId of
        Just id ->
            ( emptyModel flags, Api.verifyShare flags (ShareSecret id Nothing) VerifyResp )

        Nothing ->
            ( emptyModel flags, Cmd.none )


type Msg
    = VerifyResp (Result Http.Error ShareVerifyResult)
    | SearchResp (Result Http.Error ItemLightList)
    | SetPassword String
    | SubmitPassword
    | SearchMenuMsg Comp.SearchMenu.Msg
    | PowerSearchMsg Comp.PowerSearchInput.Msg
    | ResetSearch
    | ItemListMsg Comp.ItemCardList.Msg
