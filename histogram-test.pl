#!/usr/bin/perl

use DBI;

do './database-config.pl';

# Parse the parameters ...
sub usage() {
  print "\n";
  print " Usage: $0 [--jira-tables] --db=mysql,mariadb,postgresql  test_name \n";
  print "\n";
}


$print_jira_tables= 0;

$db_arg= shift;
if ($db_arg =~ /^--jira-tables$/) {
   $print_jira_tables= 1;
}
  
$db_arg= shift;
if ($db_arg =~ /^--db=(.*)$/) {
  #print "dbs=$1\n";
  @databases= split(/,/, $1);
} else {
  usage();
  die "Wrong --db argument";
}

$test_name= shift;
if (!($test_name =~ /\.\//)) {
  $test_name= "./" . $test_name;
}

do $test_name;

@mariadb_analyze_cmds= (
  " set histogram_type=json_hb",
#  " set histogram_type=double_prec_hb",
  " analyze table t1 persistent for all"
);

@mysql_analyze_cmds= (
  "analyze table t1 update histogram on col",
  "analyze table t1",
#  "do sleep(60)",
#  "flush tables"
);

@postgresql_analyze_cmds= (
  "analyze t1",
);

$table_rows= 0;

sub prepare_dataset {

  foreach (@dataset_cmds) {
    my $query= $_;
    print "# $query;\n";
    $dbh->do($query) || die ("Failed!");
  }
  
  my @analyze_cmds= ();
  if ($database_type eq "mariadb") {
    @analyze_cmds= @mariadb_analyze_cmds;
  } elsif ($database_type eq "mysql") {
    @analyze_cmds= @mysql_analyze_cmds;
  } elsif ($database_type eq "postgresql") {
    @analyze_cmds= @postgresql_analyze_cmds;
  } else {
    die("Unknown database type $database_type");
  }

  foreach (@analyze_cmds) {
    $query= $_;
    print "# $query;\n";
    $dbh->do($query) || die ("Failed!");
  }

  my $q= "select count(*) from t1";
  my $sth= $dbh->prepare($q);
  $sth->execute();
  my @result = $sth->fetchrow_array();
  $table_rows= $result[0];
  print "# table_rows= $table_rows\n";
}


#
# Then, run the queries.
#
sub find_estimate_mariadb {
  my $cond= shift;
  my $q= "explain format=json select * from t1 where $cond";
  my $sth= $dbh->prepare($q);
  $sth->execute() || die ("Failed, query $q");
  my @result = $sth->fetchrow_array();
  my $json= $result[0];
  if ($json =~ /"filtered": ([0-9.]+),/) {
    #print "Ok1\n";
    return ($1 * $table_rows * 0.01);
  } elsif ($json =~ /"filtered": "([0-9.]+)"/) {
    #print "AAA: $json, $1\n";
    return ($1 * $table_rows * 0.01);
  } else {
    print "no match!\n";
  }
}

sub find_estimate_postgresql {
  my $cond= shift;
  my $q= "explain select * from t1 where $cond";
  my $sth= $dbh->prepare($q);
  $sth->execute() || die ("Failed, query $q");
  my @result = $sth->fetchrow_array();
  my $explain= $result[0];
  if ($explain =~ /Seq Scan on t1 .* rows=([0-9.]+) /) {
    return $1;
  } else {
    print "No match!\n";
  }
}


sub find_estimate {
  my $cond= shift;
  if ($database_type eq "mariadb" || 
      $database_type eq "mysql") {
    return find_estimate_mariadb($cond);
  } elsif ($database_type eq "postgresql") {
    return find_estimate_postgresql($cond);
  } else {
    die("Unknown database type $database_type");
  }
}

sub find_value {
  my $cond= shift;
  my $q= "select count(*) from t1 where $cond";
  #print "q $q\n";
  my $sth= $dbh->prepare($q);
  $sth->execute();
  my @result = $sth->fetchrow_array();
  return $result[0];
}


## Formatting settings 

$LINE_START="";
$LINE_END="";
$SEP= ", ";
if ($print_jira_tables) {
$LINE_START="|";
$LINE_END="|";
$SEP= "| ";
}

## 
## Main
##

#$database_type="mysql";
#$database_type="mariadb";
#$database_type="postgresql";

foreach (@databases) {

  $database_type= $_;
  print "# Running on $database_type\n";
  $conn_user='';
  $conn_password='';

  if ($database_type eq "mariadb") {
    $conn_str= $conn_str_mariadb;
    $conn_user='root';
  } elsif ($database_type eq "mysql") {
    $conn_str= $conn_str_mysql;
    $conn_user='root';
  } elsif ($database_type eq "postgresql") {
    $conn_str= $conn_str_postgresql;
    $conn_password= 'foo';
  } else {
    die("Unknown database type $database_type");
  }

  # Connect 
  $dbh = DBI->connect($conn_str, $conn_user, $conn_password) || die "Could not connect to database: $DBI::errstr";

  prepare_dataset();
  
  @real_rows= ();
  $cnt= 0;
  foreach (@where_clauses) {
    $cond=$_;
    $estimate{$database_type}[$cnt]=  find_estimate($cond);
    $real[$cnt]= find_value($cond);
    #print "$cond, $est, $real\n";
    $cnt++;
  }
  $dbh->disconnect();
}

print $LINE_START . "cond" . $SEP . "real";
foreach (@databases) {
  print $SEP . $_;
}
print "$LINE_END\n";

$cnt= 0;
foreach (@where_clauses) {
  $cond=$_;
  print $LINE_START . $cond . $SEP . $real[$cnt];
  foreach (@databases) {
    $database_type= $_;
    print $SEP;
    print $estimate{$database_type}[$cnt];
  }
  $cnt++;
  print "$LINE_END\n";
}
