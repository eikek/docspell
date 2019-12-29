module Util.Update exposing (andThen1)


andThen1 : List (a -> ( a, Cmd b )) -> a -> ( a, Cmd b )
andThen1 fs a =
    let
        init =
            ( a, [] )

        update el tuple =
            let
                ( a2, c2 ) =
                    el (Tuple.first tuple)
            in
            ( a2, c2 :: Tuple.second tuple )
    in
    List.foldl update init fs
        |> Tuple.mapSecond Cmd.batch
