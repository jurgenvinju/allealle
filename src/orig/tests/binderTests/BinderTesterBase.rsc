module orig::tests::binderTests::BinderTesterBase

import orig::Binder;
import orig::AST;

import logic::Propositional;

import IO;

private Binding t(Atom x) = (<x>:\true()); 
private Binding t(Atom x, Atom y) = (<x,y>:\true());

private Binding v(Atom x) = (<x>:var(x));
private Binding v(Atom x, Atom y) = (<x,y>:var("<x>_<y>"));

private Binding f(Atom x) = (<x>:\false());
private Binding f(Atom x, Atom y) = (<x,y>:\false());

private Binding val(Atom x, Formula f) = (<x>:f);
private Binding val(Atom x, Atom y, Formula f) = (<x,y>:f);

private Binding rest(Binding orig, Universe uni, Formula val) = rest(arity(orig), orig, uni, val);
private Binding rest(1, Binding orig, Universe uni, Formula val) =
	(<x>:val | Atom x <- uni.atoms, <x> notin orig) + orig;
private Binding rest(2, Binding orig, Universe uni, Formula val) =
	(<x,y>:val | Atom x <- uni.atoms, Atom y <- uni.atoms, <x,y> notin orig) + orig;