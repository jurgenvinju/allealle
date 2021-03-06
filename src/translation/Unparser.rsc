module translation::Unparser

import translation::AST;

extend translation::theories::integer::Unparser;
extend translation::theories::string::Unparser;

import List;
import util::Maybe;

str unparse(problem(list[RelationDef] relations, list[AlleFormula] constraints, map[str,AllePredicate] predicates, Maybe[ObjectiveSection] objectiveSec, Maybe[Expect] expect)) = 
  "<for (RelationDef r <- relations) {><unparse(r)>
  '<}>
  '
  '<for (str pred <- predicates) {><unparse(predicates[pred])>
  '<}>
  '
  '<for(AlleFormula f <- constraints) {><unparse(f)>
  '<}>
  '
  '<unparse(objectiveSec)> 
  '";

str unparse(relation(str name, list[HeaderAttribute] heading, RelationalBound bounds)) =
  "<name> (<intercalate(",", [unparse(ha) | HeaderAttribute ha <- heading])>) <unparse(bounds)>";

str unparse(header(str name, Domain dom)) =
  "<name> : <unparse(dom)>";

str unparse(exact(list[AlleTuple] tuples)) =
  "= {<intercalate(",", [unparse(t) | AlleTuple t <- tuples])>}";

str unparse(atMost(list[AlleTuple] upper)) =
  "\<= {<intercalate(",", [unparse(t) | AlleTuple t <- upper])>}";

str unparse(atLeastAtMost(list[AlleTuple] lower, list[AlleTuple] upper)) = 
  "\>= {<intercalate(",", [unparse(t) | AlleTuple t <- lower])>} \<= {<intercalate(",", [unparse(t) | AlleTuple t <- upper])>}";
 
str unparse(tup(list[AlleValue] values)) =
  "\<<intercalate(",", [unparse(v) | AlleValue v <- values])>\>";

str unparse(range(list[RangedValue] from, list[RangedValue] to)) =
  "\<<intercalate(",",[unparse(rv) | RangedValue rv <- from])>..<intercalate(",",[unparse(rv) | RangedValue rv <- to])>\>";

str unparse(idd(Id id)) = id;
str unparse(alleLit(AlleLiteral lit)) = unparse(lit);
str unparse(hole()) = "?";

str unparse(id(str prefix, int numm))     = "<prefix><numm>";
str unparse(idOnly(Id id))                = "<id>";
str unparse(templateLit(AlleLiteral lit)) = unparse(lit);
str unparse(templateHole())               = "?";

default str unparse(AlleLiteral l) { throw "No uparse function for literal \'<l>\'"; }
  
str unparse(id()) = "id";
default str unparse(Domain d) { throw "No unparse function for domain \'<d>\'"; }

str unparse(nothing()) = "";
str unparse(just(objectives(ObjectivePriority prio, list[Objective] objs))) = 
 "objectives (<unparse(prio)>): <intercalate(", ", [unparse(obj) | obj <- objs])>";
 
str unparse(lex()) = "lex";
str unparse(pareto()) = "pareto";
str unparse(independent()) = "independent"; 

str unparse(pred(str name, list[PredParam] params, AlleFormula form))
  = "pred <name> [<intercalate(", ", [unparse(p) | p <- params])>]
    ' = <unparse(form)>
    ";

str unparse(predParam(str name, list[HeaderAttribute] heading))
  = "<name> : (<intercalate(",", [unparse(ha) | HeaderAttribute ha <- heading])>)";

str unparse(predCall(str name, list[AlleExpr] args))                                = "<name>[<intercalate(",", [<unparse(a)> | a <- args])>]";
str unparse(empty(AlleExpr expr))                                                   = "(no <unparse(expr)>)";
str unparse(atMostOne(AlleExpr expr))                                               = "(lone <unparse(expr)>)";
str unparse(exactlyOne(AlleExpr expr))                                              = "(one <unparse(expr)>)";
str unparse(nonEmpty(AlleExpr expr))                                                = "(some <unparse(expr)>)"; 
str unparse(subset(AlleExpr lhsExpr, AlleExpr rhsExpr))                             = "(<unparse(lhsExpr)> in <unparse(rhsExpr)>)";
str unparse(equal(AlleExpr lhsExpr, AlleExpr rhsExpr))                              = "(<unparse(lhsExpr)> = <unparse(rhsExpr)>)";
str unparse(inequal(AlleExpr lhsExpr, AlleExpr rhsExpr))                            = "(<unparse(lhsExpr)> != <unparse(rhsExpr)>)";
str unparse(negation(AlleFormula form))                                             = "(not <unparse(form)>)";
str unparse(conjunction(AlleFormula lhsForm, AlleFormula rhsForm))                  = "(<unparse(lhsForm)> && <unparse(rhsForm)>)";
str unparse(disjunction(AlleFormula lhsForm, AlleFormula rhsForm))                  = "(<unparse(lhsForm)> || <unparse(rhsForm)>)";
str unparse(implication(AlleFormula lhsForm, AlleFormula rhsForm))                  = "(<unparse(lhsForm)> =\> <unparse(rhsForm)>)";
str unparse(equality(AlleFormula lhsForm, AlleFormula rhsForm))                     = "(<unparse(lhsForm)> \<=\> <unparse(rhsForm)>)";  
str unparse(\filter(AlleExpr expr, Criteria crit))                                  = "(<unparse(expr)>::[<unparse(crit)>])";  
str unparse(universal(list[VarDeclaration] decls, AlleFormula form))                = "(forall <intercalate(", ", [unparse(d) | VarDeclaration d <- decls])> | <unparse(form)>)";
str unparse(existential(list[VarDeclaration] decls, AlleFormula form))              = "(exists <intercalate(", ", [unparse(d) | VarDeclaration d <- decls])> | <unparse(form)>)";
str unparse(let(list[VarBinding] bindings, AlleFormula form))                       = "(let <intercalate(", ", [unparse(b) | VarBinding b <- bindings])> | <unparse(form)>)";
default str unparse(AlleFormula f) { throw "No unparse function for formula \'<f>\'"; }

