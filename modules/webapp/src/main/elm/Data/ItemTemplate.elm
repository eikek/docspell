module Data.ItemTemplate exposing
    ( ItemTemplate
    , TemplateContext
    , concEquip
    , concPerson
    , concat
    , concerning
    , corrOrg
    , corrPerson
    , correspondent
    , dateLong
    , dateShort
    , direction
    , dueDateLong
    , dueDateShort
    , empty
    , fileCount
    , folder
    , from
    , fromMaybe
    , isEmpty
    , literal
    , map
    , name
    , nonEmpty
    , readTemplate
    , render
    , source
    , splitTokens
    )

import Api.Model.IdName exposing (IdName)
import Api.Model.ItemLight exposing (ItemLight)
import Data.Direction exposing (Direction)
import Set
import Util.List
import Util.String


type alias TemplateContext =
    { dateFormatLong : Int -> String
    , dateFormatShort : Int -> String
    , directionLabel : Direction -> String
    }


type ItemTemplate
    = ItemTemplate (TemplateContext -> ItemLight -> String)


readTemplate : String -> Maybe ItemTemplate
readTemplate str =
    let
        read tokens =
            List.map patternToken tokens
                |> concat
    in
    if str == "" then
        Just empty

    else
        Maybe.map read (splitTokens str)


render : ItemTemplate -> TemplateContext -> ItemLight -> String
render pattern ctx item =
    case pattern of
        ItemTemplate f ->
            f ctx item


isEmpty : ItemTemplate -> ItemLight -> Bool
isEmpty pattern item =
    let
        ctx =
            { dateFormatLong = \_ -> "non-empty"
            , dateFormatShort = \_ -> "non-empty"
            , directionLabel = \_ -> "non-empty"
            }
    in
    render pattern ctx item |> String.isEmpty


nonEmpty : ItemTemplate -> ItemLight -> Bool
nonEmpty pattern item =
    isEmpty pattern item |> not



--- Pattern Combinators


map : (String -> String) -> ItemTemplate -> ItemTemplate
map f pattern =
    case pattern of
        ItemTemplate p ->
            ItemTemplate (\ctx -> p ctx >> f)


map2 : (String -> String -> String) -> ItemTemplate -> ItemTemplate -> ItemTemplate
map2 f pattern1 pattern2 =
    case ( pattern1, pattern2 ) of
        ( ItemTemplate p1, ItemTemplate p2 ) ->
            ItemTemplate (\ctx -> \i -> f (p1 ctx i) (p2 ctx i))


combine : String -> ItemTemplate -> ItemTemplate -> ItemTemplate
combine sep p1 p2 =
    map2
        (\s1 ->
            \s2 ->
                List.filter (String.isEmpty >> not) [ s1, s2 ]
                    |> String.join sep
        )
        p1
        p2


concat : List ItemTemplate -> ItemTemplate
concat patterns =
    ItemTemplate
        (\ctx ->
            \i ->
                List.map (\p -> render p ctx i) patterns
                    |> String.join ""
        )


firstNonEmpty : List ItemTemplate -> ItemTemplate
firstNonEmpty patterns =
    ItemTemplate
        (\ctx ->
            \i ->
                List.map (\p -> render p ctx i) patterns
                    |> List.filter (String.isEmpty >> not)
                    |> List.head
                    |> Maybe.withDefault ""
        )



--- Patterns


from : (ItemLight -> String) -> ItemTemplate
from f =
    ItemTemplate (\_ -> f)


fromMaybe : (TemplateContext -> ItemLight -> Maybe String) -> ItemTemplate
fromMaybe f =
    ItemTemplate (\ctx -> f ctx >> Maybe.withDefault "")


literal : String -> ItemTemplate
literal str =
    ItemTemplate (\_ -> \_ -> str)


empty : ItemTemplate
empty =
    literal ""


name : ItemTemplate
name =
    from (.name >> Util.String.underscoreToSpace)


