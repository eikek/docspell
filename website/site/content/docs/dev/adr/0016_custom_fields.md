+++
title = "Custom Fields"
weight = 170
+++

# Context and Problem Statement

Users want to add custom metadata to items. For example, for invoices
fields like `invoice-number` or `total`/`amount` make sense. When
using a pagination stamp, every item gets a pagination number.

This is currently not possible to realize in docspell. But it is an
essential part when organizing and archiving documents. It should be
supported.


# Considered Options

## Requirements

- Fields have simple types: There is a difference in presenting a
  date, string or number. At least some simple types should be
  distinguishable for the UI to make it more convenient to use.
- An item can have at most one value of a field: The typical example
  is `invoice number` – it doesn't make sense to be able to specify
  two invoice-numbers on an item. If still necessary, one can create
  artificial fields like `invoice-number-1` and `invoice-number-2`.
- Fulltext Index: should custom field values be sent to the full-text
  index?
  - This is not required, imho. At least not for a start.
- Fields are stored per collective. When creating a new field, user
  can select from existing ones to avoid creating same fields with
  different names.
- Fields can be managed: Rename, change type, delete. Show fields that
  don't have any value associated and could be deleted.

## Ideas

### Database

Initial sketch:

``` sql
CREATE TABLE custom_field (
  id varchar(244) not null primary key,
  name varchar(100) not null,
  cid varchar(254) not null,
  ftype varchar(100) not null,
  foreign key "cid" references collective(cid),
  unique (cid, name)
);

CREATE TABLE custom_field_item_value (
  id varchar(254) not null primary key,
  item_id varchar(254) not null,
  field varchar(254) not null,
  field_value varchar(254),
  foreign key item_id references item(id),
  foreign key field references custom_field(id),
  unique (item_id, field) -- only one value allowed per item
)
```

- field carries the type in the column `ftype`. type is an enum:
  `text`, `numeric`, `date`, `money`, `bool`
- the type is just some constant, the database doesn't care and can't
  enforce anything
- the field name is unique per collective
- a value to a field can only exist on an item
- only one value per item can be created for one field
- the values are represented as a string in the database
- the application is responsible for converting into a string
- date is a local date, the iso format is used (e.g. `2020-08-11`)
- Why not each type a separate column, like `value_str`, `value_date`
  etc?
  - making them different requires to fetch all fields first before
    running a query, in order to know which columns to check
    - usually the query would look like this: `my_field_1 == "test"`;
      in order to know what column to check for `my_field_1`, a query
      to fetch the field must be done first. Only then the type is
      known and its clear what column to use for the value. This
      complicates searching and increases query count.
  - The value must be present (or converted) into the target type
  - It's a lot simpler for the implementation to reduce every custom
    field to a string value at the database. Type-specific queries
    (like avg, sum etc) can still be done using sql `CAST` function.

Changing Type:
- change the type on the `custom_field` table
- the string must be convertible to the new type, which must be
  ensured by the application

Adding more types:
- ammend the `ftype` enum with a new value and provide conversion
  functions

### REST Api

- the known field types must be transferred to the ui
- the ui creates custom presentation for date, money etc

Input 1:
- setting one value for a specific field. The server knows its type
  and converts accordingly (e.g. string->date)
- json only knows number, strings and bools (and null).
- make a structure to allow to specify all json types:
  ``` elm
  { value_str: Maybe String
  , value_num: Maybe Float
  , value_bool: Maybe Bool
  }
  ```
- con: setting all to `Nothing` is an error as well as using the wrong
  field with some type (e.g. setting `value_str` for setting a
  `numeric` field)
- con: very confusing – what to use for fields of type "date" or
  "money"?
- client needs some parsing anyways to show errors

Input 2:
- send one value as a string
  ```elm
  { value: String
  }
  ```
- string must be in a specific format according to its type. server
  may convert (like `12.4999` → `12.49`), or report an error
- client must create the correct string


Output:
- server sends field name, type and value per custom field. Return an
  array of objects per item.

Searching:
- UI knows all fields of a collective: user selects one in a dropdown
  and specifies the value


# Decision Outcome

- values are strings at the database
- values are strings when transported from/to server
- client must provide the correct formatted strings per type
  - numeric: some decimal number
  - money: decimal number
  - text: no restrictions
  - date: a local date as iso string, e.g. `2011-10-09`
  - bool: either `"true"` or `"false"`, case insensitive

## Initial Version

- create the database structure and a REST api to work with custom
  fields
- create a UI on item detail to add/set custom fields
- show custom fields on item detail
- create a page to manage fields: only rename and deletion
- extend the search for custom fields
- show custom fields in search results
