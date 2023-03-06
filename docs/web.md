# Web

The end result is a diagram which shows _Images_, contained by _Repositories_. These _Images_ point towards other _Images_, which they extend.

To create this diagram, two sources need to be provided:

1. A list of _Repositories_ and which _Images_ they use
2. A list of _Images_ and which _Repositories_ they come from

These sources are JSON files, created by the scripts in `cli/`.

The web app generates JSON containing all the information required to generate the diagram. The diagram itself is created using [PlantUML](https://plantuml.com/).

The main reason these steps are separated, is to allow the created JSON to be edited manually. This makes it easier to correct mistakes and allows customization.


 - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -


Docker Aliases

```
Imagine:
     FROM A  AS  B
     FROM B  AS  C
     COPY --from C

Given:
     C -> B -> A

Should be:
     C -> A

So for:
     images['A', 'B', 'C]

To become:
     images['A', 'A', 'A]

This:
     aliases{
         'B' => 'A'
         'C' => 'B'
     }

Has to become:
     aliases{
         'B' => 'A'
         'C' => 'A'
     }
 ```
