module Messages.CustomFieldMultiInputComp exposing (..)

import Messages.CustomFieldInputComp


type alias Texts =
    { customFieldInput : Messages.CustomFieldInputComp.Texts
    }


gb : Texts
gb =
    { customFieldInput = Messages.CustomFieldInputComp.gb
    }
