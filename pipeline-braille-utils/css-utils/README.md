css-utils
=========

Building blocks related to [Braille CSS][braillecss].

[library.xsl](src/main/resources/xml/library.xsl)
-------------------------------------------------

- Utility functions for CSS-parsing.

[library.xpl](src/main/resources/xml/library.xpl)
-------------------------------------------------

- `css:eval-content-list`
- `css:eval-counter`
- `css:eval-string-set`
- `css:inline`: Inline a CSS stylesheet in XML.
- `css:label-anchors`
- `css:make-anonymous-block-boxes`
- `css:make-anonymous-inline-boxes`
- `css:make-boxes`
- `css:make-pseudo-elements`
- `css:new-definition`
- `css:padding-to-margin`
- `css:parse-counter-set`
- `css:parse-declaration-list`
- `css:parse-stylesheet`
- `css:preserve-white-space`
- `css:repeat-string-set`
- `css:shift-string-set`
- `css:split`

Submodules
----------

- [`css-core`](../css/css-core): CSS specification.
- [`css-calabash`](../css/css-calabash): XProc bindings.


[braillecss]: http://snaekobbi.github.io/braille-css-spec