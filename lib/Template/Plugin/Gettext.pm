#! /bin/false

# Copyright (C) 2016 Guido Flohr <guido.flohr@cantanea.com>,
# all rights reserved.

# This program is free software; you can redistribute it and/or modify it
# under the terms of the GNU Library General Public License as published
# by the Free Software Foundation; either version 2, or (at your option)
# any later version.

# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU
# Library General Public License for more details.

# You should have received a copy of the GNU Library General Public
# License along with this program; if not, write to the Free Software
# Foundation, Inc., 59 Temple Place - Suite 330, Boston, MA 02111-1307,
# USA.

package Template::Plugin::Gettext;

use strict;

our $VERSION = 0.1;

use Locale::TextDomain qw(com.cantanea.Template-Plugin-Gettext);
use Locale::Messages;
use Locale::Util qw(web_set_locale);

use Cwd qw(abs_path);

use base qw(Template::Plugin);

my %bound_dirs;
my @default_dirs;

sub __find_domain($);
sub __expand($%);

BEGIN {
    foreach my $dir (qw('/usr/share/locale /usr/local/share/locale')) {
        if (-d $dir) {
            push @default_dirs , $dir;
            last;
        }
    }
}

sub new {
    my ($class, $ctx, $textdomain, $language, $charset, @search_dirs) = @_;

    my $self = bless {}, $class;

    $textdomain = 'textdomain' unless defined $textdomain && length $textdomain;

    unless (exists $bound_dirs{$textdomain}) {
        @search_dirs = map $_ . '/LocaleData', @INC, @default_dirs
            unless @search_dirs;
        $bound_dirs{$textdomain} = [@search_dirs];
    }

    web_set_locale $language, $charset if defined $language;

    $self->{__textdomain} = $textdomain;

    $ctx->define_filter(gettext => sub {
        my ($context) = @_;

        return sub {
            return __gettext($textdomain, shift);
        };
    }, 1);
    $ctx->define_filter(xgettext => sub {
        my ($context, @args) = @_;
        my $pairs = ref $args[-1] eq 'HASH' ? pop(@args) : {};

        push @args, %$pairs;
        return sub {
            return __xgettext($textdomain, shift, @args);
        };
    }, 1);

    return $self;
}

sub __gettext {
    my ($textdomain, $msgid) = @_;

    __find_domain $textdomain
        if defined $textdomain && exists $bound_dirs{$textdomain};

    return Locale::Messages::dgettext($textdomain => $msgid);
}

sub gettext {
    my ($self, $msgid) = @_;

    return __gettext $self->{__textdomain}, $msgid;
}

sub __xgettext {
    my ($textdomain, $msgid, %vars) = @_;

    __find_domain $textdomain
        if defined $textdomain && exists $bound_dirs{$textdomain};

    return __expand((Locale::Messages::dgettext($textdomain => $msgid)), %vars);
}

sub xgettext {
    my ($self, $msgid, @args) = @_;
 
    my $pairs = ref $args[-1] eq 'HASH' ? pop(@args) : {};
    push @args, %$pairs;

    return __xgettext $self->{__textdomain}, $msgid, @args;
}

sub __expand($%) {
    my ($str, %vars) = @_;

    my $re = join '|', map { quotemeta } keys %vars;
    $str =~ s/\{($re)\}/exists $vars{$1} ? 
        (defined $vars{$1} ? $vars{$1} : '') : "{$1}"/ge;

    return $str;
}

sub __find_domain($) {
    my ($domain) = @_;

    my $try_dirs = $bound_dirs{$domain};

    if (defined $try_dirs) {
        my $found_dir = '';

        TRYDIR: foreach my $dir (map {abs_path $_} grep { -d $_ } @$try_dirs) {
            # Is there a message catalog?

            local *DIR;
            if (opendir DIR, $dir) {
                 my @files = map { "$dir/$_/LC_MESSAGES/$domain.mo" }
                             grep { ! /^\.\.?$/ } readdir DIR;
                 foreach my $file (@files) {
                     if (-f $file || -l $file) {
                         $found_dir = $dir;
                         last TRYDIR;
                     }
                 }
            }
        }

        # If $found_dir is undef, the default search directories are
        # used.
        Locale::Messages::bindtextdomain($domain => $found_dir);
    }

    delete $bound_dirs{$domain};

    return 1;
}

1;

=head1 NAME

Template::Plugin::Gettext - Gettext Support For the Template Toolkit Version 2

=head1 SYNOPSIS

In your templates:

    [% USE gettext(com.textdomain.my utf-8 DIRECTORIES...) %]

=head1 DESCRIPTION


