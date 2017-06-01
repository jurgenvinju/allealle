module theories::PreProcessor

import theories::AST;

import List;
import IO;
import Set;
import util::Maybe;

Problem replaceConstants(Problem problem) {
  list[AtomDecl] constantAtoms = [];
  list[RelationalBound] constantRelations = [];

  bool exists(str atomName) = atomName in {a.atom | AtomDecl a <- constantAtoms};
  
  void addRelation(str constantName, AtomDecl ad) { 
    constantAtoms += [ad];
    constantRelations += [relationalBound(constantName, 1, [\tuple([ad.atom])], [\tuple([ad.atom])])];
  }
    
  problem.constraints = visit(problem.constraints) {
    case Expr expr => replaceConstants(expr, addRelation, exists) when isConstant(expr)
  }
  
  problem.uni.atoms += constantAtoms;
  problem.bounds += constantRelations;
  
  return problem;
}

default bool isConstant(Expr _) = false;
default Expr replaceConstants(Expr orig, void (str, AtomDecl) update, bool (str) exists) { throw "No constant replacing function defined for constant expression \'<orig>\'"; }

private alias Env = map[str relName, tuple[list[list[Atom]] maxTuples, Expr domain] info];

data Expr(list[list[Atom]] tuples = [], Expr domain = emptyExpr());

Problem transform(Problem problem) {
  problem = replaceConstants(problem);

  int lastResult = 0;
  str newResultAtom() { 
    lastResult += 1;
    return "_r<lastResult>";
  }
  
  list[AtomDecl] newAtoms = [];
  list[RelationalBound] newRelations = [];
  list[AlleFormula] newConstraints = [];
  
  void addRelation(str relName, list[AtomDecl] atomDecls, list[list[Atom]] minTuples, list[list[Atom]] maxTuples) {
    set[AtomDecl] newAtomSet = {*newAtoms};
    newAtoms += [a | AtomDecl a <- atomDecls, a notin newAtomSet];
    
    list[Tuple] newLb = [\tuple(tup) | list[Atom] tup <- minTuples];
    list[Tuple] newUb = [\tuple(tup) | list[Atom] tup <- maxTuples];
    
    if (r:relationalBound(relName, int arity, list[Tuple] lb, list[Tuple] ub) <- newRelations) {
      newRelations -= r;
      newRelations += relationalBound(relName, arity, lb + newLb, ub + newUb);
    }
    else {
      int arity = size(getOneFrom(maxTuples));
    
      newRelations += [relationalBound(relName, arity, newLb, newUb)];
    }
  }  
  
  void addConstraint(AlleFormula newForm) {
    newConstraints += newForm;
  }
  
  int lastId = 0;
  
  str newRelNr() {
    lastId += 1;
    return "<lastId>";
  }  
  
  Env env = buildEnv(problem);

  list[AlleFormula] transformedForms = [transform(f, env, problem.uni, newResultAtom, addRelation, addConstraint, newRelNr) | AlleFormula f <- problem.constraints];
  transformedForms = visit(transformedForms) {
    case Expr expr => expr[tuples = []]
  }
  
  problem.uni.atoms += newAtoms;
  problem.bounds += newRelations;
  problem.constraints = transformedForms + newConstraints;
  
  return problem;
}

data Expr = emptyExpr(); 

Env buildEnv(Problem p) {
  Expr findDomainConstraint(str relName) {
    if (subset(variable(relName), p:product(Expr lhs, Expr rhs)) <- p.constraints) {
      return p;
    }
    
    return emptyExpr();
  }
  
  Env env = ();
  
  for (RelationalBound rb <- p.bounds) {
    list[list[Atom]] tuples = [t.atoms | Tuple t <- rb.upperBounds];
    Expr domain = emptyExpr();
    
    if (rb.arity == 1) {
      domain = variable(rb.relName);
    } else {
      domain = findDomainConstraint(rb.relName);
    }
    
    env[rb.relName] = <tuples, domain>;
  }

  return env;
}

AlleFormula transform(empty(Expr expr), Env env, Universe uni, str () newResultAtom, void (str, list[AtomDecl], list[list[Atom]], list[list[Atom]]) addRelation, void (AlleFormula) addConstraint, str () newRelNr) 
  = empty(transform(expr, env, uni, newResultAtom, addRelation, addConstraint, newRelNr));
