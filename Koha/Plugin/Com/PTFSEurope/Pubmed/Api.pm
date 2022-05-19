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

    my $pmid = $c->validation->param('pmid') || '';

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

sub parse_to_ill {
    # Validate what we've received
    my $c = shift->openapi->valid_input or return;

    my $payload = $c->validation->param('body');
    my $body = $payload->{results}->{result};

    # We only use the first result we receive
    my $uid = $body->{result}->{uids}->[0];
    my $metadata = $body->{result}->{$uid};

    # Map Koha core ILL props to Pubmed
    my $mapping = {
        article_author => sub {
            my $authors = shift->{authors};
            my @auth_arr = ();
            foreach my $author(@{$authors}) {
                push @auth_arr, $author->{name};
            }
            return join('; ', @auth_arr);
        },
        article_title => sub {
            return shift->{title};
        },
        associated_id => sub {
            my $ids = shift->{articleids};
            foreach my $id(@{$ids}) {
                if ($id->{idtype} eq 'pubmed') {
                    return $id->{value};
                }
            }
        },
        issn => sub {
            return shift->{issn};
        },
        issue => sub {
            return shift->{issue};
        },
        pages => sub {
            return shift->{pages};
        },
        publisher => sub {
            return shift->{publishername};
        },
        title => sub {
            return shift->{title};
        },
        published_date => sub {
            return shift->{pubdate};
        }
    };

    my $return = {};

    while (my ($k, $v) = each %{$mapping}) {
        $return->{$k} = $v->($metadata);
    }

    _return_response(
        { success => $return },
        $c
    );
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