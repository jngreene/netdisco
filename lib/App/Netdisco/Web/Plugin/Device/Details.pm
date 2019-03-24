package App::Netdisco::Web::Plugin::Device::Details;

use Dancer ':syntax';
use Dancer::Plugin::DBIC;
use Dancer::Plugin::Auth::Extensible;
use Dancer::Plugin::Swagger;

use App::Netdisco::Web::Plugin;

register_device_tab({ tag => 'details', label => 'Details' });

# device details table
swagger_path {
    description => 'Get properties and power details for a device.',
    tags => ['Devices'],
    path => '/api/device/{identifier}',
    parameters => [
        identifier => { in => 'path', required => 1, type => 'string' },
    ],
    responses => { default => { examples => {
        # TODO document fields returned
        'application/json' => { device => {} },
    } } },
},
get '/ajax/content/device/details' => require_login sub {
    my $q = param('q');
    my $device = schema('netdisco')->resultset('Device')
      ->search_for_device($q) or return bang('Bad device', 400);

    my @results
        = schema('netdisco')->resultset('Device')
        ->search( { 'me.ip' => $device->ip } )->with_times()
        ->hri->all;
    
    my @power
        = schema('netdisco')->resultset('DevicePower')
        ->search( { 'me.ip' => $device->ip } )->with_poestats->hri->all;

    if (request->is_api) {
        content_type('application/json');
        $results[0]->{'power'} = \@power;
        to_json { device => $results[0] };
    }
    else {
        content_type('text/html');
        template 'ajax/device/details.tt', {
          d => $results[0], p => \@power
        }, { layout => undef };
    }
};

true;
