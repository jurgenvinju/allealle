module translation::Environment

import smtlogic::Core;

import translation::AST;
import translation::Relation;

import List;

alias Environment = tuple[map[str, Relation] relations, list[Id] idDomain, str (str) newVar]; 

Environment createInitialEnvironment(Problem p) {
  int latest = 0;
  str newVar(str varName) {
    latest += 1;
    return "_<varName>_<latest>";
  }
  
  list[Id] idDomain = extractIdDomain(p);
 
  map[str, Relation] relations = (r.name:createRelation(r) | RelationDef r <- p.relations);
   
  return <relations, idDomain, newVar>;
}   
                      
list[Id] extractIdDomain(Problem p) =
  dup([id | RelationDef r <- p.relations, AlleTuple t <- getAlleTuples(r.bounds)<1>, idd(Id id) <- t.values]);   
                                                                                                                                                    
Relation createRelation(RelationDef r) {
  str idToStr(list[AlleValue] vals) = intercalate("_", [i | idd(i) <- vals]);

  list[str] orderedHeading = [ha.name | HeaderAttribute ha <- r.heading];
  list[Domain] orderedDomains = [ha.dom | HeaderAttribute ha <- r.heading];
  Heading heading = (orderedHeading[i] : orderedDomains[i] | int i <- [0..size(orderedHeading)]);
    
  set[str] partialKey = getIdFields(heading);
  IndexedRows rows = <partialKey, []>;
  
  tuple[list[AlleTuple] lb, list[AlleTuple] ub] bounds = getAlleTuples(r.bounds);
  
  for (AlleTuple t <- bounds.lb) {
    rows = addRow(rows, <convertAlleTuple(t, r.name, idToStr(t.values), orderedHeading, orderedDomains), <\true(), \true()>>);
  }

  for (AlleTuple t <- bounds.ub, t notin bounds.lb) {
    rows = addRow(rows, <convertAlleTuple(t, r.name, idToStr(t.values), orderedHeading, orderedDomains), <pvar("<r.name>_<idToStr(t.values)>"), \true()>>);
  }
 
  return toRelation(rows,heading);
} 

tuple[list[AlleTuple], list[AlleTuple]] getAlleTuples(exact(list[AlleTuple] tuples)) = <tups,tups> when list[AlleTuple] tups := convertRangedDefinitions(tuples);
tuple[list[AlleTuple], list[AlleTuple]] getAlleTuples(atMost(list[AlleTuple] upper)) = <[], convertRangedDefinitions(upper)>;
tuple[list[AlleTuple], list[AlleTuple]] getAlleTuples(atLeastAtMost(list[AlleTuple] lower, list[AlleTuple] upper)) = <convertRangedDefinitions(lower),convertRangedDefinitions(upper)>;

Tuple convertAlleTuple(AlleTuple alleTuple, str relName, str varPostfix, list[str] attNames, list[Domain] attDomains) {
  Tuple t = ();
  for (int i <- [0..size(alleTuple.values)]) {
    t[attNames[i]] = convertToTerm(alleTuple.values[i], "<relName>_<varPostfix>_<attNames[i]>", attDomains[i]);
  }
  
  return t;
}

Term convertToTerm(idd(Id i), str _, Domain _) = lit(id(i));
Term convertToTerm(alleLit(AlleLiteral l), str attVarName, Domain _) = lit(convertToLit(l));
Term convertToTerm(hole(), str attVarName, Domain d) = convertToVar(attVarName, d); 

default Literal convertToLit(AlleLiteral l) { throw "Can not convert literal \'<l>\', no conversion function found"; }
default Term convertToVar(str varName, Domain d) { throw "Can not create a var with name \'<varName>\' for domain \'<d>\', no conversion function found";}

@memo
list[AlleTuple] convertRangedDefinitions(list[AlleTuple] tuples) = [*convertRangedDefinition(t) | AlleTuple t <- tuples];
 
list[AlleTuple] convertRangedDefinition(t:tup(list[AlleValue] _)) = [t]; 
list[AlleTuple] convertRangedDefinition(range(list[RangedValue] from, list[RangedValue] to)) {
  if (size(from) != size(to)) {
    throw "Unable to build tuples from ranges, arity of from and to do not match";
  } 
  
  list[list[Id]] newTupleIds = [];
  list[AlleValue] templates = [];
  for (int i <- [0..size(from)]) {
    if (id(str prefixFrom, int numFrom) := from[i], id(prefixTo, int numTo) := to[i]) {
      if (prefixFrom != prefixTo) {
        throw "Can not change the alphanummeric prefix in a ranged tuple for an id in the same column";
      } 
      
      newTupleIds += [["<prefixFrom><n>" | int n <- [numFrom..numTo+1]]];
    } else if (id(_,_) !:= from[i], from[i] == to[i]) {
      templates += convert(from[i]);
    } else {
      throw "Can not create tuples from declared range. Template attribute definitions do not match";
    }
  }
    
  return buildTuplesFromRange(newTupleIds, [], templates);
}  
  
list[AlleTuple] buildTuplesFromRange([], list[AlleValue] currentIds, list[AlleValue] templates) = [tup([*currentIds,*templates])];
list[AlleTuple] buildTuplesFromRange([list[Id] hd, *list[Id] tl], list[AlleValue] currentIds, list[AlleValue] templates) = [*buildTuplesFromRange(tl, currentIds + idd(i), templates) | Id i <- hd];

AlleValue convert(idOnly(Id atom)) = idd(atom);
AlleValue convert(templateLit(AlleLiteral l)) = alleLit(l);
AlleValue convert(templateHole()) = hole();
default AlleValue convert(RangedValue v) { throw "Unable to convert \'v\' to a Value"; }
