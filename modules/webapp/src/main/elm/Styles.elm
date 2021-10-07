{-
   Copyright 2020 Eike K. & Contributors

   SPDX-License-Identifier: AGPL-3.0-or-later
-}


module Styles exposing (..)


sidebar : String
sidebar =
    " flex flex-col flex-none md:w-80 w-full min-h-max px-2 dark:text-gray-200 overflow-y-auto h-full transition-opacity transition-duration-200 scrollbar-thin scrollbar-light-sidebar dark:scrollbar-dark-sidebar"


sidebarBg : String
sidebarBg =
    " bg-blue-50 dark:bg-bluegray-700 "


sidebarMenuItemActive : String
sidebarMenuItemActive =
    "bg-blue-100 dark:bg-bluegray-600"


content : String
content =
    "w-full mx-auto px-2 h-screen-12 overflow-y-auto scrollbar-main scrollbar-thin"


sidebarLink : String
sidebarLink =
    " mb-2 px-4 py-3 flex flex-row hover:bg-blue-100 dark:hover:bg-bluegray-600 hover:font-bold rounded rounded-lg items-center "


successMessage : String
successMessage =
    " border border-green-600 bg-green-50 text-green-600 dark:border-lime-800 dark:bg-lime-300 dark:text-lime-800 px-4 py-2 rounded "


successMessageLink : String
successMessageLink =
    "text-green-700 hover:text-green-800 dark:text-lime-800 dark:hover:text-lime-700 underline "


errorMessage : String
errorMessage =
    " border border-red-600 bg-red-50 text-red-600 dark:border-orange-800 dark:bg-orange-300 dark:text-orange-800 px-2 py-2 rounded "


errorText : String
errorText =
    " text-red-600 dark:text-orange-800 "


warnMessage : String
warnMessage =
    warnMessageColors ++ " border dark:bg-opacity-25 px-2 py-2 rounded "


warnMessageColors : String
warnMessageColors =
    " border-yellow-800 bg-yellow-50 text-yellow-800 dark:border-amber-200 dark:bg-amber-800 dark:text-amber-200 "


infoMessage : String
infoMessage =
    " border border-blue-800 bg-blue-100 text-blue-800 dark:border-lightblue-200 dark:bg-lightblue-800 dark:text-lightblue-200 dark:bg-opacity-25 px-2 py-2 rounded "


message : String
message =
    " border border-gray-600 bg-gray-50 text-gray-600 "
        ++ "dark:border-bluegray-400 dark:bg-bluegray-600 dark:bg-opacity-80 dark:text-bluegray-400 "
        ++ "px-4 py-2 rounded "


greenSolidLabel : String
greenSolidLabel =
    " label border-green-500 bg-green-500 text-white dark:border-lime-800 dark:bg-lime-300 dark:text-lime-800 "


greenBasicLabel : String
greenBasicLabel =
    " label border-green-500 text-green-500 dark:border-lime-300 dark:text-lime-300 "


redSolidLabel : String
redSolidLabel =
    " label border-red-500 bg-red-500 text-white dark:border-orange-800 dark:bg-orange-200 dark:text-orange-800 "


redBasicLabel : String
redBasicLabel =
    " label border-red-500 text-red-500 dark:border-orange-200 dark:text-orange-200 "


basicLabel : String
basicLabel =
    " label border-gray-600 text-gray-600 dark:border-bluegray-300 dark:text-bluegray-300 "


blueBasicLabel : String
blueBasicLabel =
    " label border-blue-500 text-blue-500 dark:border-lightblue-200 dark:text-lightblue-200 "



--- Primary Button


primaryButton : String
primaryButton =
    primaryButtonRounded ++ primaryButtonPlain


primaryButtonPlain : String
primaryButtonPlain =
    primaryButtonMain ++ primaryButtonHover


primaryButtonMain : String
primaryButtonMain =
    " my-auto whitespace-nowrap bg-blue-500 dark:bg-lightblue-800 text-white text-center px-4 py-2 shadow-md focus:outline-none focus:ring focus:ring-opacity-75 "


primaryButtonHover : String
primaryButtonHover =
    " hover:bg-blue-600 dark:hover:bg-lightblue-700 "


