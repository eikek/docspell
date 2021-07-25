{-
   Copyright 2020 Docspell Contributors

   SPDX-License-Identifier: GPL-3.0-or-later
-}


module Data.Validated exposing
    ( Validated(..)
    , isInvalid
    , map
    , map2
    , map3
    , map4
    , toResult
    , value
    )

-- TODO Remove this, use Result


type Validated a
    = Valid a
    | Invalid (List String) a
    | Unknown a


toResult : Validated a -> Result String a
toResult va =
    case va of
        Valid a ->
            Ok a

        Invalid errs _ ->
            Err (String.join ", " errs)

        Unknown a ->
            Ok a


isInvalid : Validated a -> Bool
isInvalid v =
    case v of
        Valid _ ->
            False

        Invalid _ _ ->
            True

        Unknown _ ->
            False


value : Validated a -> a
value va =
    case va of
        Valid a ->
            a

        Invalid _ a ->
            a

        Unknown a ->
            a


map : (a -> b) -> Validated a -> Validated b
map f va =
    case va of
        Valid a ->
            Valid (f a)

        Invalid em a ->
            Invalid em (f a)

        Unknown a ->
            Unknown (f a)


map2 : (a -> b -> c) -> Validated a -> Validated b -> Validated c
map2 f va vb =
    case ( va, vb ) of
        ( Valid a, Valid b ) ->
            Valid (f a b)

        ( Valid a, Invalid em b ) ->
            Invalid em (f a b)

        ( Valid a, Unknown b ) ->
            Unknown (f a b)

        ( Invalid em a, Valid b ) ->
            Invalid em (f a b)

        ( Invalid em1 a, Invalid em2 b ) ->
            Invalid (em1 ++ em2) (f a b)

        ( Invalid em a, Unknown b ) ->
            Invalid em (f a b)

        ( Unknown a, Valid b ) ->
            Unknown (f a b)

        ( Unknown a, Invalid em b ) ->
            Invalid em (f a b)

        ( Unknown a, Unknown b ) ->
            Unknown (f a b)


map3 :
    (a -> b -> c -> d)
    -> Validated a
    -> Validated b
    -> Validated c
    -> Validated d
map3 f va vb vc =
    let
        vab =
            map2 (\e1 -> \e2 -> f e1 e2) va vb
    in
    map2 (\g -> \e3 -> g e3) vab vc


map4 :
    (a -> b -> c -> d -> e)
    -> Validated a
    -> Validated b
    -> Validated c
    -> Validated d
    -> Validated e
map4 f va vb vc vd =
    let
        vabc =
            map3 (\e1 -> \e2 -> \e3 -> f e1 e2 e3) va vb vc
    in
    map2 (\g -> \e4 -> g e4) vabc vd
