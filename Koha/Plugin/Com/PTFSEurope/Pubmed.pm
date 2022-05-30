package Koha::Plugin::Com::PTFSEurope::Pubmed;

use Modern::Perl;

use base qw(Koha::Plugins::Base);
use Koha::DateUtils qw( dt_from_string );

use Cwd qw(abs_path);
use CGI;
use LWP::UserAgent;
use HTTP::Request;
use JSON qw( encode_json decode_json );

our $VERSION = "1.1.0";

our $metadata = {
    name            => 'Pubmed',
    author          => 'Andrew Isherwood',
    date_authored   => '2022-04-21',
    date_updated    => "2022-04-21",
    minimum_version => '18.05.00.000',
    maximum_version => undef,
    version         => $VERSION,
    description     => 'This plugin provides Koha API routes enabling access to the Pubmed "esummary" API endpoint' 
};

sub new {
    my ( $class, $args ) = @_;

    ## We need to add our metadata here so our base class can access it
    $args->{'metadata'} = $metadata;
    $args->{'metadata'}->{'class'} = $class;

    ## Here, we call the 'new' method for our base class
    ## This runs some additional magic and checking
    ## and returns our actual $self
    my $self = $class->SUPER::new($args);

    return $self;
}

sub provides_api {
    return {
        name                  => 'PubMed', # Display name
        api_namespace         => api_namespace(), # API namespace for URL forming
        type                  => 'search', # Type of API this is
        identifiers_supported => { # The identifiers this service can use
            pmid => {
                regex      => '/^(?<identifier>\d{1,8})$/', # Regex for identifying these identifiers
                param_name => 'pmid' # When passing one of these identifiers to the API, name of the parameter
            }
        },
        search_endpoint       => '/esummary', # The endpoint for accessing this API
        ill_parse_endpoint    => '/parse_to_ill', # The endpoint for parsing search results into ILL schema
        method                => 'GET', # The HTTP method to use
        provide_identifier_in => 'query' # Where to provide identifiers in calls
    };
}

sub api_routes {
    my ($self, $args) = @_;

    my $spec_str = $self->mbf_read('openapi.json');
    my $spec = decode_json($spec_str);

    return $spec;
}

sub api_namespace {
    my ($self) = @_;

    return 'pubmed';
}

sub install() {
    return 1;
}

sub upgrade {
    my ( $self, $args ) = @_;

    my $dt = dt_from_string();
    $self->store_data(
        { last_upgraded => $dt->ymd('-') . ' ' . $dt->hms(':') }
    );

    return 1;
}

sub uninstall() {
    return 1;
}

1;
