module Util.Update exposing (andThen1, andThen2)


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


andThen2 : List (model -> ( model, Cmd msg, Sub msg )) -> model -> ( model, Cmd msg, Sub msg )
andThen2 fs m =
    let
        init =
            ( m, [], [] )

        update el ( m1, c1, s1 ) =
            let
                ( m2, c2, s2 ) =
                    el m1
            in
            ( m2, c2 :: c1, s2 :: s1 )

        combine ( m1, cl, sl ) =
            ( m1, Cmd.batch cl, Sub.batch sl )
    in
    List.foldl update init fs
        |> combine
