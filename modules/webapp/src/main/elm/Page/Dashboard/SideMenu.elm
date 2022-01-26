module Page.Dashboard.SideMenu exposing (view)

import Comp.BookmarkChooser
import Data.Icons as Icons
import Data.UiSettings exposing (UiSettings)
import Html exposing (Attribute, Html, a, div, h3, span, text)
import Html.Attributes exposing (class, href, target)
import Html.Events exposing (onClick)
import Messages.Page.Dashboard exposing (Texts)
import Page exposing (Page(..))
import Page.Dashboard.Data exposing (Msg(..), SideMenuModel)
import Styles as S


view : Texts -> UiSettings -> SideMenuModel -> Html Msg
view texts _ model =
    div [ class "flex flex-col" ]
        [ div [ class "mt-2" ]
            [ menuLink [ onClick InitDashboard, href "#" ] (Icons.dashboardIcon "") "Dashboard"
            , menuLink [ Page.href SearchPage ] (Icons.searchIcon "") "Items"
            ]
        , h3
            [ class S.header3
            , class "italic mt-3"
            ]
            [ text "Bookmarks"
            ]
        , div [ class "ml-2" ]
            [ Html.map BookmarkMsg
                (Comp.BookmarkChooser.viewWith
                    { showUser = True, showCollective = True, showShares = False }
                    texts.bookmarkChooser
                    model.bookmarkChooser
                    Comp.BookmarkChooser.emptySelection
                )
            ]
        , h3
            [ class S.header3
            , class "italic mt-3"
            ]
            [ text "Manage"
            ]
        , div [ class "ml-2 mb-2" ]
            [ menuLink [ onClick InitOrganization, href "#" ] (Icons.organizationIcon "") "Organization"
            , menuLink [ onClick InitPerson, href "#" ] (Icons.personIcon "") "Person"
            , menuLink [ onClick InitEquipment, href "#" ] (Icons.equipmentIcon "") "Equipment"
            , menuLink [ onClick InitTags, href "#" ] (Icons.tagsIcon "") "Tags"
            , menuLink [ onClick InitFolder, href "#" ] (Icons.folderIcon "") "Folder"
            ]
        , div [ class "ml-2" ]
            [ menuLink [ onClick InitNotificationHook, href "#" ] (Icons.notificationHooksIcon "") "Webhooks"
            , menuLink [ onClick InitPeriodicQuery, href "#" ] (Icons.periodicTasksIcon "") "Periodic Queries"
            , menuLink [ onClick InitSource, href "#" ] (Icons.sourceIcon2 "") "Sources"
            , menuLink [ onClick InitShare, href "#" ] (Icons.shareIcon "") "Shares"
            ]
        , h3
            [ class S.header3
            , class "italic mt-3"
            ]
            [ text "Misc"
            ]
        , div [ class "ml-2" ]
            [ menuLink [ href "#", target "_blank" ] (Icons.documentationIcon "") "Documentation"
            ]
        ]


menuLink : List (Attribute Msg) -> Html Msg -> String -> Html Msg
menuLink attrs icon label =
    a
        (attrs
            ++ [ class "my-1"
               , class "flex flex-row items-center rounded px-1 py-1 hover:bg-blue-100 dark:hover:bg-slate-600"
               ]
        )
        [ icon
        , span [ class "ml-2" ]
            [ text label
            ]
        ]
