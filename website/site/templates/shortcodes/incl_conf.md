{% set data = load_data(path=path) %}
``` bash
{{ data | safe }}
```
