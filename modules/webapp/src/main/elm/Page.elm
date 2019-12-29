module Page exposing
    ( Page(..)
    , fromUrl
    , goto
    , href
    , isOpen
    , isSecured
    , loginPage
    , loginPageReferrer
    , pageFromString
    , pageName
    , pageToString
    , uploadId
    )

import Browser.Navigation as Nav
import Html exposing (Attribute)
import Html.Attributes as Attr
import Url exposing (Url)
import Url.Parser as Parser exposing ((</>), Parser, oneOf, s, string)
import Util.Maybe


type Page
    = HomePage
    | LoginPage (Maybe String)
    | ManageDataPage
    | CollectiveSettingPage
    | UserSettingPage
    | QueuePage
    | RegisterPage
    | UploadPage (Maybe String)
    | NewInvitePage


isSecured : Page -> Bool
isSecured page =
    case page of
        HomePage ->
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


isOpen : Page -> Bool
isOpen page =
    not (isSecured page)


loginPage : Page -> Page
loginPage p =
    case p of
        LoginPage _ ->
            LoginPage Nothing

        _ ->
            LoginPage (Just (pageToString p |> String.dropLeft 2))


pageName : Page -> String
pageName page =
    case page of
        HomePage ->
            "Home"

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


loginPageReferrer : Page -> Maybe Page
loginPageReferrer page =
    case page of
        LoginPage r ->
            Maybe.andThen pageFromString r

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
        HomePage ->
            "#/home"

        LoginPage referer ->
            Maybe.map (\p -> "/" ++ p) referer
                |> Maybe.withDefault ""
                |> (++) "#/login"

        ManageDataPage ->
            "#/manageData"

        CollectiveSettingPage ->
            "#/collectiveSettings"

        UserSettingPage ->
            "#/userSettings"

        QueuePage ->
            "#/queue"

        RegisterPage ->
            "#/register"

        UploadPage sourceId ->
            Maybe.map (\id -> "/" ++ id) sourceId
                |> Maybe.withDefault ""
                |> (++) "#/upload"

        NewInvitePage ->
            "#/newinvite"


pageFromString : String -> Maybe Page
pageFromString str =
    let
        url =
            Url.Url Url.Http "" Nothing str Nothing Nothing
    in
    Parser.parse parser url


href : Page -> Attribute msg
href page =
    Attr.href (pageToString page)


goto : Page -> Cmd msg
goto page =
    Nav.load (pageToString page)


parser : Parser (Page -> a) a
parser =
    oneOf
        [ Parser.map HomePage (oneOf [ s "", s "home" ])
        , Parser.map (\s -> LoginPage (Just s)) (s "login" </> string)
        , Parser.map (LoginPage Nothing) (s "login")
        , Parser.map ManageDataPage (s "manageData")
        , Parser.map CollectiveSettingPage (s "collectiveSettings")
        , Parser.map UserSettingPage (s "userSettings")
        , Parser.map QueuePage (s "queue")
        , Parser.map RegisterPage (s "register")
        , Parser.map (\s -> UploadPage (Just s)) (s "upload" </> string)
        , Parser.map (UploadPage Nothing) (s "upload")
        , Parser.map NewInvitePage (s "newinvite")
        ]


fromUrl : Url -> Maybe Page
fromUrl url =
    { url | path = Maybe.withDefault "" url.fragment, fragment = Nothing }
        |> Parser.parse parser
