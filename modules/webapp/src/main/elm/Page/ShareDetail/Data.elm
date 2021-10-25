{-
   Copyright 2020 Eike K. & Contributors

   SPDX-License-Identifier: AGPL-3.0-or-later
-}


module Page.ShareDetail.Data exposing (Model, Msg(..), PageError(..), ViewMode(..), init)

import Api
import Api.Model.ItemDetail exposing (ItemDetail)
import Api.Model.ShareSecret exposing (ShareSecret)
import Api.Model.ShareVerifyResult exposing (ShareVerifyResult)
import Comp.SharePasswordForm
import Comp.UrlCopy
import Data.Flags exposing (Flags)
import Http


type ViewMode
    = ViewNormal
    | ViewPassword
    | ViewLoading


type PageError
    = PageErrorNone
    | PageErrorHttp Http.Error
    | PageErrorAuthFail


type alias Model =
    { item : ItemDetail
    , verifyResult : ShareVerifyResult
    , passwordModel : Comp.SharePasswordForm.Model
    , viewMode : ViewMode
    , pageError : PageError
    , attachMenuOpen : Bool
    , visibleAttach : Int
    }


type Msg
    = VerifyResp (Result Http.Error ShareVerifyResult)
    | GetItemResp (Result Http.Error ItemDetail)
    | PasswordMsg Comp.SharePasswordForm.Msg
    | SelectActiveAttachment Int
    | ToggleSelectAttach
    | UrlCopyMsg Comp.UrlCopy.Msg


emptyModel : ViewMode -> Model
emptyModel vm =
    { item = Api.Model.ItemDetail.empty
    , verifyResult = Api.Model.ShareVerifyResult.empty
    , passwordModel = Comp.SharePasswordForm.init
    , viewMode = vm
    , pageError = PageErrorNone
    , attachMenuOpen = False
    , visibleAttach = 0
    }


init : Maybe ( String, String ) -> Flags -> ( Model, Cmd Msg )
init mids flags =
    case mids of
        Just ( shareId, itemId ) ->
            ( emptyModel ViewLoading
            , Api.verifyShare flags (ShareSecret shareId Nothing) VerifyResp
            )

        Nothing ->
            ( emptyModel ViewLoading, Cmd.none )
