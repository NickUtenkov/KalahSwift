//
//  Evals.swift
//  Kalah
//
//  Created by Nick Utenkov on 29/03/17.
//  Copyright © 2017 nick. All rights reserved.
//

protocol Evaluation
{
	func eval(_ pos:Position,_ idxMove:Int) -> Float
}

final class EvalSimple : Evaluation
{
	internal func eval(_ pos: Position,_ idxMove:Int) -> Float
	{
		return Float(pos.eval())
	}
}

final class EvalRehenberg : Evaluation
{
	static var buffer:[Position] = [.init(),.init(),.init(),.init(),.init(),.init()]
	internal func eval(_ pos: Position,_ idxMove:Int) -> Float
	{
		return Float(pos.evalRehenberg(EvalRehenberg.buffer[idxMove]))
	}
}

final class EvalTseitin : Evaluation
{
	static var buffer:[Position] = [.init(),.init(),.init(),.init(),.init(),.init()]
	internal func eval(_ pos: Position,_ idxMove:Int) -> Float
	{
		return pos.evalTseitin(EvalTseitin.buffer[idxMove])
	}
}
