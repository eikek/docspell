module Page.Dashboard.SideMenu exposing (view)

import Api.Model.VersionInfo exposing (VersionInfo)
import Comp.BookmarkChooser
import Data.Flags exposing (Flags)
import Data.Icons as Icons
import Data.UiSettings exposing (UiSettings)
import Html exposing (Attribute, Html, a, div, h3, span, text)
import Html.Attributes exposing (class, href, target)
import Html.Events exposing (onClick)
import Messages.Page.Dashboard exposing (Texts)
import Page exposing (Page(..))
import Page.Dashboard.Data exposing (Msg(..), SideMenuModel)
import Styles as S


view : Texts -> VersionInfo -> UiSettings -> SideMenuModel -> Html Msg
view texts versionInfo _ model =
    div [ class "flex flex-col flex-grow" ]
        [ div [ class "mt-2" ]
            [ menuLink [ onClick InitDashboard, href "#" ] (Icons.dashboardIcon "") texts.dashboardLink
            , menuLink [ Page.href (SearchPage Nothing) ] (Icons.searchIcon "") texts.basics.items
            ]
        , h3
            [ class S.header3
            , class "italic mt-3"
            ]
            [ text texts.bookmarks
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
            [ text texts.settings
            ]
        , div [ class "ml-2 mb-2" ]
            [ menuLink [ onClick InitNotificationHook, href "#" ] (Icons.notificationHooksIcon "") texts.basics.notificationHooks
            , menuLink [ onClick InitPeriodicQuery, href "#" ] (Icons.periodicTasksIcon "") texts.basics.periodicQueries
            , menuLink [ onClick InitSource, href "#" ] (Icons.sourceIcon2 "") texts.basics.sources
            , menuLink [ onClick InitShare, href "#" ] (Icons.shareIcon "") texts.basics.shares
            ]
        , h3
            [ class S.header3
            , class "italic mt-3"
            ]
            [ text texts.manage
            ]
        , div [ class "ml-2 mb-2" ]
            [ menuLink [ onClick InitOrganization, href "#" ] (Icons.organizationIcon "") texts.basics.organization
            , menuLink [ onClick InitPerson, href "#" ] (Icons.personIcon "") texts.basics.person
            , menuLink [ onClick InitEquipment, href "#" ] (Icons.equipmentIcon "") texts.basics.equipment
            , menuLink [ onClick InitTags, href "#" ] (Icons.tagsIcon "") texts.basics.tags
            , menuLink [ onClick InitFolder, href "#" ] (Icons.folderIcon "") texts.basics.folder
            ]
        , h3
            [ class S.header3
            , class "italic mt-3"
            ]
            [ text texts.misc
            ]
        , div [ class "ml-2" ]
            [ menuLink [ onClick InitUpload, href "#" ] (Icons.fileUploadIcon "") texts.uploadFiles
            ]
        , div [ class "mt-2 opacity-75" ]
            [ menuLink [ href Data.UiSettings.documentationSite, target "_blank" ] (Icons.documentationIcon "") texts.documentation
            ]
        , div [ class "flex flex-grow items-end" ]
            [ div [ class "text-center text-xs w-full opacity-50" ]
                [ text "Docspell "
                , text versionInfo.version
                ]
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
