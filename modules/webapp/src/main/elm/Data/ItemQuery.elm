{-
   Copyright 2020 Docspell Contributors

   SPDX-License-Identifier: GPL-3.0-or-later
-}


module Data.ItemQuery exposing
    ( AttrMatch(..)
    , ItemQuery(..)
    , TagMatch(..)
    , and
    , render
    , renderMaybe
    , request
    )

{-| Models the query language for the purpose of generating a query string.
-}

import Api.Model.CustomFieldValue exposing (CustomFieldValue)
import Api.Model.ItemQuery as RQ
import Data.Direction exposing (Direction)


type TagMatch
    = AnyMatch
    | AllMatch


type AttrMatch
    = Eq
    | Neq
    | Lt
    | Gt
    | Lte
    | Gte
    | Like


type ItemQuery
    = Inbox Bool
    | And (List ItemQuery)
    | Or (List ItemQuery)
    | Not ItemQuery
    | TagIds TagMatch (List String)
    | CatNames TagMatch (List String)
    | FolderId AttrMatch String
    | CorrOrgId AttrMatch String
    | CorrPersId AttrMatch String
    | ConcPersId AttrMatch String
    | ConcEquipId AttrMatch String
    | CustomField AttrMatch CustomFieldValue
    | CustomFieldId AttrMatch CustomFieldValue
    | DateMs AttrMatch Int
    | DueDateMs AttrMatch Int
    | Source AttrMatch String
    | Dir Direction
    | ItemIdIn (List String)
    | ItemName AttrMatch String
    | AllNames String
    | Contents String
    | Fragment String


and : List (Maybe ItemQuery) -> Maybe ItemQuery
and list =
    case List.filterMap identity list of
        [] ->
            Nothing

        es ->
            Just (And es)


request : Maybe ItemQuery -> RQ.ItemQuery
request mq =
    { offset = Nothing
    , limit = Nothing
    , withDetails = Just True
    , query = renderMaybe mq
    , deleted = Just False
    }


renderMaybe : Maybe ItemQuery -> String
renderMaybe mq =
    Maybe.map render mq
        |> Maybe.withDefault ""


render : ItemQuery -> String
render q =
    let
        boolStr flag =
            if flag then
                "yes"

            else
                "no"

        between left right str =
            left ++ str ++ right

        surround lr str =
            between lr lr str

        tagMatchStr tm =
            case tm of
                AnyMatch ->
                    ":"

                AllMatch ->
                    "="

        quoteStr =
            String.replace "\"" "\\\""
                >> surround "\""
    in
    case q of
        And inner ->
            List.map render inner
                |> String.join " "
                |> between "(& " " )"

        Or inner ->
            List.map render inner
                |> String.join " "
                |> between "(| " " )"

        Not inner ->
            "!" ++ render inner

        Inbox flag ->
            "inbox:" ++ boolStr flag

        TagIds m ids ->
            List.map quoteStr ids
                |> String.join ","
                |> between ("tag.id" ++ tagMatchStr m) ""

        CatNames m ids ->
            List.map quoteStr ids
                |> String.join ","
                |> between ("cat" ++ tagMatchStr m) ""

        FolderId m id ->
            "folder.id" ++ attrMatch m ++ quoteStr id

        CorrOrgId m id ->
            "corr.org.id" ++ attrMatch m ++ quoteStr id

        CorrPersId m id ->
            "corr.pers.id" ++ attrMatch m ++ quoteStr id

        ConcPersId m id ->
            "conc.pers.id" ++ attrMatch m ++ quoteStr id

        ConcEquipId m id ->
            "conc.equip.id" ++ attrMatch m ++ quoteStr id

        CustomField m kv ->
            "f:" ++ kv.field ++ attrMatch m ++ quoteStr kv.value

        CustomFieldId m kv ->
            "f.id:" ++ kv.field ++ attrMatch m ++ quoteStr kv.value

        DateMs m ms ->
            "date" ++ attrMatch m ++ "ms" ++ String.fromInt ms

        DueDateMs m ms ->
            "due" ++ attrMatch m ++ "ms" ++ String.fromInt ms

        Source m str ->
            "source" ++ attrMatch m ++ quoteStr str

        Dir dir ->
            "incoming:" ++ boolStr (dir == Data.Direction.Incoming)

        ItemIdIn ids ->
            "id~=" ++ String.join "," ids

        ItemName m str ->
            "name" ++ attrMatch m ++ quoteStr str

        AllNames str ->
            "names:" ++ quoteStr str

        Contents str ->
            "content:" ++ quoteStr str

        Fragment str ->
            "(& " ++ str ++ " )"


attrMatch : AttrMatch -> String
attrMatch am =
    case am of
        Eq ->
            "="

        Neq ->
            "!="

        Like ->
            ":"

        Gt ->
            ">"

        Gte ->
            ">="

        Lt ->
            "<"

        Lte ->
            "<="
