module translation::tests::relationTests::IntersectionTester

import translation::Relation;
import translation::AST;
import translation::tests::relationTests::RelationBuilder;
import smtlogic::Core;

import IO;

test bool unionCompatibleRelationsCanBeIntersected() {
  Relation r1 = create("rel1", ("id":id())).t(("id":key("r1"))).t(("id":key("r2"))).build();
  Relation r2 = create("rel2", ("id":id())).t(("id":key("r2"))).build();
  
  return intersection(r1,r2) == create("result", ("id":id())).t(("id":key("r2"))).build();
}

test bool unionIncompatibleRelationsCannotBeIntersected() {
  Relation r1 = create("rel1", ("id1":id())).t(("id1":key("r1"))).build();
  Relation r2 = create("rel2", ("id2":id())).t(("id2":key("r2"))).build();

  try {
    intersection(r1,r2);
    fail;
  } catch e: ;     
  
  return true;
}

test bool intersectionIsCommutative() {
  Relation r1 = create("rel1", ("id":id())).t(("id":key("r1"))).t(("id":key("r2"))).build();
  Relation r2 = create("rel2", ("id":id())).t(("id":key("r2"))).build();

  return intersection(r1,r2) == intersection(r2,r1);  
}

test bool intersectionIsAssociative() {
  Relation r1 = create("rel1", ("id":id())).t(("id":key("r1"))).t(("id":key("r2"))).t(("id":key("r3"))).build();
  Relation r2 = create("rel2", ("id":id())).t(("id":key("r2"))).t(("id":key("r3"))).build();
  Relation r3 = create("rel3", ("id":id())).t(("id":key("r3"))).build();

  return intersection(intersection(r1,r2),r3) == intersection(r1,intersection(r2,r3));  
}

test bool intersectionOfDistinctRelationsIsEmpty() {
  Relation r1 = create("rel1", ("id":id())).t(("id":key("r1"))).build();
  Relation r2 = create("rel2", ("id":id())).t(("id":key("r2"))).build();

  return intersection(r1,r2) == <r1.header,()>;  
}

test bool optionalRowsTrumpMandatoryRowsAfterIntersection() {
  Relation r1 = create("rel1", ("id":id())).t(("id":key("r1"))).build();
  Relation r2 = create("rel2", ("id":id())).v(("id":key("r1"))).build();
  
  return intersection(r1,r2) == create("result", ("id":id())).f(("id":key("r1")), pvar("rel2_r1")).build();
}

test bool twoOptionalRowsMustBothBePresentAfterIntersection() {
  Relation r1 = create("rel1", ("id":id())).v(("id":key("r1"))).build();
  Relation r2 = create("rel2", ("id":id())).v(("id":key("r1"))).build();
  
  return intersection(r1,r2) == create("result", ("id":id())).f(("id":key("r1")), \and(pvar("rel1_r1"),pvar("rel2_r1"))).build();
}

test bool intersectionOfNAryRelationsIsAllowed() {
  Relation r1 = create("rel1", ("pId":id(),"hId":id())).t(("pId":key("p1"),"hId":key("h1"))).build();
  Relation r2 = create("rel2", ("pId":id(),"hId":id())).t(("pId":key("p1"),"hId":key("h1"))).build();

  return intersection(r1,r2) == create("result", ("pId":id(),"hId":id()))
    .t(("pId":key("p1"),"hId":key("h1")))
    .build();
}