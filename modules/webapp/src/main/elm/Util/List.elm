module Util.List exposing ( find
                          , findIndexed
                          , get
                          , distinct
                          , findNext
                          , findPrev
                          )

get: List a -> Int -> Maybe a
get list index =
    if index < 0 then Nothing
    else case list of
        [] ->
            Nothing
        x :: xs ->
            if index == 0
            then Just x
            else get xs (index - 1)

find: (a -> Bool) -> List a -> Maybe a
find pred list =
    findIndexed pred list |> Maybe.map Tuple.first

findIndexed: (a -> Bool) -> List a -> Maybe (a, Int)
findIndexed pred list =
    findIndexed1 pred list 0

findIndexed1: (a -> Bool) -> List a -> Int -> Maybe (a, Int)
findIndexed1 pred list index =
    case list of
        [] -> Nothing
        x :: xs ->
            if pred x then Just (x, index)
            else findIndexed1 pred xs (index + 1)

distinct: List a -> List a
distinct list =
    List.reverse <|
        List.foldl (\a -> \r -> if (List.member a r) then r else a :: r) [] list

findPrev: (a -> Bool) -> List a -> Maybe a
findPrev pred list =
    findIndexed pred list
        |> Maybe.map Tuple.second
        |> Maybe.map (\i -> i - 1)
        |> Maybe.andThen (get list)

findNext: (a -> Bool) -> List a -> Maybe a
findNext pred list =
    findIndexed pred list
        |> Maybe.map Tuple.second
        |> Maybe.map (\i -> i + 1)
        |> Maybe.andThen (get list)