AlleFormula transform(atMostOne(Expr expr), Env env, Universe uni, str () newResultAtom, void (str, list[AtomDecl], list[list[Atom]], list[list[Atom]]) addRelation, void (AlleFormula) addConstraint, str () newRelNr) 
  = atMostOne(transform(expr, env, uni, newResultAtom, addRelation, addConstraint, newRelNr));   
AlleFormula transform(exactlyOne(Expr expr), Env env, Universe uni, str () newResultAtom, void (str, list[AtomDecl], list[list[Atom]], list[list[Atom]]) addRelation, void (AlleFormula) addConstraint, str () newRelNr) 
  = exactlyOne(transform(expr, env, uni, newResultAtom, addRelation, addConstraint, newRelNr));
AlleFormula transform(nonEmpty(Expr expr), Env env, Universe uni, str () newResultAtom, void (str, list[AtomDecl], list[list[Atom]], list[list[Atom]]) addRelation, void (AlleFormula) addConstraint, str () newRelNr) 
  = nonEmpty(transform(expr, env, uni, newResultAtom, addRelation, addConstraint, newRelNr));
AlleFormula transform(subset(Expr lhsExpr, Expr rhsExpr), Env env, Universe uni, str () newResultAtom, void (str, list[AtomDecl], list[list[Atom]], list[list[Atom]]) addRelation, void (AlleFormula) addConstraint, str () newRelNr) 
  = subset(transform(lhsExpr, env, uni, newResultAtom, addRelation, addConstraint, newRelNr), transform(rhsExpr, env, uni, newResultAtom, addRelation, addConstraint, newRelNr));
AlleFormula transform(equal(Expr lhsExpr, Expr rhsExpr), Env env, Universe uni, str () newResultAtom, void (str, list[AtomDecl], list[list[Atom]], list[list[Atom]]) addRelation, void (AlleFormula) addConstraint, str () newRelNr) 
  = equal(transform(lhsExpr, env, uni, newResultAtom, addRelation, addConstraint, newRelNr), transform(rhsExpr, env, uni, newResultAtom, addRelation, addConstraint, newRelNr));
AlleFormula transform(inequal(Expr lhsExpr, Expr rhsExpr), Env env, Universe uni, str () newResultAtom, void (str, list[AtomDecl], list[list[Atom]], list[list[Atom]]) addRelation, void (AlleFormula) addConstraint, str () newRelNr) 
  = inequal(transform(lhsExpr, env, uni, newResultAtom, addRelation, addConstraint, newRelNr), transform(rhsExpr, env, uni, newResultAtom, addRelation, addConstraint, newRelNr));
AlleFormula transform(negation(AlleFormula form), Env env, Universe uni, str () newResultAtom, void (str, list[AtomDecl], list[list[Atom]], list[list[Atom]]) addRelation, void (AlleFormula) addConstraint, str () newRelNr) 
  = negation(transform(form, env, uni, newResultAtom, addRelation, addConstraint, newRelNr));
AlleFormula transform(conjunction(AlleFormula lhsForm, AlleFormula rhsForm), Env env, Universe uni, str () newResultAtom, void (str, list[AtomDecl], list[list[Atom]], list[list[Atom]]) addRelation, void (AlleFormula) addConstraint, str () newRelNr) 
  = conjunction(transform(lhsForm, env, uni, newResultAtom, addRelation, addConstraint, newRelNr), transform(rhsForm, env, uni, newResultAtom, addRelation, addConstraint, newRelNr));
AlleFormula transform(disjunction(AlleFormula lhsForm, AlleFormula rhsForm), Env env, Universe uni, str () newResultAtom, void (str, list[AtomDecl], list[list[Atom]], list[list[Atom]]) addRelation, void (AlleFormula) addConstraint, str () newRelNr) 
  = disjunction(transform(lhsForm, env, uni, newResultAtom, addRelation, addConstraint, newRelNr), transform(rhsForm, env, uni, newResultAtom, addRelation, addConstraint, newRelNr)); 
AlleFormula transform(implication(AlleFormula lhsForm, AlleFormula rhsForm), Env env, Universe uni, str () newResultAtom, void (str, list[AtomDecl], list[list[Atom]], list[list[Atom]]) addRelation, void (AlleFormula) addConstraint, str () newRelNr) 
  = implication(transform(lhsForm, env, uni, newResultAtom, addRelation, addConstraint, newRelNr), transform(rhsForm, env, uni, newResultAtom, addRelation, addConstraint, newRelNr));
