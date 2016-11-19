# NAME

Template::Plugin::Gettext - Gettext Support For the Template Toolkit Version 2

# SYNOPSIS

Load the plug-in in templates:

    [% USE Gettext('com.textdomain.my' 'utf-8' 'DIRECTORIES'...) %]
    [% Gettext.gettext('Hello, world!) %]

Or alias "Gettext":

    [% USE gtx = Gettext('com.textdomain.my' 'utf-8' 'DIRECTORIES'...) %]
    [% gtx.gettext('Hello, world!) %]

Use method invocations:

    [% Gettext.gettext("Hello, world!") %]
    [% Gettext.xgettext("Hello, {name}!", name => 'John Doe') %]

Or filters:

    [% FILTER gettext %]
    Hello, world!
    [% END %]

    [% FILTER xgettext(name => 'John Doe') %]
    Hello, {name}!
    [% END %]

# DESCRIPTION

The **Template::Plugin::Gettext** plug-in makes the
[GNU gettext API](https://www.gnu.org/software/gettext/) available for
documents using the
[Template Toolkit version 2](http://template-toolkit.org/).
