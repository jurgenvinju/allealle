module solver::backend::z3::SolverRunner

import solver::backend::z3::Z3;

import List;
import String;
import Boolean;
import IO;
import Map;

import logic::Integer;

alias SolverPID = int;

SolverPID startSolver() {
	pid = startZ3();
	
	// make sure that the unsatisfiable core are produced
	runSolver(pid, "(set-option :produce-unsat-cores true)");
	
	return pid;
}

void stopSolver(SolverPID pid) {
	stopZ3(pid);
}

bool isSatisfiable(SolverPID pid, str smtFormula) { 
  println("Starting to check satisfiability");
	str solverResult = runSolver(pid, smtFormula, wait=20); 
	if ("" !:= solverResult) {
		throw "Unable to assert clauses: <solverResult>"; 
	} 	
	
	return checkSat(pid);
}

bool checkSat(SolverPID pid) {
	str result = runSolver(pid, "(check-sat)", wait = 5);
	
	switch(result) {
		case /unsat.*/: return false;
    case /sat.*/ : return true;
		case /unknown.*/: throw "Could not compute satisfiability";		
		default: throw "unable to get result from smt solver";
	}
}

str runSolver(SolverPID pid, str commands, int wait = 0) {
	try {
		return run(pid, commands, debug=false, wait = wait);
	}
	catch er: throw "Error while running SMT solver, reason: <er>"; 	
}