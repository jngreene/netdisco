package App::Netdisco::Web::Plugin::Device::Addresses;

use Dancer ':syntax';
use Dancer::Plugin::DBIC;
use Dancer::Plugin::Auth::Extensible;
use Dancer::Plugin::Swagger;

use App::Netdisco::Web::Plugin;

register_device_tab( { tag => 'addresses', label => 'Addresses', provides_csv => 1 } );

# device interface addresses
swagger_path {
    description => 'Get interface addresses for a device.',
    tags => ['Devices'],
    path => '/api/device/{identifier}/addresses',
    parameters => [
        identifier => { in => 'path', required => 1, type => 'string' },
    ],
    responses => { default => { examples => {
        # TODO document fields returned
        'application/json' => [],
    } } },
},
get '/ajax/content/device/addresses' => require_login sub {
    my $q = param('q');

    my $device = schema('netdisco')->resultset('Device')
      ->search_for_device($q) or return bang( 'Bad device', 400 );

    my @results = $device->device_ips
      ->search( {}, { order_by => 'alias', prefetch => 'device_port' } )
      ->hri->all;

    return unless scalar @results;

    if (request->is_api) {
        content_type('application/json');
        to_json \@results;
    }
    elsif (request->is_ajax) {
        my $json = to_json( \@results );
        template 'ajax/device/addresses.tt', { results => $json },
            { layout => undef };
    }
    else {
        header( 'Content-Type' => 'text/comma-separated-values' );
        template 'ajax/device/addresses_csv.tt', { results => \@results },
            { layout => undef };
    }
};

1;
