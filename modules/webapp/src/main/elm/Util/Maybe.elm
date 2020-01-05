module Util.Maybe exposing
    ( fromString
    , isEmpty
    , nonEmpty
    , or
    , withDefault
    )


nonEmpty : Maybe a -> Bool
nonEmpty ma =
    not (isEmpty ma)


isEmpty : Maybe a -> Bool
isEmpty ma =
    ma == Nothing


withDefault : Maybe a -> Maybe a -> Maybe a
withDefault ma1 ma2 =
    if isEmpty ma2 then
        ma1

    else
        ma2


or : List (Maybe a) -> Maybe a
or listma =
    case listma of
        [] ->
            Nothing

        el :: els ->
            case el of
                Just _ ->
                    el

                Nothing ->
                    or els


fromString : String -> Maybe String
fromString str =
    let
        s =
            String.trim str
    in
    if s == "" then
        Nothing

    else
        Just str
