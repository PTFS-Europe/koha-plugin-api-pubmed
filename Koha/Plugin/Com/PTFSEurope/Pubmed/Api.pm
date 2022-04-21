package Koha::Plugin::Com::PTFSEurope::Pubmed::Api;

use Modern::Perl;
use strict;
use warnings;

use JSON qw( decode_json );
use LWP::UserAgent;

use Mojo::Base 'Mojolicious::Controller';
use Koha::Plugin::Com::PTFSEurope::Pubmed;

sub esummary {
    # Validate what we've received
    my $c = shift->openapi->valid_input or return;

    my $base_url = "https://eutils.ncbi.nlm.nih.gov/entrez/eutils/esummary.fcgi";

    my $doi = $c->validation->param('pmid') || '';

    if (!$pmid || length $pmid == 0) {
        _return_response({ error => 'No PMID supplied' }, $c);
    }

    my $ua = LWP::UserAgent->new;
    my $response = $ua->get("${base_url}?db=pubmed&retmode=json&id=$pmid");

    if ( $response->is_success ) {
        _return_response({ success => decode_json($response->decoded_content) }, $c);
    } else {
        _return_response(
            {
                error => $response->status_line,
                errorcode => $response->code
            },
            $c
        );

    }
}

sub _return_response {
    my ( $response, $c ) = @_;
    return $c->render(
        status => $response->{errorcode} || 200,
        openapi => {
            results => {
                result => $response->{success} || [],
                errors => $response->{error} || []
            }
        }
    );
}

1;