AlleFormula transform(equality(AlleFormula lhsForm, AlleFormula rhsForm), Env env, Universe uni, str () newResultAtom, void (str, list[AtomDecl], list[list[Atom]], list[list[Atom]]) addRelation, void (AlleFormula) addConstraint, str () newRelNr) 
  = equality(transform(lhsForm, env, uni, newResultAtom, addRelation, addConstraint, newRelNr), transform(rhsForm, env, uni, newResultAtom, addRelation, addConstraint, newRelNr));

AlleFormula transform(universal(list[VarDeclaration] decls, AlleFormula form), Env env, Universe uni, str () newResultAtom, void (str, list[AtomDecl], list[list[Atom]], list[list[Atom]]) addRelation, void (AlleFormula) addConstraint, str () newRelNr) {
  bool addToEnv(str name, list[list[Atom]] tuples, Expr domain) {
    env += (name : <tuples, domain>);
    return true;
  }
  
  decls = top-down visit(decls) {
    case varDecl(str name, Expr binding) => varDecl(name, e) when Expr e := transform(binding, env, uni, newResultAtom, addRelation, addConstraint, newRelNr), addToEnv(name, e.tuples, e.domain)
  }
  
  return universal(decls, transform(form, env, uni, newResultAtom, addRelation, addConstraint, newRelNr));
} 

AlleFormula transform(existential(list[VarDeclaration] decls, AlleFormula form), Env env, Universe uni, str () newResultAtom, void (str, list[AtomDecl], list[list[Atom]], list[list[Atom]]) addRelation, void (AlleFormula) addConstraint, str () newRelNr) {
  bool addToEnv(str name, list[list[Atom]] tuples, Expr domain) {
    env += (name : <tuples, domain>);
    return true;
  }
  
  decls = top-down visit(decls) {
    case varDecl(str name, Expr binding) => varDecl(name, e) when Expr e := transform(binding, env, uni, newResultAtom, addRelation, addConstraint, newRelNr), addToEnv(name, e.tuples, e.domain)
  }
  
  return existential(decls, transform(form, env, uni, newResultAtom, addRelation, addConstraint, newRelNr));
}
default AlleFormula transform(AlleFormula f, Env env, Universe uni, str () newResultAtom, void (str, list[AtomDecl], list[list[Atom]], list[list[Atom]]) addRelation, void (AlleFormula) addConstraint, str () newRelNr) { throw "transformer for formula \'<f>\' not supported"; }

Expr transform(variable(str name), Env env, Universe uni, str () newResultAtom, void (str, list[AtomDecl], list[list[Atom]], list[list[Atom]]) addRelation, void (AlleFormula) addConstraint, str () newRelNr) 
  = variable(name, tuples=env[name].maxTuples, domain=env[name].domain);
     
Expr transform(transpose(Expr expr), Env env, Universe uni, str () newResultAtom, void (str, list[AtomDecl], list[list[Atom]], list[list[Atom]]) addRelation, void (AlleFormula) addConstraint, str () newRelNr) 
  = transpose(e, tuples=[reverse(t) | list[list[Atom]] r := e.tuples, list[Atom] t <- r], domain = e.domain) 
  when Expr e := transform(expr, env, uni, newResultAtom, addRelation, addConstraint, newRelNr); 

private list[list[Atom]] square(list[list[Atom]] tuples, int i, int sizeOfUniverse, Env env) = tuples when i >= sizeOfUniverse;
private list[list[Atom]] square(list[list[Atom]] tuples, int i, int sizeOfUniverse, Env env) = \join(n, n) when list[list[Atom]] n := square(tuples, i * 2, sizeOfUniverse, env); 

Expr transform(closure(Expr expr), Env env, Universe uni, str () newResultAtom, void (str, list[AtomDecl], list[list[Atom]], list[list[Atom]]) addRelation, void (AlleFormula) addConstraint, str () newRelNr)
  = closure(e, tuples=square(e.tuples, size(uni.atoms), size(uni.atoms), env), domain=e.domain) 
  when Expr e := transform(expr, env, uni, newResultAtom, addRelation, addConstraint, newRelNr); 
