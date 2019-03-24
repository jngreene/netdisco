package App::Netdisco::Web;

use Dancer ':syntax';
use Dancer::Plugin::Ajax;

use Dancer::Plugin::Swagger;

# setup for swagger API
my $swagger = Dancer::Plugin::Swagger->instance->doc;
$swagger->{schemes} = ['http','https'];
$swagger->{consumes} = 'application/json';
$swagger->{produces} = 'application/json';
$swagger->{tags} = [
  {name => 'General'},
  {name => 'Devices',
    description => 'Operations relating to Devices (switches, routers, etc)'},
  {name => 'Nodes',
    description => 'Operations relating to Nodes (end-stations such as printers)'},
  {name => 'NodeIPs',
    description => 'Operations relating to MAC-IP mappings (IPv4 ARP and IPv6 Neighbors)'},
];
$swagger->{securityDefinitions} = {
  APIKeyHeader =>
    { type => 'apiKey', name => 'Authorization', in => 'header' },
  BasicAuth =>
    { type => 'basic' },
};
$swagger->{security} = [ { APIKeyHeader => [] } ];

# when we start forwarding to ajax handlers for api calls
hook 'before' => sub {
  vars->{'orig_path'} = request->path unless request->is_forward;
};

# workaround for Swagger plugin weird response body
hook 'after' => sub {
  my $r = shift; # a Dancer::Response

  if (request->path eq '/swagger.json') {
      $r->content( to_json( $r->content ) );
      header('Content-Type' => 'application/json');
  }
};

# remove secrets from JSON response
sub _clean {
  my $h = shift;
  return unless ref {} eq ref $h;
  delete $h->{snmp_comm};
  _clean($_) for values %$h;
}

# remove secrets from JSON response
hook 'after' => sub {
  my $r = shift; # a Dancer::Response
  my $type = $r->content_type or return;

  if ($type eq 'application/json') {
    my $content = from_json $r->content or return;
    _clean( $content );
    $r->content( to_json $content );
  }
};

# forward API calls to AJAX route handlers
any '/api/:type/:identifier/:method' => require_login sub {
  pass unless setting('api_enabled')
    ->{ params->{'type'} }->{ params->{'method'} };

  my $target =
    sprintf '/ajax/content/%s/%s', params->{'type'}, params->{'method'};
  forward $target, { tab => params->{'method'}, q => params->{'identifier'} };
};

{
  # helper for handlers of more than one method type
  *Dancer::Request::is_api = sub {
      my $self = shift;
      my $path = ($self->is_forward ? vars->{'orig_path'} : $self->path);
      return (setting('api_token_lifetime')
        and $self->accept =~ m/(?:json|javascript)/
        and index($path, uri_for('/api')->path) == 0);
  };
}

true;
