{-
   Copyright 2020 Eike K. & Contributors

   SPDX-License-Identifier: AGPL-3.0-or-later
-}


module Page exposing
    ( LoginData
    , Page(..)
    , emptyLoginData
    , fromUrl
    , goto
    , hasSidebar
    , href
    , isOpen
    , isSecured
    , loginPage
    , loginPageReferrer
    , pageFromString
    , pageName
    , pageShareDetail
    , pageShareId
    , pageToString
    , set
    , uploadId
    )

import Browser.Navigation as Nav
import Html exposing (Attribute)
import Html.Attributes as Attr
import Url exposing (Url)
import Url.Parser as Parser exposing ((</>), (<?>), Parser, oneOf, s, string)
import Url.Parser.Query as Query
import Util.Maybe


type alias LoginData =
    { referrer : Maybe Page
    , session : Maybe String
    , openid : Int
    }


emptyLoginData : LoginData
emptyLoginData =
    { referrer = Nothing
    , session = Nothing
    , openid = 0
    }


type Page
    = SearchPage
    | LoginPage LoginData
    | ManageDataPage
    | CollectiveSettingPage
    | UserSettingPage
    | QueuePage
    | RegisterPage
    | UploadPage (Maybe String)
    | NewInvitePage
    | ItemDetailPage String
    | SharePage String
    | ShareDetailPage String String


isSecured : Page -> Bool
isSecured page =
    case page of
        SearchPage ->
            True

        LoginPage _ ->
            False

        ManageDataPage ->
            True

        CollectiveSettingPage ->
            True

        UserSettingPage ->
            True

        QueuePage ->
            True

        RegisterPage ->
            False

        NewInvitePage ->
            False

        UploadPage arg ->
            Util.Maybe.isEmpty arg

        ItemDetailPage _ ->
            True

        SharePage _ ->
            False

        ShareDetailPage _ _ ->
            False


{-| Currently, all secured pages have a sidebar, except UploadPage.
-}
hasSidebar : Page -> Bool
hasSidebar page =
    case page of
        UploadPage _ ->
            False

        SharePage _ ->
            True

        ShareDetailPage _ _ ->
            True

        _ ->
            isSecured page


isOpen : Page -> Bool
isOpen page =
    not (isSecured page)


loginPage : Page -> Page
loginPage p =
    case p of
        LoginPage _ ->
            LoginPage emptyLoginData

        _ ->
            LoginPage { emptyLoginData | referrer = Just p }


pageName : Page -> String
pageName page =
    case page of
        SearchPage ->
            "Search"

        LoginPage _ ->
            "Login"

        ManageDataPage ->
            "Manage Data"

        CollectiveSettingPage ->
            "Collective Settings"

        UserSettingPage ->
            "User Settings"

        QueuePage ->
            "Processing"

        RegisterPage ->
            "Register"

        NewInvitePage ->
            "New Invite"

        UploadPage arg ->
            case arg of
                Just _ ->
                    "Anonymous Upload"

                Nothing ->
                    "Upload"

        ItemDetailPage _ ->
            "Item"

        SharePage _ ->
            "Share"

        ShareDetailPage _ _ ->
            "Share Detail"


loginPageReferrer : Page -> LoginData
loginPageReferrer page =
    case page of
        LoginPage data ->
            data

        _ ->
            emptyLoginData


pageShareId : Page -> Maybe String
pageShareId page =
    case page of
        SharePage id ->
            Just id

        _ ->
            Nothing


pageShareDetail : Page -> Maybe ( String, String )
pageShareDetail page =
    case page of
        ShareDetailPage shareId itemId ->
            Just ( shareId, itemId )

        _ ->
            Nothing


uploadId : Page -> Maybe String
uploadId page =
    case page of
        UploadPage id ->
            id

        _ ->
            Nothing


pageToString : Page -> String
pageToString page =
    case page of
        SearchPage ->
            "/app/search"

        LoginPage data ->
            case data.referrer of
                Just (LoginPage _) ->
                    "/app/login"

                Just p ->
                    "/app/login?r=" ++ pageToString p

                Nothing ->
                    "/app/login"

        ManageDataPage ->
            "/app/managedata"

        CollectiveSettingPage ->
            "/app/csettings"

        UserSettingPage ->
            "/app/usettings"

        QueuePage ->
            "/app/queue"

        RegisterPage ->
            "/app/register"

        UploadPage sourceId ->
            Maybe.map (\id -> "/" ++ id) sourceId
                |> Maybe.withDefault ""
                |> (++) "/app/upload"

        NewInvitePage ->
            "/app/newinvite"

        ItemDetailPage id ->
            "/app/item/" ++ id

        SharePage id ->
            "/app/share/" ++ id

        ShareDetailPage shareId itemId ->
            "/app/share/" ++ shareId ++ "/" ++ itemId


pageFromString : String -> Maybe Page
pageFromString str =
    let
        urlNormed =
            if String.startsWith str "http" then
                str

            else
                "http://somehost" ++ str

        url =
            Url.fromString urlNormed
    in
    Maybe.andThen (Parser.parse parser) url


href : Page -> Attribute msg
href page =
    Attr.href (pageToString page)


set : Nav.Key -> Page -> Cmd msg
set key page =
    Nav.pushUrl key (pageToString page)


goto : Page -> Cmd msg
goto page =
    Nav.load (pageToString page)


pathPrefix : String
pathPrefix =
    "app"


parser : Parser (Page -> a) a
parser =
    oneOf
        [ Parser.map SearchPage
            (oneOf
                [ Parser.top
                , s pathPrefix </> s "search"
                ]
            )
        , Parser.map LoginPage (s pathPrefix </> s "login" <?> loginPageParser)
        , Parser.map ManageDataPage (s pathPrefix </> s "managedata")
        , Parser.map CollectiveSettingPage (s pathPrefix </> s "csettings")
        , Parser.map UserSettingPage (s pathPrefix </> s "usettings")
        , Parser.map QueuePage (s pathPrefix </> s "queue")
        , Parser.map RegisterPage (s pathPrefix </> s "register")
        , Parser.map (\s -> UploadPage (Just s)) (s pathPrefix </> s "upload" </> string)
        , Parser.map (UploadPage Nothing) (s pathPrefix </> s "upload")
        , Parser.map NewInvitePage (s pathPrefix </> s "newinvite")
        , Parser.map ItemDetailPage (s pathPrefix </> s "item" </> string)
        , Parser.map ShareDetailPage (s pathPrefix </> s "share" </> string </> string)
        , Parser.map SharePage (s pathPrefix </> s "share" </> string)
        ]


fromUrl : Url -> Maybe Page
fromUrl url =
    Parser.parse parser url


fromString : String -> Maybe Page
fromString str =
    let
        url =
            Url Url.Http "localhost" Nothing str Nothing Nothing
    in
    fromUrl url


loginPageOAuthQuery : Query.Parser Int
loginPageOAuthQuery =
    Query.map (Maybe.withDefault 0) (Query.int "openid")


loginPageSessionQuery : Query.Parser (Maybe String)
loginPageSessionQuery =
    Query.string "auth"


loginPageParser : Query.Parser LoginData
loginPageParser =
    Query.map3 LoginData pageQuery loginPageSessionQuery loginPageOAuthQuery


pageQuery : Query.Parser (Maybe Page)
pageQuery =
    let
        parsePage ms =
            Maybe.andThen fromString ms
    in
    Query.string "r"
        |> Query.map parsePage
