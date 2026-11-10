# geo

A small library of coordinate helpers used by other projects.

```python
from geo import parse_point, distance_km
paris = parse_point("48.8566,2.3522")
london = parse_point("51.5074,-0.1278")
print(round(distance_km(paris, london)))   # 343
```

`parse_point` returns `None` for text that is not a point; callers check for it.
Run the tests with `python3 -m unittest`.
