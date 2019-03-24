package App::Netdisco::Web::Plugin::Device::Modules;

use Dancer ':syntax';
use Dancer::Plugin::DBIC;
use Dancer::Plugin::Auth::Extensible;
use Dancer::Plugin::Swagger;

use App::Netdisco::Util::Web (); # for sort_module
use App::Netdisco::Web::Plugin;

register_device_tab({ tag => 'modules', label => 'Modules' });

swagger_path {
    description => 'Get hardware components for a device.',
    tags => ['Devices'],
    path => '/api/device/{identifier}/modules',
    parameters => [
        identifier => { in => 'path', required => 1, type => 'string' },
    ],
    responses => { default => { examples => {
        # TODO document fields returned
        'application/json' => { nodes => {} },
    } } },
},
get '/ajax/content/device/modules' => require_login sub {
    my $q = param('q');
    my $device = schema('netdisco')->resultset('Device')
      ->search_for_device($q) or return bang('Bad device', 400);

    my @set = $device->modules->search({},
      {order_by => { -asc => [qw/parent class pos index/] }});

    # sort modules (empty set would be a 'no records' msg)
    my $results = &App::Netdisco::Util::Web::sort_modules( \@set );
    return unless scalar keys %$results;

    if (request->is_api) {
        content_type('application/json');
        map {$results->{$_}->{module} = { $results->{$_}->{module}->get_columns }
             if (ref {} eq ref $results->{$_} and exists $results->{$_}->{module})} keys %$results;
        to_json { nodes => $results };
    }
    else {
        content_type('text/html');
        template 'ajax/device/modules.tt', {
          nodes => $results,
        }, { layout => undef };
    }
};

true;
