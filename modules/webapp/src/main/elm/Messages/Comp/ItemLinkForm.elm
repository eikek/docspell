module Messages.Comp.ItemLinkForm exposing (Texts, de, fr, gb)

import Data.Direction exposing (Direction)
import Data.TimeZone exposing (TimeZone)
import Http
import Messages.Comp.HttpError
import Messages.Comp.ItemSearchInput
import Messages.Data.Direction
import Messages.DateFormat as DF
import Messages.UiLanguage exposing (UiLanguage(..))


type alias Texts =
    { dateFormatLong : Int -> String
    , dateFormatShort : Int -> String
    , directionLabel : Direction -> String
    , itemSearchInput : Messages.Comp.ItemSearchInput.Texts
    , httpError : Http.Error -> String
    }


gb : TimeZone -> Texts
gb tz =
    { dateFormatLong = DF.formatDateLong English tz
    , dateFormatShort = DF.formatDateShort English tz
    , directionLabel = Messages.Data.Direction.gb
    , itemSearchInput = Messages.Comp.ItemSearchInput.gb
    , httpError = Messages.Comp.HttpError.gb
    }


de : TimeZone -> Texts
de tz =
    { dateFormatLong = DF.formatDateLong German tz
    , dateFormatShort = DF.formatDateShort German tz
    , directionLabel = Messages.Data.Direction.de
    , itemSearchInput = Messages.Comp.ItemSearchInput.de
    , httpError = Messages.Comp.HttpError.de
    }


fr : TimeZone -> Texts
fr tz =
    { dateFormatLong = DF.formatDateLong French tz
    , dateFormatShort = DF.formatDateShort French tz
    , directionLabel = Messages.Data.Direction.fr
    , itemSearchInput = Messages.Comp.ItemSearchInput.fr
    , httpError = Messages.Comp.HttpError.fr
    }
