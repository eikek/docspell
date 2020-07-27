+++
title = "ISO8601 vs Millis as Date-Time transfer"
weight = 50
+++

# Context and Problem Statement

The question is whether the REST Api should return an ISO8601
formatted string in UTC timezone, or the unix time (number of
milliseconds since 1970-01-01).

There is quite some controversy about it.

- <https://stackoverflow.com/questions/47426786/epoch-or-iso8601-date-format>
- <https://nbsoftsolutions.com/blog/designing-a-rest-api-unix-time-vs-iso-8601>

In my opinion, the ISO8601 format (always UTC) is better. The reason
is the better readability. But elm folks are on the other side:

- <https://package.elm-lang.org/packages/elm/time/1.0.0#iso-8601>
- <https://package.elm-lang.org/packages/rtfeldman/elm-iso8601-date-strings/latest/>

One can convert from an ISO8601 date-time string in UTC time into the
epoch millis and vice versa. So it is the same to me. There is no less
information in a ISO8601 string than in the epoch millis.

To avoid confusion, all date/time values should use the same encoding.

# Decision Outcome

I go with the epoch time. Every timestamp/date-time values is
transfered as Unix timestamp.

Reasons:

- the Elm application needs to frequently calculate with these values
  to render the current waiting time etc. This is better if there are
  numbers without requiring to parse dates first
- Since the UI is written with Elm, it's probably good to adopt their
  style
