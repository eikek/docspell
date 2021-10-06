module Page.ShareDetail.Update exposing (update)

import Api
import Comp.SharePasswordForm
import Data.Flags exposing (Flags)
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
            ( { model
                | item = item
                , viewMode = ViewNormal
                , pageError = PageErrorNone
              }
            , Cmd.none
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
