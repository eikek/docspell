module Comp.Tabs exposing
    ( State(..)
    , Style
    , Tab
    , akkordion
    , akkordionTab
    , defaultStyle
    , searchMenuStyle
    )

import Html exposing (..)
import Html.Attributes exposing (..)
import Html.Events exposing (onClick)


type alias Tab msg =
    { name : String
    , title : String
    , titleRight : List (Html msg)
    , info : Maybe String
    , body : List (Html msg)
    }


type alias Style =
    { rootClasses : String
    , tabClasses : String
    , titleClasses : String
    , bodyClasses : String
    }


type State
    = Open
    | Closed
    | Hidden


defaultStyle : Style
defaultStyle =
    { rootClasses = "border-0 border-t  dark:border-bluegray-600"
    , tabClasses = "border-0 border-b  dark:border-bluegray-600"
    , titleClasses = "py-4 md:py-2 px-2 bg-gray-50 hover:bg-gray-100 dark:bg-bluegray-700 dark:bg-opacity-50 dark:hover:bg-opacity-100"
    , bodyClasses = "mt-2 py-2"
    }


searchMenuStyle : Style
searchMenuStyle =
    { rootClasses = "border-0 "
    , tabClasses = "border-0 "
    , titleClasses = "py-4 md:py-2 pl-2 bg-blue-50 hover:bg-blue-100 dark:bg-bluegray-700 dark:hover:bg-opacity-100 dark:hover:bg-bluegray-600 rounded"
    , bodyClasses = "mt-1 py-1 pl-2"
    }


akkordion : Style -> (Tab msg -> ( State, msg )) -> List (Tab msg) -> Html msg
akkordion style state tabs =
    let
        viewTab t =
            let
                ( open, m ) =
                    state t
            in
            akkordionTab style open m t
    in
    div
        [ class style.rootClasses
        , class "flex flex-col"
        ]
        (List.map viewTab tabs)


akkordionTab : Style -> State -> msg -> Tab msg -> Html msg
akkordionTab style state toggle tab =
    let
        tabTitle =
            div
                [ class "flex flex-row"
                , class style.titleClasses
                ]
                (a
                    [ class "flex flex-row items-center flex-grow"
                    , href "#"
                    , onClick toggle
                    ]
                    [ div [ class "inline-flex mr-2 w-2" ]
                        [ if state == Open then
                            i [ class "fa fa-caret-down" ] []

                          else
                            i [ class "fa fa-caret-right" ] []
                        ]
                    , div [ class "flex flex-col" ]
                        [ div [ class "px-2 font-semibold" ]
                            [ text tab.title
                            ]
                        , div [ class "px-2 opacity-50 text-sm" ]
                            [ text (Maybe.withDefault "" tab.info)
                            ]
                        ]
                    ]
                    :: tab.titleRight
                )

        tabContent =
            div
                [ classList [ ( "hidden", state == Closed ) ]
                , class style.bodyClasses
                ]
                tab.body
    in
    div
        [ class style.tabClasses
        , class "flex flex-col"
        , classList [ ( "hidden", state == Hidden ) ]
        ]
        [ tabTitle
        , tabContent
        ]
