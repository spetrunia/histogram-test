#
# Define @dataset_cmds, @where_clauses.
#

# 10 constants + long tail
@dataset_cmds= (
  "drop table if exists ten, one_k, t1",
  "create table ten(a int)",
  "insert into ten values (0),(1),(2),(3),(4),(5),(6),(7),(8),(9)",
  "create table one_k(a int)", 
  "insert into one_k select A.a + B.a* 10 + C.a * 100 from ten A, ten B, ten C",

  "create table t1 ( col int)",
# 100 , 200, 300, ...
  "insert into t1 select 100*A.a+100 from ten A, one_k B",
# 10 rows in the middle of each:
#  110..120
#  210..220 
#  etc
  "insert into t1 select A.a*100 + 10 + B.a from ten A, ten B, ten D",
# the same but 130-140, 230-240, etc
  "insert into t1 select A.a*100 + 30 + B.a from ten A, ten B, ten D"
);

@where_clauses= (
  "col=80",
  "col=100",
  "col=115",
  "col=185",
  "col=200",
  "col=205",
  "col=215",
  "col=255",
);

