module Data.UiTheme exposing
    ( UiTheme(..)
    , cycle
    , fromString
    , toString
    )


type UiTheme
    = Light
    | Dark


cycle : UiTheme -> UiTheme
cycle current =
    case current of
        Light ->
            Dark

        Dark ->
            Light


fromString : String -> Maybe UiTheme
fromString str =
    case String.toLower str of
        "light" ->
            Just Light

        "dark" ->
            Just Dark

        _ ->
            Nothing


toString : UiTheme -> String
toString theme =
    case theme of
        Light ->
            "Light"

        Dark ->
            "Dark"