primaryButtonRounded : String
primaryButtonRounded =
    " rounded "



--- Primary Basic Button


primaryBasicButton : String
primaryBasicButton =
    primaryBasicButtonMain ++ primaryBasicButtonHover


primaryBasicButtonMain : String
primaryBasicButtonMain =
    " rounded my-auto whitespace-nowrap border border-blue-500 dark:border-lightblue-500 text-blue-500 dark:text-lightblue-500 text-center px-4 py-2 shadow-md focus:outline-none focus:ring focus:ring-opacity-75 "


primaryBasicButtonHover : String
primaryBasicButtonHover =
    " hover:bg-blue-600 hover:text-white dark:hover:text-white dark:hover:bg-lightblue-500 "



--- Secondary Button


secondaryButton : String
secondaryButton =
    secondaryButtonMain ++ secondaryButtonHover


secondaryButtonMain : String
secondaryButtonMain =
    " rounded my-auto whitespace-nowrap bg-gray-300 dark:bg-bluegray-400 text-center px-4 py-2 shadow-md focus:outline-none focus:ring focus:ring-opacity-75 dark:text-gray-800 text-gray-800"


secondaryButtonHover : String
secondaryButtonHover =
    " hover:bg-gray-400 dark:hover:bg-bluegray-300 "


secondaryBasicButton : String
secondaryBasicButton =
    secondaryBasicButtonRounded ++ secondaryBasicButtonPlain


secondaryBasicButtonPlain : String
secondaryBasicButtonPlain =
    secondaryBasicButtonMain ++ secondaryBasicButtonHover


secondaryBasicButtonRounded : String
secondaryBasicButtonRounded =
    " rounded border px-4 py-2 "



--- Secondary Basic Button


secondaryBasicButtonMain : String
secondaryBasicButtonMain =
    " my-auto whitespace-nowrap border-gray-500 dark:border-bluegray-500 text-gray-500 dark:text-bluegray-400 text-center shadow-none focus:outline-none focus:ring focus:ring-opacity-75 "


secondaryBasicButtonHover : String
secondaryBasicButtonHover =
    " hover:bg-gray-600 hover:text-white dark:hover:text-white dark:hover:bg-bluegray-500 dark:hover:text-bluegray-100 "



--- Delete Button


deleteButton : String
deleteButton =
    deleteButtonMain ++ deleteButtonHover


deleteButtonMain : String
deleteButtonMain =
    " rounded my-auto whitespace-nowrap border border-red-500 dark:border-lightred-500 text-red-500 dark:text-orange-500 text-center px-4 py-2 shadow-none focus:outline-none focus:ring focus:ring-opacity-75 "


deleteButtonHover : String
deleteButtonHover =
    " hover:bg-red-600 hover:text-white dark:hover:bg-orange-500 dark:hover:text-bluegray-900 "


undeleteButton : String
undeleteButton =
    " rounded my-auto whitespace-nowrap border border-green-500 dark:border-lightgreen-500 text-green-500 dark:text-lightgreen-500 text-center px-4 py-2 shadow-none focus:outline-none focus:ring focus:ring-opacity-75 hover:bg-green-600 hover:text-white dark:hover:text-white dark:hover:bg-lightgreen-500 dark:hover:text-bluegray-900 "


deleteLabel : String
deleteLabel =
    "label my-auto whitespace-nowrap border border-red-500 dark:border-lightred-500 text-red-500 dark:text-orange-500 text-center focus:outline-none focus:ring focus:ring-opacity-75 hover:bg-red-600 hover:text-white dark:hover:text-white dark:hover:bg-orange-500 dark:hover:text-bluegray-900"



--- Others


link : String
link =
    " text-blue-400 hover:text-blue-500 dark:text-lightblue-200 dark:hover:text-lightblue-100 cursor-pointer "


inputErrorBorder : String
inputErrorBorder =
    " border-red-600 dark:border-orange-600 "


inputLabel : String
inputLabel =
    " text-sm font-semibold py-0.5 "


textInput : String
textInput =
    " placeholder-gray-400 w-full dark:text-bluegray-200 dark:bg-bluegray-800 dark:border-bluegray-500 border-gray-400 rounded " ++ formFocusRing