//set[Tuple] transform(reflexClosure(Expr expr), Env env) = 
Expr transform(union(Expr lhsExpr, Expr rhsExpr), Env env, Universe uni, str () newResultAtom, void (str, list[AtomDecl], list[list[Atom]], list[list[Atom]]) addRelation, void (AlleFormula) addConstraint, str () newRelNr) 
  = union(lhs,rhs, tuples = lhs.tuples + rhs.tuples, domain = union(lhs.domain, rhs.domain)) 
  when Expr lhs := transform(lhsExpr, env, uni, newResultAtom, addRelation, addConstraint, newRelNr), 
       Expr rhs := transform(rhsExpr, env, uni, newResultAtom, addRelation, addConstraint, newRelNr);  

Expr transform(intersection(Expr lhsExpr, Expr rhsExpr), Env env, Universe uni, str () newResultAtom, void (str, list[AtomDecl], list[list[Atom]], list[list[Atom]]) addRelation, void (AlleFormula) addConstraint, str () newRelNr) 
  = intersection(lhs, rhs, tuples = lhs.tuples & rhs.tuples, domain = intersection(lhs.domain, rhs.domain)) 
  when Expr lhs := transform(lhsExpr, env, uni, newResultAtom, addRelation, addConstraint, newRelNr), 
       Expr rhs := transform(rhsExpr, env, uni, newResultAtom, addRelation, addConstraint, newRelNr);

Expr transform(difference(Expr lhsExpr, Expr rhsExpr), Env env, Universe uni, str () newResultAtom, void (str, list[AtomDecl], list[list[Atom]], list[list[Atom]]) addRelation, void (AlleFormula) addConstraint, str () newRelNr) 
  = difference(lhs, rhs, tuples = lhs.tuples, domain = lhs.domain) 
  when Expr lhs := transform(lhsExpr, env, uni, newResultAtom, addRelation, addConstraint, newRelNr), 
       Expr rhs := transform(rhsExpr, env, uni, newResultAtom, addRelation, addConstraint, newRelNr);

Expr transform(\join(Expr lhsExpr, Expr rhsExpr), Env env, Universe uni, str () newResultAtom, void (str, list[AtomDecl], list[list[Atom]], list[list[Atom]]) addRelation, void (AlleFormula) addConstraint, str () newRelNr) 
  = \join(lhs, rhs, tuples = \join(lhs.tuples, rhs.tuples), domain = \join(lhs.domain, rhs.domain)) 
  when Expr lhs := transform(lhsExpr, env, uni, newResultAtom, addRelation, addConstraint, newRelNr), 
       Expr rhs := transform(rhsExpr, env, uni, newResultAtom, addRelation, addConstraint, newRelNr);

list[list[Atom]] \join(list[list[Atom]] lhs, list[list[Atom]] rhs) = [hd + tl | [*Atom hd, Atom last] <- lhs, [Atom first, *Atom tl] <- rhs, last == first];  

Expr transform(accessorJoin(Expr lhsExpr, Expr rhsExpr), Env env, Universe uni, str () newResultAtom, void (str, list[AtomDecl], list[list[Atom]], list[list[Atom]]) addRelation, void (AlleFormula) addConstraint, str () newRelNr) 
  = transform(\join(rhsExpr, lhsExpr), env, uni, newResultAtom, addRelation, addConstraint, newRelNr);

Expr transform(product(Expr lhsExpr, Expr rhsExpr), Env env, Universe uni, str () newResultAtom, void (str, list[AtomDecl], list[list[Atom]], list[list[Atom]]) addRelation, void (AlleFormula) addConstraint, str () newRelNr) 
  = product(lhs, rhs, tuples = [l + r | list[Atom] l <- lhs.tuples, list[Atom] r <- rhs.tuples], domain = product(lhs.domain, rhs.domain))
  when Expr lhs := transform(lhsExpr, env, uni, newResultAtom, addRelation, addConstraint, newRelNr),
       Expr rhs := transform(rhsExpr, env, uni, newResultAtom, addRelation, addConstraint, newRelNr);

default Expr transform(Expr expr, Env env, Universe uni, str () newResultAtom, void (str, list[AtomDecl], list[list[Atom]], list[list[Atom]]) addRelation, void (AlleFormula) addConstraint, str () newRelNr) { throw "Unable to transform expression \'<expr>\'"; }
