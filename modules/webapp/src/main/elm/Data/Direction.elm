module Data.Direction exposing (..)

type Direction
    = Incoming
    | Outgoing

fromString: String -> Maybe Direction
fromString str =
    case String.toLower str of
        "outgoing" -> Just Outgoing
        "incoming" -> Just Incoming
        _ -> Nothing

all: List Direction
all =
    [ Incoming
    , Outgoing
    ]

toString: Direction -> String
toString dir =
    case dir of
        Incoming -> "Incoming"
        Outgoing -> "Outgoing"

icon: Direction -> String
icon dir =
    case dir of
        Incoming -> "level down alternate icon"
        Outgoing -> "level up alternate icon"

unknownIcon: String
unknownIcon =
    "question circle outline icon"

iconFromString: String -> String
iconFromString dir =
    fromString dir
        |> Maybe.map icon
        |> Maybe.withDefault unknownIcon

iconFromMaybe: Maybe String -> String
iconFromMaybe ms =
    Maybe.map iconFromString ms
        |> Maybe.withDefault unknownIcon
