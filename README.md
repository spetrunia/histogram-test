# histogram-test
Histogram precision test script. Supports multiple databases (MariaDB, MySQL-8, PostgreSQL).

## Requirements

- The databases must be started by something outside the test.
- Perl DBI connectors must be installed.

## Setup
Edit the `database-config.pl` and set the database connection parameters accordingly.

## Running the test

```
./histogram-test.pl [--jira-tables]  --db=comma-sepatated-list-of-databases  <testname>
```

For example:
```
./histogram-test.pl --jira-tables --db=mariadb,mysql,postgresql  ./03-common-and-uncommon.pl
```

will produce this output:

```
# log of commands used to setup the test. Each line starts with '#'.
|cond| real| mariadb| mysql| postgresql|
|col=80| 0| 57.1429002| 1.2| 10|
|col=100| 1000| 999.9999618| 999.6| 1000|
|col=115| 10| 8.0000004| 9.6| 10|
|col=185| 0| 57.1429002| 1.2| 10|
|col=200| 1000| 999.9999618| 999.6| 1000|
|col=205| 0| 57.1429002| 1.2| 10|
|col=215| 10| 8.0000004| 9.6| 10|
|col=255| 0| 57.1429002| 1.2| 10|
```

Columns:
* `cond` is the WHERE condition
* `real` is the actual number of rows matching this condition
* `$database-name` is the expected number of rows obtained in $database-name.

## Adding your own tests.

The test file structure is really basic:

```perl 
@dataset_cmds= (
 # array of commands to fill the dataset.
 # this must produce table `t1` with column `col`. 
 # The script will take care of collecting the histogram.
);

@where_clauses= (
 # array of WHERE clauses to test
);
```
