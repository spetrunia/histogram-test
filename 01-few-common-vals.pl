
# Uniformly distributed dataset, 10 constants
@dataset_cmds= (
  "drop table if exists ten, one_k, t1",
  "create table ten(a int);",
  "insert into ten values (0),(1),(2),(3),(4),(5),(6),(7),(8),(9);",
  "create table one_k(a int);", 
  "insert into one_k select A.a + B.a* 10 + C.a * 100 from ten A, ten B, ten C;",

  "create table t1 ( col int);",
  "insert into t1 select 100*A.a+100 from ten A, one_k B;"
);

@where_clauses= (
  "col=0",
  "col=50",
  "col=70",
  "col=100",
  "col=150",
  "col=200"
);



