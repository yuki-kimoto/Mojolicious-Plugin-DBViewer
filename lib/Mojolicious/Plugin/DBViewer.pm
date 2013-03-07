use 5.008001;
package Mojolicious::Plugin::DBViewer;
use Mojo::Base 'Mojolicious::Plugin';

use File::Basename 'dirname';
use Cwd 'abs_path';
use Mojolicious::Plugin::DBViewer::Command;
use DBIx::Custom;
use Validator::Custom;

our $VERSION = '0.01';

has 'command';
has 'prefix';
has 'validator';
has 'dbi';

sub add_template_path {
  my ($self, $renderer, $class) = @_;
  $class =~ s/::/\//g;
  $class .= '.pm';
  my $public = abs_path $INC{$class};
  $public =~ s/\.pm$//;
  push @{$renderer->paths}, "$public/templates";
}

sub register {
  my ($self, $app, $conf) = @_;
  
  # Prefix
  my $prefix = $conf->{prefix} // 'dbviewer';
  
  # DBI
  my $dbi = DBIx::Custom->connect(
    dsn => $conf->{dsn},
    user => $conf->{user},
    password => $conf->{password},
    option => $conf->{option} || {},
    connector => 1
  );
  $self->dbi($dbi);
  
  # Validator
  my $validator = Validator::Custom->new;
  $validator->register_constraint(
    safety_name => sub {
      my $name = shift;
      return ($name || '') =~ /^\w+$/ ? 1 : 0;
    }
  );
  $self->validator($validator);
  
  # Commaned
  require Mojolicious::Plugin::DBViewer::MySQL::Command;
  my $command
    = Mojolicious::Plugin::DBViewer::MySQL::Command->new(dbi => $dbi);
  $self->command($command);
  
  # Add template path
  $self->add_template_path($app->renderer, __PACKAGE__);
  
  # Routes
  my $r = $conf->{route} // $app->routes;
  $self->prefix($prefix);
  {
    my $r = $r->route("/$prefix")->to(
      'dbviewer#',
      namespace => 'Mojolicious::Plugin::DBViewer::MySQL',
      plugin => $self,
      prefix => $self->prefix,
      main_title => 'DBViewer',
    );
    
    $r->get('/')->to('#default');
    $r->get('/tables')->to(
      '#tables',
      utilities => [
        {path => 'showcreatetables', title => 'Show create tables'},
        {path => 'showselecttables', title => 'Show select tables'},
        {path => 'showprimarykeys', title => 'Show primary keys'},
        {path => 'shownullallowedcolumns', title => 'Show null allowed columns'},
        {path => 'showdatabaseengines', title => 'Show database engines'},
        {path => 'showcharsets', title => 'Show charsets'}
      ]
    );
    $r->get('/table')->to('#table');
    $r->get('/showcreatetables')->to('#showcreatetables');
    $r->get('/showselecttables')->to('#showselecttables');
    $r->get('/showprimarykeys')->to('#showprimarykeys');
    $r->get('/shownullallowedcolumns')->to('#shownullallowedcolumns');
    $r->get('/showdatabaseengines')->to('#showdatabaseengines');
    $r->get('/showcharsets')->to('#showcharsets');
    $r->get('/select')->to('#select');

    # Routes (MySQL specific)
    $r->get('/showdatabaseengines')->to('#showdatabaseengines');
    $r->get('/showcharsets')->to('#showcharsets');
  }
}

1;

=head1 NAME

Mojolicious::Plugin::DBViewer - Mojolicious plugin to display MySQL database information on browser

=head1 SYNOPSYS

  # Mojolicious::Lite
  plugin(
    'DBViewer',
    dsn => "dbi:mysql:database=bookshop",
    user => 'ken',
    password => '!LFKD%$&'
  );

  # Mojolicious
  $app->plugin(
    'DBViewer',
    dsn => "dbi:mysql:database=bookshop",
    user => 'ken',
    password => '!LFKD%$&'
  );
  
  # Access
  http://localhost:3000/dbviewer
  
  # Prefix change (http://localhost:3000/dbviewer2)
  plugin 'DBViewer', dbh => $dbh, prefix => 'dbviewer2';

  # Route
  my $bridge = $app->route->under(sub {...});
  plugin 'DBViewer', route => $bridge, ...;

=head1 DESCRIPTION

L<Mojolicious::Plugin::DBViewer> is L<Mojolicious> plugin
to display Database information on your browser.

L<Mojolicious::Plugin::DBViewer> have the following features.

=over 4

=item *

Support C<MySQL> and C<SQLite>

=item *

Display all table names

=item *

Display C<show create table>

=item *

Select * from TABLE

=item *

Display C<primary keys>, C<null allowed columnes>, C<database engines> and C<charsets> in all tables.

=back

=head1 OPTIONS

=head2 dsn

  dsn => "dbi:SQLite:dbname=proj"

Datasource name.


=head2 password

  password => 'secret';

Database password.

=head2 prefix

  prefix => 'dbviewer2'

Application base path, default to C<dbviewer>.
You can access DB viewer by the following path.

  http://somehost.com/dbviewer2
  
=head2 option

  option => $option
  
DBI option (L<DBI> connect method's fourth argument).

=head2 route

    route => $route

Router, default to C<$app->routes>.

It is useful when C<under> is used.

  my $bridge = $r->under(sub {...});
  plugin 'DBViewer', dbh => $dbh, route => $bridge;

=head2 user

  user => 'kimoto'

Database user.

=cut
