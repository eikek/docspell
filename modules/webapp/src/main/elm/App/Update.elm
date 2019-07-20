module App.Update exposing (update, initPage)

import Api
import Ports
import Browser exposing (UrlRequest(..))
import Browser.Navigation as Nav
import Url
import Data.Flags
import App.Data exposing (..)
import Page exposing (Page(..))
import Page.Home.Data
import Page.Home.Update
import Page.Login.Data
import Page.Login.Update

update: Msg -> Model -> (Model, Cmd Msg)
update msg model =
    case msg of
        HomeMsg lm ->
            updateHome lm model

        LoginMsg lm ->
            updateLogin lm model

        SetPage p ->
            ( {model | page = p }
            , Cmd.none
            )

        VersionResp (Ok info) ->
            ({model|version = info}, Cmd.none)

        VersionResp (Err err) ->
            (model, Cmd.none)

        Logout ->
            (model, Api.logout model.flags LogoutResp)
        LogoutResp _ ->
            ({model|loginModel = Page.Login.Data.empty}, Ports.removeAccount (Page.pageToString HomePage))
        SessionCheckResp res ->
            case res of
                Ok lr ->
                    let
                        newFlags = Data.Flags.withAccount model.flags lr
                        refresh = Api.refreshSession newFlags SessionCheckResp
                    in
                        if (lr.success) then ({model|flags = newFlags}, refresh)
                        else  (model, Ports.removeAccount (Page.pageToString LoginPage))
                Err _ -> (model, Ports.removeAccount (Page.pageToString LoginPage))

        NavRequest req ->
            case req of
                Internal url ->
                    let
                        isCurrent =
                            Page.fromUrl url |>
                            Maybe.map (\p -> p == model.page) |>
                            Maybe.withDefault True
                    in
                        ( model
                        , if isCurrent then Cmd.none else Nav.pushUrl model.key (Url.toString url)
                        )

                External url ->
                    ( model
                    , Nav.load url
                    )

        NavChange url ->
            let
                page = Page.fromUrl url |> Maybe.withDefault HomePage
                (m, c) = initPage model page
            in
            ( { m | page = page }, c )


updateLogin: Page.Login.Data.Msg -> Model -> (Model, Cmd Msg)
updateLogin lmsg model =
    let
        (lm, lc, ar) = Page.Login.Update.update model.flags lmsg model.loginModel
        newFlags = Maybe.map (Data.Flags.withAccount model.flags) ar
                   |> Maybe.withDefault model.flags
    in
        ({model | loginModel = lm, flags = newFlags}
        ,Cmd.map LoginMsg lc
        )

updateHome: Page.Home.Data.Msg -> Model -> (Model, Cmd Msg)
updateHome lmsg model =
    let
        (lm, lc) = Page.Home.Update.update model.flags lmsg model.homeModel
    in
        ( {model | homeModel = lm }
        , Cmd.map HomeMsg lc
        )


initPage: Model -> Page -> (Model, Cmd Msg)
initPage model page =
    case page of
        HomePage ->
            (model, Cmd.none)
{--            updateHome Page.Home.Data.GetBasicStats model --}

        LoginPage ->
            (model, Cmd.none)
