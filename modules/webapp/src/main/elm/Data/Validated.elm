module Data.Validated exposing (Validated(..), value)


type Validated a
    = Valid a
    | Invalid a
    | Unknown a


value : Validated a -> a
value va =
    case va of
        Valid a ->
            a

        Invalid a ->
            a

        Unknown a ->
            a