textInputSidebar : String
textInputSidebar =
    " w-full placeholder-gray-400 border-gray-400 bg-blue-50 dark:text-bluegray-200 dark:bg-bluegray-700 dark:border-bluegray-500 rounded " ++ formFocusRing


textAreaInput : String
textAreaInput =
    "block" ++ textInput


inputIcon : String
inputIcon =
    "absolute left-3 top-2 w-10 text-gray-400 dark:text-bluegray-400  "


dateInputIcon : String
dateInputIcon =
    "absolute left-3 top-3 w-10 text-gray-400 dark:text-bluegray-400  "


inputLeftIconLink : String
inputLeftIconLink =
    "inline-flex items-center justify-center absolute right-0 top-0 h-full w-10 rounded-r cursor-pointer "
        ++ "text-gray-400 dark:text-bluegray-400 "
        ++ "bg-gray-300 dark:bg-bluegray-700 "
        ++ "dark:border-bluegray-500 border-0 border-r border-t border-b border-gray-500 "
        ++ "hover:bg-gray-400 hover:text-gray-700 dark:hover:bg-bluegray-600"


inputLeftIconLinkSidebar : String
inputLeftIconLinkSidebar =
    "inline-flex items-center justify-center absolute right-0 top-0 h-full w-10 rounded-r cursor-pointer "
        ++ "text-gray-400 dark:text-bluegray-400 "
        ++ "bg-gray-300 dark:bg-bluegray-600 "
        ++ "dark:border-bluegray-500 border-0 border-r border-t border-b border-gray-500 "
        ++ "hover:bg-gray-400 hover:text-gray-700 dark:hover:bg-bluegray-500"


inputLeftIconOnly : String
inputLeftIconOnly =
    "inline-flex items-center justify-center absolute right-0 top-0 h-full w-10 rounded-r "
        ++ "dark:border-bluegray-500 border-0 border-r border-t border-b border-gray-500 "


checkboxInput : String
checkboxInput =
    " checkbox w-5 h-5 md:w-4 md:h-4 text-black  dark:text-bluegray-600 dark:bg-bluegray-600 dark:border-bluegray-700" ++ formFocusRing


formFocusRing : String
formFocusRing =
    " focus:ring focus:ring-black focus:ring-opacity-50 focus:ring-offset-0 dark:focus:ring-bluegray-400 "


radioInput : String
radioInput =
    checkboxInput


box : String
box =
    " border dark:border-bluegray-500 bg-white dark:bg-bluegray-800 shadow-md "


border : String
border =
    " border dark:border-bluegray-600 "


border2 : String
border2 =
    " border-2 dark:border-bluegray-600 "


header1 : String
header1 =
    " text-3xl mt-3 mb-3 sm:mb-5 font-semibold tracking-wide break-all"


header2 : String
header2 =
    " text-2xl mb-3 font-medium tracking-wide "


header3 : String
header3 =
    " text-xl mb-3 font-medium tracking-wide "


editLinkTableCellStyle : String
editLinkTableCellStyle =
    "w-px whitespace-nowrap pr-2 md:pr-4 py-4 md:py-2"


dimmer : String
dimmer =
    " absolute top-0 left-0 w-full h-full bg-black bg-opacity-90 dark:bg-bluegray-900 dark:bg-opacity-90 z-50 flex flex-col items-center justify-center px-4 md:px-8 py-2 "


dimmerLight : String
dimmerLight =
    " absolute top-0 left-0 w-full h-full bg-black bg-opacity-60 dark:bg-bluegray-900 dark:bg-opacity-60 z-30 flex flex-col items-center justify-center px-4 py-2 "


dimmerCard : String
dimmerCard =
    " absolute top-0 left-0 w-full h-full bg-black bg-opacity-60 dark:bg-lightblue-900 dark:bg-opacity-60 z-30 flex flex-col items-center justify-center px-4 py-2 "


tableMain : String
tableMain =
    "border-collapse table w-full"


tableRow : String
tableRow =
    "border-t dark:border-bluegray-600"


qrCode : String
qrCode =
    "max-w-min dark:bg-bluegray-400 bg-gray-50 mx-auto md:mx-0"
