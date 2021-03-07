module Page.Home.View2 exposing (viewContent, viewSidebar)

import Comp.Basic as B
import Comp.ItemCardList
import Comp.MenuBar as MB
import Comp.PowerSearchInput
import Comp.SearchMenu
import Comp.SearchStatsView
import Comp.YesNoDimmer
import Data.Flags exposing (Flags)
import Data.ItemSelection
import Data.UiSettings exposing (UiSettings)
import Html exposing (..)
import Html.Attributes exposing (..)
import Html.Events exposing (onClick, onInput)
import Page exposing (Page(..))
import Page.Home.Data exposing (..)
import Page.Home.SideMenu
import Set
import Styles as S
import Util.Html


viewSidebar : Bool -> Flags -> UiSettings -> Model -> Html Msg
viewSidebar visible flags settings model =
    div
        [ id "sidebar"
        , class S.sidebar
        , class S.sidebarBg
        , classList [ ( "hidden", not visible ) ]
        ]
        [ Page.Home.SideMenu.view flags settings model
        ]


viewContent : Flags -> UiSettings -> Model -> Html Msg
viewContent flags settings model =
    div
        [ id "item-card-list" -- this id is used in scroll-to-card
        , class S.content
        ]
        (searchStats flags settings model
            ++ itemsBar flags settings model
            ++ itemCardList flags settings model
            ++ deleteSelectedDimmer model
        )



--- Helpers


deleteSelectedDimmer : Model -> List (Html Msg)
deleteSelectedDimmer model =
    let
        selectAction =
            case model.viewMode of
                SelectView svm ->
                    svm.action

                _ ->
                    NoneAction

        deleteAllDimmer : Comp.YesNoDimmer.Settings
        deleteAllDimmer =
            Comp.YesNoDimmer.defaultSettings2 "Really delete all selected items?"
    in
    case model.viewMode of
        SelectView svm ->
            [ Html.map DeleteSelectedConfirmMsg
                (Comp.YesNoDimmer.viewN
                    (selectAction == DeleteSelected)
                    deleteAllDimmer
                    svm.deleteAllConfirm
                )
            ]

        _ ->
            []


itemsBar : Flags -> UiSettings -> Model -> List (Html Msg)
itemsBar flags settings model =
    case model.viewMode of
        SimpleView ->
            [ defaultMenuBar flags settings model ]

        SearchView ->
            [ defaultMenuBar flags settings model ]

        SelectView svm ->
            [ editMenuBar model svm ]


defaultMenuBar : Flags -> UiSettings -> Model -> Html Msg
defaultMenuBar _ settings model =
    let
        btnStyle =
            S.secondaryBasicButton ++ " text-sm"

        searchInput =
            Comp.SearchMenu.textSearchString
                model.searchMenuModel.textSearchModel

        simpleSearchBar =
            div
                [ class "relative flex flex-row" ]
                [ input
                    [ type_ "text"
                    , placeholder
                        (case model.searchTypeDropdownValue of
                            ContentOnlySearch ->
                                "Content search…"

                            BasicSearch ->
                                "Search in names…"
                        )
                    , onInput SetBasicSearch
                    , Util.Html.onKeyUpCode KeyUpSearchbarMsg
                    , Maybe.map value searchInput
                        |> Maybe.withDefault (value "")
                    , class (String.replace "rounded" "" S.textInput)
                    , class "py-1 text-sm border-r-0 rounded-l"
                    ]
                    []
                , a
                    [ class S.secondaryBasicButtonPlain
                    , class "text-sm px-4 py-2 border rounded-r"
                    , href "#"
                    , onClick ToggleSearchType
                    ]
                    [ i [ class "fa fa-exchange-alt" ] []
                    ]
                ]

        powerSearchBar =
            div
                [ class "relative flex flex-grow flex-row" ]
                [ Html.map PowerSearchMsg
                    (Comp.PowerSearchInput.viewInput []
                        model.powerSearchInput
                    )
                , Html.map PowerSearchMsg
                    (Comp.PowerSearchInput.viewResult [] model.powerSearchInput)
                ]
    in
    MB.view
        { end =
            [ MB.CustomElement <|
                B.secondaryBasicButton
                    { label = ""
                    , icon =
                        if model.searchInProgress then
                            "fa fa-sync animate-spin"

                        else
                            "fa fa-sync"
                    , disabled = model.searchInProgress
                    , handler = onClick ResetSearch
                    , attrs = [ href "#" ]
                    }
            , MB.CustomButton
                { tagger = ToggleSelectView
                , label = ""
                , icon = Just "fa fa-tasks"
                , title = "Select Mode"
                , inputClass =
                    [ ( btnStyle, True )
                    , ( "bg-gray-200 dark:bg-bluegray-600", selectActive model )
                    ]
                }
            ]
        , start =
            [ MB.CustomElement <|
                if settings.powerSearchEnabled then
                    powerSearchBar

                else
                    simpleSearchBar
            , MB.CustomButton
                { tagger = TogglePreviewFullWidth
                , label = ""
                , icon = Just "fa fa-expand"
                , title =
                    if settings.cardPreviewFullWidth then
                        "Full height preview"

                    else
                        "Full width preview"
                , inputClass =
                    [ ( btnStyle, True )
                    , ( "hidden sm:inline-block", False )
                    , ( "bg-gray-200 dark:bg-bluegray-600", settings.cardPreviewFullWidth )
                    ]
                }
            ]
        , rootClasses = "mb-2 pt-1 dark:bg-bluegray-700 items-center text-sm"
        }


