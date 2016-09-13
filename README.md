# Template-Plugin-Gettext

Localization for the Template Toolkit 2

## Status

Pre-alpha, incomplete.

## Description

This Perl library offers a complete solution for the Template Toolkit 2.
It consists of a plugin that offers translation functions inside templates
and a string extractor `xgettext_tt` that extracts translatable strings
from templates and writes them to PO files (or rather a `.pot` file in PO
format).

## Usage

The solution offered by this library is suitable for templates that have
a lot of markup (normally HTML) compared to text.  If the files contain
a lot of content other solutions are probably more suitable.  One of them
is [xml2po](https://github.com/mate-desktop/mate-doc-utils/tree/master/xml2po),
especially if the input format is HTML.

If the input format is Markdown, for example for a static side generator,
a feasible approach may be to simply split the input into paragraphs, and
turn each paragraph into an entry of a PO file.
