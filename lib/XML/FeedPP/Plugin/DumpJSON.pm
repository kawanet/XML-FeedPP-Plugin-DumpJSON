=head1 NAME

XML::FeedPP::Plugin::DumpJSON - FeedPP Plugin for generating JSON

=head1 SYNOPSIS

    use XML::FeedPP;
    my $feed = XML::FeedPP->new( 'index.rss' );
    $feed->limit_item( 10 );
    $feed->call( DumpJSON => 'index-rss.json' );

=head1 DESCRIPTION

This plugin generates a JSON data representation.

=head1 FILE OR STRING

If a JSON filename is C<undef> or C<''>, this module returns a JSON 
string instead of generating a JSON file.

    $feed->call( DumpJSON => 'feed.json' );     # generates a JSON file
    my $json = $feed->call( DumpJSON => '' );   # returns a JSON string

=head1 OPTIONS

This plugin allows some optoinal arguments following:

    my %opt = (
        slim             => 1,
        slim_element_add => [ 'media:thumbnail@url' ],
        slim_element     => [ 'link', 'title', 'pubDate' ],
    );
    my $json = $feed->call( DumpJSON => '', %opt );

=head2 slim

This plugin converts the whole feed into JSON format by default.
All elements and attribuets are included in a JSON generated.
If this boolean is true, some limited elements are only included.

=head2 slim_element_add

An array reference for element/attribute names
which is given by set()/get() method's format.
These elements/attributes are also appended for slim JSON.

=head2 slim_element

An array reference for element/attribute names.
The default list of limited elements is replaced by this value.

=head1 MODULE DEPENDENCIES

L<JSON::Syck> or L<JSON> is required.

=head1 SEE ALSO

JSON, JavaScript Object Notation:
L<http://www.json.org/>

=head1 AUTHOR

Yusuke Kawasaki, http://www.kawa.net/

=head1 COPYRIGHT AND LICENSE

Copyright (c) 2006 Yusuke Kawasaki. All rights reserved.
This program is free software; you can redistribute it 
and/or modify it under the same terms as Perl itself.

=cut
# ----------------------------------------------------------------
package XML::FeedPP::Plugin::DumpJSON;
use strict;
use vars qw( @ISA );
@ISA = qw( XML::FeedPP::Plugin );
use Carp;
use Symbol;
# use JSON;
# use JSON::Syck;

use vars qw( $VERSION );
$VERSION = "0.15";

*XML::FeedPP::to_json = \&to_json;

my $SLIM_ELEM = [qw( 
    link title pubDate dc:date modified issued dc:subject category 
    image/url media:content@url media:thumbnail@url
)];

sub run {
    my $class = shift;
    my $feed = shift;
    &to_json( $feed, @_ );
}

sub to_json {
    my $feed = shift;
    my $file = shift;
    my $opt  = {@_};
    my $data = $feed;

    if ( $opt->{slim} || $opt->{slim_element} || $opt->{slim_element_add} ) {
        $data = &slim_feed( $data, $opt->{slim_element}, $opt->{slim_element_add} );
    }

    my $json = &dump_json( $data );
    if ( $file ) {
        &write_file( $file, $json );
    }
    $json;
}

sub write_file {
    my $file = shift;
    my $fh   = Symbol::gensym();
    open( $fh, ">$file" ) or Carp::croak "$! - $file";
    print $fh @_;
    close($fh);
}

sub dump_json {
    my $data = shift;
    my $opt = { convblessed => 1 };
    return JSON::Syck::Dump($data) if defined $JSON::Syck::VERSION;
    return JSON->new()->objToJson($data,$opt) if defined $JSON::VERSION;
    local $@;
    eval { require JSON::Syck; };
    return JSON::Syck::Dump($data) if defined $JSON::Syck::VERSION;
    eval { require JSON; };
    return JSON->new()->objToJson($data,$opt) if defined $JSON::VERSION;
    undef;
}

sub slim_feed {
    my $feed = shift;
    my $list = shift || $SLIM_ELEM;
    my $add  = shift;
    my $slim = {};
    my $root = ( keys %$feed )[0];
    if ( ref $add ) {
        $list = [ @$list, @$add ];
    }
    my $channel = {};
    foreach my $key ( @$list ) {
        my $val = ( $key eq "link" ) ? $feed->link() : $feed->get($key);
        $channel->{$key} = $val if defined $val;
    }
    my $entries = [];
    foreach my $item ( $feed->get_item() ) {
        my $hash = {};
        foreach my $key ( @$list ) {
            my $val = ( $key eq "link" ) ? $item->link() : $item->get($key);
            $hash->{$key} = $val if defined $val;
        }
        push( @$entries, $hash );
    }
    my $data;
    if ( $root eq 'rss' ) {
        $channel->{item} = $entries;
        $data = { rss => { channel => $channel }};
    }
    elsif ( $root eq 'rdf:RDF' ) {
        $data = { 'rdf:RDF' => { channel => $channel, item => $entries }};
    }
    elsif ( $root eq 'feed' ) {
        $channel->{entry} = $entries;
        $data = { feed => $channel };
    }
    else {
        Carp::croak "Invalid feed type: $root";
    }
    $data;
}

# ----------------------------------------------------------------
1;
# ----------------------------------------------------------------
