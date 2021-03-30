module Messages exposing
    ( Messages
    , fromIso2
    , get
    , toIso2
    )

import Messages.App
import Messages.CollectiveSettingsPage
import Messages.LoginPage
import Messages.RegisterPage
import UiLanguage exposing (UiLanguage(..))


{-| The messages record contains all strings used in the application.
-}
type alias Messages =
    { lang : UiLanguage
    , iso2 : String
    , label : String
    , flagIcon : String
    , app : Messages.App.Texts
    , collectiveSettings : Messages.CollectiveSettingsPage.Texts
    , login : Messages.LoginPage.Texts
    , register : Messages.RegisterPage.Texts
    }


get : UiLanguage -> Messages
get lang =
    case lang of
        English ->
            gb

        German ->
            de


{-| Get a ISO-3166-1 code of the given lanugage.
-}
toIso2 : UiLanguage -> String
toIso2 lang =
    get lang |> .iso2


{-| Return the UiLanguage from given iso2 code. If the iso2 code is not
known, return Nothing.
-}
readIso2 : String -> Maybe UiLanguage
readIso2 iso =
    let
        isIso lang =
            iso == toIso2 lang
    in
    List.filter isIso UiLanguage.all
        |> List.head


{-| return the language from the given iso2 code. if the iso2 code is
not known, return English as a default.
-}
fromIso2 : String -> UiLanguage
fromIso2 iso =
    readIso2 iso
        |> Maybe.withDefault English



--- Messages Definitions


gb : Messages
gb =
    { lang = English
    , iso2 = "gb"
    , label = "English"
    , flagIcon = "flag-icon flag-icon-gb"
    , app = Messages.App.gb
    , collectiveSettings = Messages.CollectiveSettingsPage.gb
    , login = Messages.LoginPage.gb
    , register = Messages.RegisterPage.gb
    }


de : Messages
de =
    { lang = German
    , iso2 = "de"
    , label = "Deutsch"
    , flagIcon = "flag-icon flag-icon-de"
    , app = Messages.App.de
    , collectiveSettings = Messages.CollectiveSettingsPage.de
    , login = Messages.LoginPage.de
    , register = Messages.RegisterPage.de
    }
