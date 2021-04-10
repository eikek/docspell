module Data.Fields exposing
    ( Field(..)
    , all
    , fromList
    , fromString
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
    | PreviewImage
    | CustomFields
    | SourceName


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
        , PreviewImage
        , CustomFields
        , SourceName
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

        "preview" ->
            Just PreviewImage

        "customfields" ->
            Just CustomFields

        "sourcename" ->
            Just SourceName

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

        PreviewImage ->
            "preview"

        CustomFields ->
            "customfields"

        SourceName ->
            "sourcename"


fromList : List String -> List Field
fromList strings =
    List.filterMap fromString strings
