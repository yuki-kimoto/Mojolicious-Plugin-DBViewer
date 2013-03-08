package Mojolicious::Plugin::DBViewer::MySQL::Dbviewer;
use Mojo::Base 'Mojolicious::Controller';
use Data::Page;

sub showcharsets {
  my $self = shift;;
  
  my $plugin = $self->stash->{plugin};
  my $command = $plugin->command;

  # Validation
  my $params = $command->params($self);
  my $rule = [
    database => {default => ''} => [
      'safety_name'
    ],
  ];
  my $vresult = $plugin->validator->validate($params, $rule);
  my $database = $vresult->data->{database};
  
  # Get primary keys
  my $charsets = $command->show_charsets($database);
  
  $self->stash->{template} = 'mysqlviewerlite/showcharsets'
    unless $self->stash->{template};

  $self->render(
    database => $database,
    charsets => $charsets
  );
}

1;
