# Web

The web application takes two JSON files as input (created by the scripts in `cli/`). It then generates JSON, which is used to create a diagram. The diagram itself is created using [PlantUML](https://plantuml.com/).

The main reason these steps are separated, is to allow the created JSON to be edited manually. This makes it easier to correct mistakes and allows customization.
