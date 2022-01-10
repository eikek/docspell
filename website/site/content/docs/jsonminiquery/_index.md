+++
title = "JSON (mini) query"
[extra]
mktoc = true
hidden = true
+++

A "JSON mini query" is a simple expression that evaluates to `true` or
`false` for any given JSON value.

It is used in docspell to filter notification events.

The examples shown here assume the JSON at [the end of this
page](#sample-json).

# Structure

A json mini query is a sequence of "segments" where each one selects
contents from the "current result". The current result is always a
list of JSON values and starts out with a single element list
containing the given root JSON document.

When the expression is applied, it is read from left to right where
each segment is evaluated against the JSON. All results are always
aggregated into a single list which is handed to the next segment as
input. Each segment of the expression is always applied to every
element in the list.

The expression evaluates to `true` if the final result is non-empty
and to `false` otherwise. So the actual values selected at the and are
not really of interest. It only matters if the last result is the
empty list or not.

There are the following possible segments:

- selecting fields: `fieldname[,fieldname2,…]`
- selecting specific array elements: `(0[,1,…])`
- filter list of nodes against given values: `=some-value`,
  `!some-value`
- combining the above (sequence, `&` and `|`)


## Field selection

The simplest segment is just a field name. It looks up the field name
in the current JSON result and replaces each element in the result
with the value at that field.

```
query: a
current result: [{"a":1,"b":2}, {"a":5, "b":2}]
next result: [1, 5]
```

You can select multiple fields at once by separating names by comma.
This simply combines all results into a list:

```
query: a,b
current result: [{"a":1,"b":2}, {"a":5, "b":2}]
next result: [1, 2, 5, 2]
```

You can use dot-notation combining several field selection segments to
select elements deeper in the JSON:

```
query: a.b.x,y
current result:
  [{"a": {"b": {"x": 1, "y": 2}}, "v": 0},
   {"a": {"b": {"y": 9, "b": 2}}, "z": 0}]
next result: [1, 2, 9]
```


## Array selection

When looking at an array, you can select specific elements by their
indexes. To distinguish it from field selection, you must surround it
by parens:

```
query: (0,2)
current result: [[1,2,3,4]]
next result: [1,3]
```

If you combine field selection and array selection, keep in mind that
a previous field selection combines both arrays into one before array
selection is used!

```
query: a(0,2)
current result: [{"a": [10,9,8,7]}, {"a": [1,2,3,4]}]
next result: [10,8]
```


## Matching Values

You can filter elements of the current result based on their value.
This only works for primitive elements.

- equals (case insensitive): `=`
- not equals (case insensitive): `!`

Values can be given either as a simple string or, should it contain
whitespace or brackets/parens, you need to enclose it either in single
or double quotes. If you want to check for `null` use the special
`*null*` value.

The match will be applied to all elements in the current result and
filters out those that don't match.

```
query: =blue
current result: ["blue", "green", "red"]
next result: ["blue"]
```

```
query: color=blue
current result:
    [{"color": "blue", "count": 2},
     {"color": "blue", "count": 1},
     {"color": "red", "count": 3}]
next result:["blue", "blue"]
```

## Combining

The above expressions can be combined by writing one after the other,
sequencing them. This has been shown in some examples above. The next
segment will be applied to the result of the previous segment. When
sequencing field names they must be separated by a dot.

Another form is to combine several expressions using `&` or `|`. The
results of all sub expressions will be concatenated into a single
list. When using `&`, results are only concatenated if all lists are
not empty; otherwise the result is the empty list.

This example filters all `count` equal to `6` and all `name` equal to
`max`. Since there are no `count`s with value `6`, the final result is
empty.

```
query: [count=6 & name=max]
current result:
  [{"name":"max", "count":4},
   {"name":"me", "count": 3},
   {"name":"max", "count": 3}
  ]
next result: []
```

Using `|` for combining lets all the `max` values through:

```
query: [count=6 & name=max]
current result:
  [{"name":"max", "count":4},
   {"name":"me", "count": 3},
   {"name":"max", "count": 3}
  ]
next result: ["max", "max"]
```

## Example walkthrough

Let's look at an example:

```
content.added,removed[name=Invoice | category=expense]
```

Starting out with the root JSON document, a list is created containing
it as the only element:

```
( {"eventType": "TagsChanged", "content: {…}, …} )
```

Then the field `content` is selected. This changes the list to contain
this sub-document:

```
( {"account": "demo", "added":[…], "removed":[…], …} )
```

Then two fields are selected. They both select arrays. Both results
are combined into a single list and arrays are flattened. So the
result after `content.added,removed` looks like this:

```
( {"id":"Fy4…",name="…",category="…"}, {"id":"7zae…",…}, {"id":"GbXg…",…} )
```

At last, the remaining elements are filtered. It resolve all `name`
fields and keeps only `invoice` values. It also resolves `category`
and keeps only `expense` values. Both lists are then concatenated into
one. The final result is then `["Invoice", "expense"]`, which matches
the sample json data below.


# Sample JSON

Some examples assume the following JSON:

```json
{
  "eventType": "TagsChanged",
  "account": {
    "collective": "demo",
    "user": "demo",
    "login": "demo"
  },
  "content": {
    "account": "demo",
    "items": [
      {
        "id": "4PvMM4m7Fwj-FsPRGxYt9zZ-uUzi35S2rEX-usyDEVyheR8",
        "name": "MapleSirupLtd_202331.pdf",
        "dateMillis": 1633557740733,
        "date": "2021-10-06",
        "direction": "incoming",
        "state": "confirmed",
        "dueDateMillis": 1639173740733,
        "dueDate": "2021-12-10",
        "source": "webapp",
        "overDue": false,
        "dueIn": "in 3 days",
        "corrOrg": "Acme AG",
        "notes": null
      }
    ],
    "added": [
      {
        "id": "Fy4VC6hQwcL-oynrHaJg47D-Q5RiQyB5PQP-N5cFJ368c4N",
        "name": "Invoice",
        "category": "doctype"
      },
      {
        "id": "7zaeU6pqVym-6Je3Q36XNG2-ZdBTFSVwNjc-pJRXciTMP3B",
        "name": "Grocery",
        "category": "expense"
      }
    ],
    "removed": [
      {
        "id": "GbXgszdjBt4-zrzuLHoUx7N-RMFatC8CyWt-5dsBCvxaEuW",
        "name": "Receipt",
        "category": "doctype"
      }
    ],
    "itemUrl": "http://localhost:7880/app/item"
  }
}
```
