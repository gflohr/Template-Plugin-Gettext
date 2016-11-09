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

package Locale::XGettext::TT2;

use strict;

use Locale::TextDomain qw(Template-Plugin-Gettext);
use Template;

use base qw(Locale::XGettext);

sub versionInformation {
    return __x('{program} (Template-Plugin-Gettext) {version}
Copyright (C) {years} Cantanea EOOD (http://www.cantanea.com/).
License GPLv3+: GNU GPL version 3 or later <http://gnu.org/licenses/gpl.html>
This is free software: you are free to change and redistribute it.
There is NO WARRANTY, to the extent permitted by law.
Written by Guido Flohr (http://www.guido-flohr.net/).
',
    program => $0, years => 2016, version => $Locale::XGettext::VERSION);
}

sub fileInformation {
    return __(<<EOF);
Input files are interpreted as plain text files with each paragraph being
a separately translatable unit.  
EOF
}

sub canExtractAll {
    shift;
}

sub canKeywords {
    shift;
}

sub __addLocation {
	my ($self, $entry, $filename) = @_;

    my $new_ref = "$filename:$entry->{__xgettext_tt_lineno}";
    
    my $reference = $entry->reference;
    my @lines = split "\n", $reference;
    if (!@lines) {
    	push @lines, $new_ref;
    } else {
    	my $last_line = $lines[-1];
    	my $ref_length = 1 + length $new_ref;
    	if ($ref_length > 76) {
    		push @lines, $new_ref;
    	} elsif ($ref_length + length $last_line > 76) {
    		push @lines, $new_ref;
    	} else {
    		$lines[-1] .= ' ' . $new_ref;
    	}
    }
    
    $entry->reference(join "\n", @lines);
    
    return $self;
}

sub __getEntriesFromFile {
	my ($self, $filename) = @_;

    my %options = (
        INTERPOLATE => 1,
        RELATIVE => 1
    );
    
    my $parser = Locale::XGettext::TT2::Parser->new(\%options);
    
    my $tt = Template->new({
        %options,
        PARSER => $parser,
    });
 
    my $sink;
    $parser->{__xgettext}->{options} = $self->{__options};
    
    $tt->process($filename, {}, \$sink) or die $tt->error;

    my $entries = $parser->__xgettextEntries;
    
    return $entries;
}

package Locale::XGettext::TT2::Parser;

use base qw(Template::Parser);

use strict;

sub split_text {
    my ($self, $text) = @_;

    my %functions = (
        gettext => [qw(s)],
        ngettext => [qw(s p)],
        pgettext => [qw(c s)],
        npgettext => [qw(c s p)],
        xgettext => [qw(s)],
        nxgettext => [qw(s p)],
        pxgettext => [qw(c s)],
        npxgettext => [qw(c s p)],
    );
    my %properties = (
        s => 'msgid',
        p => 'msgid_plural',
        c => 'msgctxt',
    );

    sub extract_args {
        my ($tokens, $offset, $function) = @_;

        return if $offset >= @$tokens;
        my $schema = $functions{$function};

        return if '(' ne $tokens->[$offset];
        $offset += 2;

        my $entry = Locale::PO->new;
        foreach my $type (@$schema) {
            return if $offset >= @$tokens;

            if ('LITERAL' eq $tokens->[$offset]) {
                my $string = substr $tokens->[$offset + 1], 1, -1;
                $string =~ s/\\([\\'])/$1/gs;
                my $method = $properties{$type};
                $entry->$method($string);
                
                $offset += 2;

                if ($type ne $schema->[-1]) {
                    return if $offset >= @$tokens;
                    return if 'COMMA' ne $tokens->[$offset];
                    $offset += 2;
                }
            } elsif ('"' eq $tokens->[$offset]) {
                $offset += 2;
                return if $offset >= @$tokens;
                return if 'TEXT' ne $tokens->[$offset];
                my $method = $properties{$type};
                $entry->$method($tokens->[$offset + 1]);
                
                $offset += 4;
            } else {
                return;
            }
        }

        if (defined $entry->msgid_plural && length $entry->msgid_plural) {
            $entry->msgstr_n({0 => '', 1 => ''});
        } else {
            $entry->msgstr('');       	
        }

        # We ignore excess elements.

        return $entry;
    }

    my $chunks = $self->SUPER::split_text($text) or return;

    my $entries = Locale::XGettext::TT2::POEntries->new;
    
    my $options = $self->{__xgettext}->{options};
    
    my $ident;
    foreach my $chunk (@$chunks) {
         my ($text, $lineno, $tokens) = @$chunk;

         next if !ref $tokens;

         if ('USE' eq $tokens->[0] && 'IDENT' eq $tokens->[2]) {
             if ('Gettext' eq $tokens->[3]
                 && (4 == @$tokens
                     || '(' eq $tokens->[4])) {
                 $ident = 'Gettext';
             } elsif ('ASSIGN' eq $tokens->[4] && 'IDENT' eq $tokens->[6]
                      && 'Gettext' eq $tokens->[7]) {
                 $ident = $tokens->[3];
             }
             next;
         }

         next if !defined $ident;
    
         if ('IDENT' eq $tokens->[0] && $ident eq $tokens->[1]
             && 'DOT' eq $tokens->[2] && 'IDENT' eq $tokens->[4]
             && exists $functions{$tokens->[5]}) {
             my $entry = extract_args $tokens, 6, $tokens->[5];
             next if !$entry;

             $entry->{__xgettext_tt_lineno} = $lineno;
             
             if ($options->{add_comments} && $text =~ /^#/) {
             	my @triggers = @{$options->{add_comments}};
             	foreach my $trigger (@triggers) {
             		if ($text =~ /^#[ \t\r\f\013]*$trigger/) {
             			my $comment = '';
             			my @lines = split /\n/, $text;
             			foreach my $line (@lines) {
             				last if $line !~ s/^[ \t\r\f\013]*#[ \t\r\f\013]?//;
             				
             			    $comment .= $line . "\n";
             			}
             			chomp $comment;
             			$entry->comment($comment);
             			last;
             		}
             	}
             }
             
             $entries->add($entry);
         }
    }

    $self->{__xgettext_entries} = $entries;

    # Stop processing here, so that for example includes are ignored.    
    return [];
}

sub __xgettextEntries {
	shift->{__xgettext_entries};
}

1;