direction : ItemTemplate
direction =
    let
        dirStr ctx ms =
            Maybe.andThen Data.Direction.fromString ms
                |> Maybe.map ctx.directionLabel
    in
    fromMaybe (\ctx -> .direction >> dirStr ctx)


dateLong : ItemTemplate
dateLong =
    ItemTemplate (\ctx -> .date >> ctx.dateFormatLong)


dateShort : ItemTemplate
dateShort =
    ItemTemplate (\ctx -> .date >> ctx.dateFormatShort)


dueDateLong : ItemTemplate
dueDateLong =
    fromMaybe (\ctx -> .dueDate >> Maybe.map ctx.dateFormatLong)


dueDateShort : ItemTemplate
dueDateShort =
    fromMaybe (\ctx -> .dueDate >> Maybe.map ctx.dateFormatShort)


source : ItemTemplate
source =
    from .source


folder : ItemTemplate
folder =
    from (.folder >> getName)


corrOrg : ItemTemplate
corrOrg =
    from (.corrOrg >> getName)


corrPerson : ItemTemplate
corrPerson =
    from (.corrPerson >> getName)


correspondent : ItemTemplate
correspondent =
    combine ", " corrOrg corrPerson


concPerson : ItemTemplate
concPerson =
    from (.concPerson >> getName)


concEquip : ItemTemplate
concEquip =
    from (.concEquipment >> getName)


concerning : ItemTemplate
concerning =
    combine ", " concPerson concEquip


fileCount : ItemTemplate
fileCount =
    from (.attachments >> List.length >> String.fromInt)



--- Helpers


getName : Maybe IdName -> String
getName =
    Maybe.map .name >> Maybe.withDefault ""



--- Parse pattern


knownPattern : String -> Maybe ItemTemplate
knownPattern str =
    case str of
        "{{name}}" ->
            Just name

        "{{source}}" ->
            Just source

        "{{folder}}" ->
            Just folder

        "{{corrOrg}}" ->
            Just corrOrg

        "{{corrPerson}}" ->
            Just corrPerson

        "{{correspondent}}" ->
            Just correspondent

        "{{concPerson}}" ->
            Just concPerson

        "{{concEquip}}" ->
            Just concEquip

        "{{concerning}}" ->
            Just concerning

        "{{fileCount}}" ->
            Just fileCount

        "{{dateLong}}" ->
            Just dateLong

        "{{dateShort}}" ->
            Just dateShort

        "{{dueDateLong}}" ->
            Just dueDateLong

        "{{dueDateShort}}" ->
            Just dueDateShort

        "{{direction}}" ->
            Just direction

        _ ->
            Nothing


patternToken : String -> ItemTemplate
patternToken str =
    knownPattern str
        |> Maybe.withDefault
            (alternativeToken str
                |> Maybe.withDefault (literal str)
            )


alternativeToken : String -> Maybe ItemTemplate
alternativeToken str =
    let
        inner =
            String.dropLeft 2 str
                |> String.dropRight 2
                |> String.split "|"
                |> List.filter (String.isEmpty >> not)

        pattern s =
            knownPattern ("{{" ++ s ++ "}}")
                |> Maybe.withDefault (literal s)
    in
    if String.startsWith "{{" str && String.endsWith "}}" str then
        case inner of
            [] ->
                Nothing

            _ ->
                List.map pattern inner
                    |> firstNonEmpty
                    |> Just

    else
        Nothing


splitTokens : String -> Maybe (List String)
splitTokens str =
    let
        begins =
            String.indexes "{{" str

        ends =
            String.indexes "}}" str
                |> List.map ((+) 2)

        indexes =
            Set.union (Set.fromList begins) (Set.fromList ends)
                |> Set.insert 0
                |> Set.insert (String.length str)
                |> Set.toList
                |> List.sort

        mkSubstring i1 i2 =
            String.slice i1 i2 str
    in
    if List.length begins == List.length ends then
        Util.List.sliding mkSubstring indexes |> Just

    else
        Nothing
