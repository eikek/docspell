module Data.Fields exposing
    ( Field(..)
    , all
    , fromList
    , fromString
    , label
    , sort
    , toString
    )


type Field
    = Tag
    | Folder
    | CorrOrg
    | CorrPerson
    | ConcPerson
    | ConcEquip
    | Date
    | DueDate
    | Direction


all : List Field
all =
    sort
        [ Tag
        , Folder
        , CorrOrg
        , CorrPerson
        , ConcPerson
        , ConcEquip
        , Date
        , DueDate
        , Direction
        ]


sort : List Field -> List Field
sort fields =
    List.sortBy toString fields


fromString : String -> Maybe Field
fromString str =
    case String.toLower str of
        "tag" ->
            Just Tag

        "folder" ->
            Just Folder

        "corrorg" ->
            Just CorrOrg

        "corrperson" ->
            Just CorrPerson

        "concperson" ->
            Just ConcPerson

        "concequip" ->
            Just ConcEquip

        "date" ->
            Just Date

        "duedate" ->
            Just DueDate

        "direction" ->
            Just Direction

        _ ->
            Nothing


toString : Field -> String
toString field =
    case field of
        Tag ->
            "tag"

        Folder ->
            "folder"

        CorrOrg ->
            "corrorg"

        CorrPerson ->
            "corrperson"

        ConcPerson ->
            "concperson"

        ConcEquip ->
            "concequip"

        Date ->
            "date"

        DueDate ->
            "duedate"

        Direction ->
            "direction"


label : Field -> String
label field =
    case field of
        Tag ->
            "Tag"

        Folder ->
            "Folder"

        CorrOrg ->
            "Correspondent Organization"

        CorrPerson ->
            "Correspondent Person"

        ConcPerson ->
            "Concerning Person"

        ConcEquip ->
            "Concerned Equipment"

        Date ->
            "Date"

        DueDate ->
            "Due Date"

        Direction ->
            "Direction"


fromList : List String -> List Field
fromList strings =
    List.filterMap fromString strings
