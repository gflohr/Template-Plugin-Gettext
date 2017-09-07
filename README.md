# Template-Plugin-Gettext

Localization for the Template Toolkit 2

## Description

This Perl library offers a complete solution for the Template Toolkit 2.
It consists of a plugin that offers translation functions inside templates
and a string extractor `xgettext-tt2` that extracts translatable strings
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

In the following, we will assume that you have decided to localize
templates with this library.

### Templates

The first step is to mark all translatable strings.  This serves
a double purpose.  Strings are marked, so that the extractor 
`xgettext-tt2` can find them and write them into a translation file 
in PO format.

The second purpose is that these markers are also valid functions
resp. filters for the template toolkit and will interpolate the
translations for these messages into the output, when rendering the
template.  As a result, your templates remain pretty readable after
localizing them.

In every source file that you want to use translations, you have
to `USE` the template:

    [% USE gtx = Gettext('com.mydomain.www', 'fr') %]

Do *not* forget to `USE` the plug-in in all templates!  The template
toolkit will not warn you, when you forget it but the translation 
mechanism will not work!

The first argument is the so-called *textdomain*.  This is the
identifier for your message catalogs and also the basename of several
files.  In the example above, the translated message catalog would
be searched as *`LOCALEDIR`*`/fr/LC_MESSAGES/com.mydomain.www.mo`. The second parameter is the language.  This will normally come from
a variable instead of a hard-coded string.

A possible third argument (omitted in the example) is the character
set to use, all following arguments are additional directories to
search first for translations.

The default list of directories is:

* `./locale`
* `/usr/share/locale`
* `/usr/local/share/locale`

The directory `./locale` is relative to the current working directory
from where you invoke the template processor.

#### Simple Translations With `gettext()`

The simplest and most common way of doing things is:

    [% USE gtx = Gettext('com.mydomain.www', lang) %]

    <title>[% gtx.gettext("World Of Themes") %]</title>
    
    <h1>[% "Introduction" | gettext %]

    <p>
    [% FILTER gettext %]
    The "World Of Themes" is the ultimate source of templates
    for the Template Toolkit.
    [% END %]
    </p>

This shows three different ways of localizing strings.  You can
use the function `gtx.gettext()`, the filter `gettext` with pipe
syntax the same filter with block syntax.  The result is always
the same.  The string will be recognized as translatable by `xgettext-tt2` and it will be translated into the selected language,
when rendering the template.

