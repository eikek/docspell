module Util.Maybe exposing (..)

nonEmpty: Maybe a -> Bool
nonEmpty ma =
    Maybe.map (\_ -> True) ma
        |> Maybe.withDefault False

isEmpty: Maybe a -> Bool
isEmpty ma =
    not (nonEmpty ma)

withDefault: Maybe a -> Maybe a -> Maybe a
withDefault ma1 ma2 =
    if isEmpty ma2 then ma1 else ma2

or: List (Maybe a) -> Maybe a
or listma =
    case listma of
        [] -> Nothing
        el :: els ->
            case el of
                Just _ -> el
                Nothing -> or els
