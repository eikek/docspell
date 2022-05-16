{% set data = load_data(path=path) %}
``` json
{{ data | safe }}
```
