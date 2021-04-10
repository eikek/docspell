module Messages.Comp.UserManage exposing (..)

import Messages.Basics
import Messages.Comp.UserForm
import Messages.Comp.UserTable


type alias Texts =
    { userTable : Messages.Comp.UserTable.Texts
    , userForm : Messages.Comp.UserForm.Texts
    , users : String
    , newUser : String
    , addNewUser : String
    , reallyDeleteUser : String
    , createNewUser : String
    , basics : Messages.Basics.Texts
    , deleteThisUser : String
    , pleaseCorrectErrors : String
    }


gb : Texts
gb =
    { userTable = Messages.Comp.UserTable.gb
    , userForm = Messages.Comp.UserForm.gb
    , basics = Messages.Basics.gb
    , users = "Users"
    , newUser = "New user"
    , addNewUser = "Add new user"
    , reallyDeleteUser = "Really delete this user?"
    , createNewUser = "Create new user"
    , deleteThisUser = "Delete this user"
    , pleaseCorrectErrors = "Please correct the errors in the form."
    }


de : Texts
de =
    gb