editMenuBar : Model -> SelectViewModel -> Html Msg
editMenuBar model svm =
    let
        selectCount =
            Set.size svm.ids |> String.fromInt

        btnStyle =
            S.secondaryBasicButton ++ " text-sm"
    in
    MB.view
        { start =
            [ MB.CustomButton
                { tagger = EditSelectedItems
                , label = ""
                , icon = Just "fa fa-edit"
                , title = "Edit " ++ selectCount ++ " selected items"
                , inputClass =
                    [ ( btnStyle, True )
                    , ( "bg-gray-200 dark:bg-bluegray-600", svm.action == EditSelected )
                    ]
                }
            , MB.CustomButton
                { tagger = RequestDeleteSelected
                , label = ""
                , icon = Just "fa fa-trash"
                , title = "Delete " ++ selectCount ++ " selected items"
                , inputClass =
                    [ ( btnStyle, True )
                    , ( "bg-gray-200 dark:bg-bluegray-600", svm.action == DeleteSelected )
                    ]
                }
            ]
        , end =
            [ MB.CustomButton
                { tagger = SelectAllItems
                , label = ""
                , icon = Just "fa fa-check-square font-thin"
                , title = "Select all visible"
                , inputClass =
                    [ ( btnStyle, True )
                    ]
                }
            , MB.CustomButton
                { tagger = SelectNoItems
                , label = ""
                , icon = Just "fa fa-square font-thin"
                , title = "Select none"
                , inputClass =
                    [ ( btnStyle, True )
                    ]
                }
            , MB.TextLabel
                { icon = ""
                , label = selectCount
                , class = "px-4 py-2 w-10 rounded-full font-bold bg-blue-100 dark:bg-lightblue-600 "
                }
            , MB.CustomButton
                { tagger = ResetSearch
                , label = ""
                , icon = Just "fa fa-sync"
                , title = "Reset search form"
                , inputClass =
                    [ ( btnStyle, True )
                    , ( "hidden sm:block", True )
                    ]
                }
            , MB.CustomButton
                { tagger = ToggleSelectView
                , label = ""
                , icon = Just "fa fa-tasks"
                , title = "Exit Select Mode"
                , inputClass =
                    [ ( btnStyle, True )
                    , ( "bg-gray-200 dark:bg-bluegray-600", selectActive model )
                    ]
                }
            ]
        , rootClasses = "mb-2 pt-2 sticky top-0 text-sm"
        }


searchStats : Flags -> UiSettings -> Model -> List (Html Msg)
searchStats _ settings model =
    if settings.searchStatsVisible then
        [ Comp.SearchStatsView.view2 "my-2" model.searchStats
        ]

    else
        []


itemCardList : Flags -> UiSettings -> Model -> List (Html Msg)
itemCardList _ settings model =
    let
        itemViewCfg =
            case model.viewMode of
                SelectView svm ->
                    Comp.ItemCardList.ViewConfig
                        model.scrollToCard
                        (Data.ItemSelection.Active svm.ids)

                _ ->
                    Comp.ItemCardList.ViewConfig
                        model.scrollToCard
                        Data.ItemSelection.Inactive
    in
    [ Html.map ItemCardListMsg
        (Comp.ItemCardList.view2 itemViewCfg settings model.itemListModel)
    , loadMore settings model
    ]


loadMore : UiSettings -> Model -> Html Msg
loadMore settings model =
    let
        inactive =
            not model.moreAvailable || model.moreInProgress || model.searchInProgress
    in
    div
        [ class "h-40 flex flex-col items-center justify-center w-full"
        , classList [ ( "hidden", resultsBelowLimit settings model ) ]
        ]
        [ B.secondaryBasicButton
            { label =
                if model.moreAvailable then
                    "Load more…"

                else
                    "That's all"
            , icon =
                if model.moreInProgress then
                    "fa fa-circle-notch animate-spin"

                else
                    "fa fa-angle-double-down"
            , handler = onClick LoadMore
            , disabled = inactive
            , attrs = []
            }
        ]
