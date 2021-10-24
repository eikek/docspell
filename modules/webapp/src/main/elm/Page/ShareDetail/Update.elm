{-
   Copyright 2020 Eike K. & Contributors

   SPDX-License-Identifier: AGPL-3.0-or-later
-}


module Page.ShareDetail.Update exposing (update)

import Api
import Comp.SharePasswordForm
import Comp.UrlCopy
import Data.Flags exposing (Flags)
import Page exposing (Page(..))
import Page.ShareDetail.Data exposing (..)


update : String -> String -> Flags -> Msg -> Model -> ( Model, Cmd Msg )
update shareId itemId flags msg model =
    case msg of
        VerifyResp (Ok res) ->
            if res.success then
                ( { model
                    | pageError = PageErrorNone
                    , viewMode = ViewLoading
                    , verifyResult = res
                  }
                , Api.itemDetailShare flags res.token itemId GetItemResp
                )

            else if res.passwordRequired then
                ( { model
                    | pageError = PageErrorNone
                    , viewMode = ViewPassword
                  }
                , Cmd.none
                )

            else
                ( { model | pageError = PageErrorAuthFail }
                , Cmd.none
                )

        VerifyResp (Err err) ->
            ( { model | pageError = PageErrorHttp err }, Cmd.none )

        GetItemResp (Ok item) ->
            let
                url =
                    Page.pageToString (ShareDetailPage shareId itemId)
            in
            ( { model
                | item = item
                , viewMode = ViewNormal
                , pageError = PageErrorNone
              }
            , Comp.UrlCopy.initCopy url
            )

        GetItemResp (Err err) ->
            ( { model | viewMode = ViewNormal, pageError = PageErrorHttp err }, Cmd.none )

        PasswordMsg lmsg ->
            let
                ( m, c, res ) =
                    Comp.SharePasswordForm.update shareId flags lmsg model.passwordModel
            in
            case res of
                Just verifyResult ->
                    update shareId
                        itemId
                        flags
                        (VerifyResp (Ok verifyResult))
                        model

                Nothing ->
                    ( { model | passwordModel = m }, Cmd.map PasswordMsg c )

        SelectActiveAttachment pos ->
            ( { model
                | visibleAttach = pos
                , attachMenuOpen = False
              }
            , Cmd.none
            )

        ToggleSelectAttach ->
            ( { model | attachMenuOpen = not model.attachMenuOpen }, Cmd.none )

        UrlCopyMsg lm ->
            let
                cmd =
                    Comp.UrlCopy.update lm
            in
            ( model, cmd )
