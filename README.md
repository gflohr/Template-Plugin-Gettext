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

```html
    [% USE gtx = Gettext('com.mydomain.www', lang) %]

    <title>[% gtx.gettext("World Of Themes") %]</title>
    
    <h1>[% "Introduction" | gettext %]

    <p>
    [% FILTER gettext %]
    The "World Of Themes" is the ultimate source of templates
    for the Template Toolkit.
    [% END %]
    </p>
```

This shows three different ways of localizing strings.  You can
use the function `gtx.gettext()`, the filter `gettext` with pipe
syntax, or the same filter with block syntax.  The result is always
the same.  The string will be recognized as translatable by 
`xgettext-tt2` and it will be translated into the selected language,
when rendering the template.

#### Interpolating Strings Into Translations

One important thing to understand is that the argument to the
gettext functions or filters is the lookup key into the translation
database, when the template gets rendered.  That implies that this
key has to be invariable and must not use any interpolated variables.

```html
    [% USE gtx = Gettext('com.mydomain.www', lang) %]

    [% gtx.gettext("Hello, $firstname $lastname!") %]
```

This template code is syntactically correct and will also render
correctly.  But `xgettext-tt2` will bail out on it with an error
message like

    templates.html:3: Illegal variable interpolation at "$"

The function `gettext()` will receive the interpolated string
as its argument, and that is not the same as the string that
the extractor program `xgettext-tt2` sees.  And that means that
the translation cannot be found.

The correct way to interpolate strings uses `xgettext()`:

```html
    [% USE gtx = Gettext('com.mydomain.www', lang) %]

    [% gtx.xgettext("Hello, {first} {last}!",
                    first => firstname, last => lastname) %]
    [% "Hello, {first} {last}!" | xgettext(first => firstname, 
                                           last => lastname) %]
    [% FILTER xgettext(first => firstname, last => lastname) %]
    Hello, {first} {last}!
    [% END %]
```

One additional benefit of this is that the extractor program
`xgettext-tt2` will also mark these strings with the flag
"perl-brace-format".  When the translation from the `.po`
file gets compiled into an `.mo` file, the compiler `msgfmt`
checks that the translated strings contains exactly the same
placeholders as the original.

One thing that you should also avoid is to assemble strings
in the template source code.  Do *not*:

```html
    [% gtx.gettext("Please contact") %] [% name %]
    [% gtx.gettext("for help about the") %] [% package %]
    [% gtx.gettext("software.") %]
```

This will result in three translatable text snippets
"Please contact", "for help about the", and "software." that
are hard to translate without context.  Besides it makes
illegal assumptions about the word order in translated sentences.
Instead, use `xgettext()` and write in complete sentences with
placeholders.

#### Plural Forms

Do *not* write this:

```html
    [% IF num != 1 %]
    [% gtx.xgettext("{number} documents deleted!", number => num) %]
    [% ELSE %]
    [% gtx.gettext("One document deleted!") %]
    [% END %]
```

This assumes that every language has one singular and one plural
(and no other forms) and that the condition that selects the correct
form is always `COUNT != 1`.  But this is wrong for many languages
for example Russian (two plural forms), Chinese (no plural), French
(different condition), and many more.

Write instead:

```html
    [% USE gtx = Gettext('com.mydomain.www', lang) %]

    [% gtx.nxgettext("One document deleted.", 
                     "{count} documents deleted."
                     num,
                     count => num) %]
```

The function `nxgettext()` receives the singular and plural
form as the first and second argument, followed by the number
of items, followed by an arbitrary number of key/value pairs
for interpolating variables in the strings.

There is also a function `ngettext()` that does not expand
its two first arguments.  You will find out that you almost
never need that function.

You can also use `nxgettext()` and `ngettext()` as filters.
But the necessary code is awkward, and their use is therefore
not recommended.

#### Ambiguous Strings (message contexts)

Sometimes an English string has different meanings in other
languages:

```html
    [% USE gtx = Gettext('com.mydomain.www', lang) %]

    [% gtx.gettext("State:") %]
    [% IF state == '1' %]
    [% gtx.pgettext("state", "Open") %]
    [% ELSE %]
    [% gtx.gettext("Closed") %]
    [% END %]
    <a href="/action/open">[% gtx.pgettext("action", "Open") %]</a>
```

The function `pgettext()` works like gettext but has one 
extra argument preceding the string, the so-called
message context.  The string extractor `xgettext-tt2` will now
create two distinct messages "Open", one with the context "state",
the other one with the context "action".  The sole purpose of this
context is to disambiguate the string "Open" for languages where the
verb ("to open") and the adjective ("the door is *open*") has
two distinct translations.

You will normally use this function, when a translator asks you
to do so, but not on your own behalf.

There is also a function `pxgettext()` that supports placeholder
interpolation, and `npxgettext()` that has the following semantics:

```perl
    npxgettext(CONTEXT, SINGULAR, PLURAL, COUNT,
               KEY1 => VALUE1, KEY2 => VALUE2, ...)
```

#### More Esoteric Functions

The [API documentation](lib/Template/Plugin/Gettext.pod) contains
some more functions and filters that are available for completeness.
You will never need them in normal projects.

#### Translator Hints

You can add comments to the source code that are copied into the
`.po` file as hints for the translators.  This will look like
this:

```html
    [% USE gtx = Gettext('com.mydomain.www', lang) %]

    <!-- TRANSLATORS: This is the day of the week! -->
    [% gtx.gettext("Sun") %]
```

In order to make that work, you have to invoke the extractor
program `xgettext-tt2` like this:

    xgettext-tt2 --add-comments=TRANSLATORS: t1.html t2.html ...

#### Modifying Flags

In rare situations, you may need the following:

```html
    [% USE gtx = Gettext('com.mydomain.www', lang) %]

    <!-- xgettext:no-perl-brace-format -->
    [% gtx.xgettext("Value: {value}", value => whatever) %]
```

Normally, the argument of `xgettext()` will be flagged in
the `.po` file with "perl-brace-format", and a translation
will fail to compile if the translation does not contain exactly
the same placeholders as the original does.

You can override that default behavior for individual messages
by placing a comment containing the string "xgettext:" directly
in front of the string.

