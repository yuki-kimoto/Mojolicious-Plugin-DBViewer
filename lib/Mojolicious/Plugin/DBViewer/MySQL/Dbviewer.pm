package Mojolicious::Plugin::DBViewer::MySQL::Dbviewer;
use Mojo::Base 'Mojolicious::Controller';
use Data::Page;

sub select {
  my $self = shift;;
  
  my $plugin = $self->stash->{plugin};
  my $command = $plugin->command;

  # Validation
  my $params = $command->params($self);
  my $rule = [
    database => {default => ''} => [
      'safety_name'
    ],
    table => {default => ''} => [
      'safety_name'
    ],
    page => {default => 1} => [
      'uint'
    ],
    condition_column => [
      'safety_name'
    ],
    condition_value => [
      'not_blank'
    ]
  ];
  my $vresult = $plugin->validator->validate($params, $rule);
  my $database = $vresult->data->{database};
  my $table = $vresult->data->{table};
  
  # Where
  my $column = $vresult->data->{condition_column};
  my $value = $vresult->data->{condition_value};
  
  my $where;
  if (defined $column && defined $value) {
    $where = $plugin->dbi->where;
    $where->clause(":${column}{like}");
    $where->param({$column => $value});
  }
  
  # Limit
  my $page = $vresult->data->{page};
  my $count = 100;
  my $offset = ($page - 1) * $count;
  
  # Get null allowed columns
  my $result = $plugin->dbi->select(
    table => "$database.$table",
    where => $where,
    append => "limit $offset, $count"
  );
  my $header = $result->header;
  my $rows = $result->fetch_all;
  my $sql = $plugin->dbi->last_sql;
  
  # Pager
  my $total = $plugin->dbi->select(
    'count(*)',
    table => "$database.$table",
    where => $where
  )->value;
  my $pager = Data::Page->new($total, $count, $page);
  
  $self->render(
    database => $database,
    table => $table,
    header => $header,
    rows => $rows,
    sql => $sql,
    pager => $pager
  );
}

sub showdatabaseengines {
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
  my $database_engines = $command->show_database_engines($database);
  
  $self->stash->{template} = 'mysqlviewerlite/showdatabaseengines'
    unless $self->stash->{template};

  $self->render(
    database => $database,
    database_engines => $database_engines
  );
}

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
