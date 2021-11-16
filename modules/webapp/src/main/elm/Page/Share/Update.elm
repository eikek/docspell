{-
   Copyright 2020 Eike K. & Contributors

   SPDX-License-Identifier: AGPL-3.0-or-later
-}


module Page.Share.Update exposing (UpdateResult, update)

import Api
import Api.Model.ItemQuery
import Comp.ItemCardList
import Comp.LinkTarget exposing (LinkTarget)
import Comp.PowerSearchInput
import Comp.SearchMenu
import Comp.SharePasswordForm
import Data.Flags exposing (Flags)
import Data.ItemQuery as Q
import Data.SearchMode
import Data.UiSettings exposing (UiSettings)
import Page.Share.Data exposing (..)
import Util.Html
import Util.Maybe
import Util.Update


type alias UpdateResult =
    { model : Model
    , cmd : Cmd Msg
    , sub : Sub Msg
    }


update : Flags -> UiSettings -> String -> Msg -> Model -> UpdateResult
update flags settings shareId msg model =
    case msg of
        VerifyResp (Ok res) ->
            if res.success then
                let
                    eq =
                        Api.Model.ItemQuery.empty

                    iq =
                        { eq | withDetails = Just True }
                in
                noSub
                    ( { model
                        | pageError = PageErrorNone
                        , mode = ModeShare
                        , verifyResult = res
                        , searchInProgress = True
                      }
                    , makeSearchCmd flags model
                    )

            else if res.passwordRequired then
                noSub
                    ( { model
                        | pageError = PageErrorNone
                        , mode = ModePassword
                      }
                    , Cmd.none
                    )

            else
                noSub
                    ( { model | pageError = PageErrorAuthFail }
                    , Cmd.none
                    )

        VerifyResp (Err err) ->
            noSub ( { model | pageError = PageErrorHttp err }, Cmd.none )

        SearchResp (Ok list) ->
            update flags
                settings
                shareId
                (ItemListMsg (Comp.ItemCardList.SetResults list))
                { model | searchInProgress = False, pageError = PageErrorNone }

        SearchResp (Err err) ->
            noSub ( { model | pageError = PageErrorHttp err, searchInProgress = False }, Cmd.none )

        StatsResp (Ok stats) ->
            update flags
                settings
                shareId
                (SearchMenuMsg (Comp.SearchMenu.setFromStats stats))
                model

        StatsResp (Err err) ->
            noSub ( { model | pageError = PageErrorHttp err }, Cmd.none )

        PasswordMsg lmsg ->
            let
                ( m, c, res ) =
                    Comp.SharePasswordForm.update shareId flags lmsg model.passwordModel
            in
            case res of
                Just verifyResult ->
                    update flags
                        settings
                        shareId
                        (VerifyResp (Ok verifyResult))
                        model

                Nothing ->
                    noSub ( { model | passwordModel = m }, Cmd.map PasswordMsg c )

        SearchMenuMsg lm ->
            let
                res =
                    Comp.SearchMenu.update flags settings lm model.searchMenuModel

                nextModel =
                    { model | searchMenuModel = res.model }

                ( initSearch, searchCmd ) =
                    if res.stateChange && not model.searchInProgress then
                        ( True, makeSearchCmd flags nextModel )

                    else
                        ( False, Cmd.none )
            in
            noSub
                ( { nextModel | searchInProgress = initSearch }
                , Cmd.batch [ Cmd.map SearchMenuMsg res.cmd, searchCmd ]
                )

        PowerSearchMsg lm ->
            let
                res =
                    Comp.PowerSearchInput.update lm model.powerSearchInput

                nextModel =
                    { model | powerSearchInput = res.model }

                ( initSearch, searchCmd ) =
                    case res.action of
                        Comp.PowerSearchInput.NoAction ->
                            ( False, Cmd.none )

                        Comp.PowerSearchInput.SubmitSearch ->
                            ( True, makeSearchCmd flags nextModel )
            in
            { model = { nextModel | searchInProgress = initSearch }
            , cmd = Cmd.batch [ Cmd.map PowerSearchMsg res.cmd, searchCmd ]
            , sub = Sub.map PowerSearchMsg res.subs
            }

        ResetSearch ->
            let
                nm =
                    { model
                        | powerSearchInput = Comp.PowerSearchInput.init
                        , contentSearch = Nothing
                        , pageError = PageErrorNone
                    }
            in
            update flags settings shareId (SearchMenuMsg Comp.SearchMenu.ResetForm) nm

        ItemListMsg lm ->
            let
                ( im, ic, linkTarget ) =
                    Comp.ItemCardList.update flags lm model.itemListModel

                searchMsg =
                    Maybe.map Util.Update.cmdUnit (linkTargetMsg linkTarget)
                        |> Maybe.withDefault Cmd.none
            in
            noSub
                ( { model | itemListModel = im }
                , Cmd.batch [ Cmd.map ItemListMsg ic, searchMsg ]
                )

        ToggleSearchBar ->
            noSub
                ( { model
                    | searchMode =
                        case model.searchMode of
                            SearchBarContent ->
                                SearchBarNormal

                            SearchBarNormal ->
                                SearchBarContent
                  }
                , Cmd.none
                )

        SetContentSearch q ->
            noSub ( { model | contentSearch = Util.Maybe.fromString q }, Cmd.none )

        ContentSearchKey (Just Util.Html.Enter) ->
            noSub ( model, makeSearchCmd flags model )

        ContentSearchKey _ ->
            noSub ( model, Cmd.none )


noSub : ( Model, Cmd Msg ) -> UpdateResult
noSub ( m, c ) =
    UpdateResult m c Sub.none


makeSearchCmd : Flags -> Model -> Cmd Msg
makeSearchCmd flags model =
    let
        xq =
            Q.and
                [ Comp.SearchMenu.getItemQuery model.searchMenuModel
                , Maybe.map Q.Fragment <|
                    case model.searchMode of
                        SearchBarNormal ->
                            model.powerSearchInput.input

                        SearchBarContent ->
                            if flags.config.fullTextSearchEnabled then
                                Maybe.map (Q.Contents >> Q.render) model.contentSearch

                            else
                                Maybe.map (Q.AllNames >> Q.render) model.contentSearch
                ]

        request mq =
            { offset = Nothing
            , limit = Nothing
            , withDetails = Just True
            , query = Q.renderMaybe mq
            , searchMode = Just (Data.SearchMode.asString Data.SearchMode.Normal)
            }

        searchCmd =
            Api.searchShare flags model.verifyResult.token (request xq) SearchResp

        statsCmd =
            Api.searchShareStats flags model.verifyResult.token (request xq) StatsResp
    in
    Cmd.batch [ searchCmd, statsCmd ]


linkTargetMsg : LinkTarget -> Maybe Msg
linkTargetMsg linkTarget =
    Maybe.map SearchMenuMsg (Comp.SearchMenu.linkTargetMsg linkTarget)
