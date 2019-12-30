module Page.ItemDetail.Update exposing (update)

import Api
import Browser.Navigation as Nav
import Comp.ItemDetail
import Data.Flags exposing (Flags)
import Page.ItemDetail.Data exposing (Model, Msg(..))


update : Nav.Key -> Flags -> Maybe String -> Msg -> Model -> ( Model, Cmd Msg )
update key flags next msg model =
    case msg of
        Init id ->
            let
                ( lm, lc ) =
                    Comp.ItemDetail.update key flags next Comp.ItemDetail.Init model.detail
            in
            ( { model | detail = lm }
            , Cmd.batch [ Api.itemDetail flags id ItemResp, Cmd.map ItemDetailMsg lc ]
            )

        ItemDetailMsg lmsg ->
            let
                ( lm, lc ) =
                    Comp.ItemDetail.update key flags next lmsg model.detail
            in
            ( { model | detail = lm }
            , Cmd.map ItemDetailMsg lc
            )

        ItemResp (Ok item) ->
            let
                lmsg =
                    Comp.ItemDetail.SetItem item
            in
            update key flags next (ItemDetailMsg lmsg) model

        ItemResp (Err err) ->
            ( model, Cmd.none )
