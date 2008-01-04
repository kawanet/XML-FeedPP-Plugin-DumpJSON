# ----------------------------------------------------------------
    use strict;
    use Test::More;
# ----------------------------------------------------------------
{
    local $@;
    eval { require JSON; };
    plan skip_all => 'JSON is not loaded.' if $@;
    plan tests => 26;
}
# ----------------------------------------------------------------
    my $FEED_LIST = [qw(
        t/example/index-e.rdf  t/example/index-j.rdf
    )];
    my $UTF8_FLAG = undef;
# ----------------------------------------------------------------
{
    ok( defined $JSON::VERSION, "JSON $JSON::VERSION" );
    use_ok('XML::FeedPP');
    &test_main();
}
# ----------------------------------------------------------------
sub __decode_json {
    my $data = shift;
	my $json = JSON::PP->new();
	my $bool = $XML::FeedPP::UTF8_FLAG ? 0 : 1;
 	$json->utf8(! $XML::FeedPP::UTF8_FLAG);
	$json->decode($data);
}
# ----------------------------------------------------------------
sub test_main {
    local $XML::FeedPP::UTF8_FLAG = $UTF8_FLAG;
	local $XML::FeedPP::TREEPP_OPTIONS->{utf8_flag} = $UTF8_FLAG;
	my $tppopt = {};
    foreach my $file ( @$FEED_LIST ) {
        my $feed = XML::FeedPP::RDF->new( $file, %$tppopt );
        ok( ref $feed, $file );

        my $title1 = $feed->title();
        like( $title1, qr/kawa.net/i, 'feed channel title is valid' );
        ok( ! utf8::is_utf8($title1), 'feed channel title is not utf8' );

        my $item = $feed->get_item(0);
        my $title2 = $item->title();
        like( $title2, qr/\S/i, 'feed item title is valid' );
        ok( ! utf8::is_utf8($title2), 'feed item title is not utf8' );

        my $json = $feed->call( 'DumpJSON' );
        like( $json, qr/kawa.net/i, 'DumpJSON is valid' );
        ok( ! utf8::is_utf8($json), 'DumpJSON is not utf8' );

#		print STDERR "[ ", ( $json =~ /^(.{600})/s )[0]," ]\n";

        my $data = __decode_json( $json );
        ok( ref $data, 'decode json' );

        my $title3 = $data->{'rdf:RDF'}->{channel}->{title};
        like( $title3, qr/kawa.net/i, 'json channel title is valid' );
        ok( ! utf8::is_utf8($title3), 'json channel title is not utf8' );

        my $title4 = $data->{'rdf:RDF'}->{item}->[0]->{title};
        like( $title4, qr/\St/i, 'json item title is valid' );
        ok( ! utf8::is_utf8($title4), 'json item title is not utf8' );

###     is( $title3, $title1, 'same channel title' );
###     is( $title4, $title2, 'same item title' );
    }
}
# ----------------------------------------------------------------
;1;
# ----------------------------------------------------------------