str unparse(relvar(str name))                                                       = name;
str unparse(rename(AlleExpr expr, list[Rename] renames))                            = "(<unparse(expr)>[<intercalate(",",["<r.orig> as <r.new>" | Rename r <- renames])>])";
str unparse(project(AlleExpr expr, list[str] attributes))                           = "(<unparse(expr)>[<intercalate(",",attributes)>])";
str unparse(aggregate(AlleExpr expr, list[AggregateFunctionDef] funcs))             = "(<unparse(expr)>[<intercalate(",",[unparse(f) | AggregateFunctionDef f <- funcs])>])";
str unparse(groupedAggregate(AlleExpr expr, list[str] groupBy, list[AggregateFunctionDef] funcs)) = "(<unparse(expr)>[<intercalate(",", groupBy)>,<intercalate(",",[unparse(f) | AggregateFunctionDef f <- funcs])>])";
str unparse(select(AlleExpr expr, Criteria criteria))                               = "(<unparse(expr)> where <unparse(criteria)>)";
str unparse(union(AlleExpr lhs, AlleExpr rhs))                                      = "(<unparse(lhs)>+<unparse(rhs)>)";
str unparse(intersection(AlleExpr lhs, AlleExpr rhs))                               = "(<unparse(lhs)>&<unparse(rhs)>)";
str unparse(difference(AlleExpr lhs, AlleExpr rhs))                                 = "(<unparse(lhs)>-<unparse(rhs)>)";
str unparse(product(AlleExpr lhs, AlleExpr rhs))                                    = "(<unparse(lhs)> x <unparse(rhs)>)";
str unparse(naturalJoin(AlleExpr lhs, AlleExpr rhs))                                = "(<unparse(lhs)> |x| <unparse(rhs)>)";
str unparse(transpose( AlleExpr expr))                                              = "(~<unparse(expr)>)";
str unparse(closure(AlleExpr expr))                                                 = "(^<unparse(expr)>)";
str unparse(reflexClosure(AlleExpr expr))                                           = "(*<unparse(expr)>)";
str unparse(comprehension(list[VarDeclaration] decls, AlleFormula form))            = "{<intercalate(",", [unparse(d) | VarDeclaration d <- decls])> | <unparse(form)>}";

default str unparse(AlleExpr exp) { throw "No unparser implemented for \'<exp>\'"; }

str unparse(aggFuncDef(AggregateFunction fun, str bindTo))                          = "<unparse(fun)> as <bindTo>";

default str unparse(AggregateFunction f) { throw "No unparser implemented for \'<f>\'"; }

str unparse(varDecl(str name, AlleExpr binding))    = "<name>:<unparse(binding)>";
str unparse(varBinding(str name, AlleExpr binding)) = "<name> = <unparse(binding)>";

str unparse(equal(CriteriaExpr lhs, CriteriaExpr rhs))                   = "(<unparse(lhs)> = <unparse(rhs)>)";
str unparse(inequal(CriteriaExpr lhs, CriteriaExpr rhs))                 = "(<unparse(lhs)> != <unparse(rhs)>)";
str unparse(and(Criteria lhs, Criteria rhs))                             = "(<unparse(lhs)> && <unparse(rhs)>)";
str unparse(or(Criteria lhs, Criteria rhs))                              = "(<unparse(lhs)> || <unparse(rhs)>)";
str unparse(not(Criteria crit))                                          = "(!<unparse(crit)>)";

str unparse(att(str name))      = name;
str unparse(litt(AlleLiteral l)) = unparse(l);
str unparse(ite(Criteria condition, CriteriaExpr thn, CriteriaExpr els)) = "(<unparse(condition)> ? <unparse(thn)> : <unparse(els)>)";

default str unparse(CriteriaExpr expr) { throw "No unparse function for Criteria Expression \'<expr>\'";}

str unparse(maximize(AlleExpr expr)) = "maximize <unparse(expr)>";
str unparse(minimize(AlleExpr expr)) = "minimize <unparse(expr)>";

str unparse(order(str first, str second)) = "\<<first>,<second>\>";