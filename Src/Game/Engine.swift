//
//  Engine.swift
//  Kalah
//
//  Created by Nick Utenkov on 03/02/17.
//  Copyright © 2017 nick. All rights reserved.
//

import Foundation

protocol Initable
{
	init()
}
extension Int : Initable { }
extension EvalMoves : Initable { }
extension EvlMv : Initable { }

final class EvalMoves
{
	var eval:Float = 0//was eval4SavedMoves
	var movesRepeat:ArrayN<Int> = ArrayN(30)//ArrayMovesRepeat
}

final class ArrayN<T:Initable>
{
	private var elem:[T] = []
	private var cElems = 0
	@inline(__always) init(_ maxElems:Int)
	{
		elem.reserveCapacity(maxElems)
		for _ in 0..<maxElems {elem.append(T())}
	}
	@inline(__always) func append(_ val:T)
	{
		elem[self.cElems] = val//doesn't checking bounds
		cElems += 1
	}
	subscript(i: Int) -> T
	{
		get
		{
			return elem[i]
		}
		set
		{
			elem[i] = newValue
		}
	}
	@inline(__always) func incrementElements()
	{
		cElems += 1
	}
	@inline(__always) func clear()//another name - resetCount
	{
		cElems = 0
	}
	@inline(__always) func size() -> Int
	{
		return cElems
	}
	@inline(__always) func prefix(upTo end:Int) -> ArraySlice<T>
	{
		return elem.prefix(upTo:end)
	}

	func sort(_ sortFunc:(T, T) -> Bool)
	{//for short arrays can use bubble sort
		if cElems > 1
		{
			for i in 0..<cElems
			{
				for j in i+1..<cElems
				{
					if sortFunc(elem[j],elem[i])
					{
						let tmp = elem[i]
						elem[i] = elem[j]
						elem[j] = tmp
					}
				}
			}
		}
	}
	/*func getAr() -> [T]//only for tests
	{
		return elem
	}*/
}

struct EvlMv
{
	var eval:Float = 0
	var move = 0
}

final class Engine
{
	final class Node
	{
		var m_pParent:Node? = nil,m_pChild:Node? = nil//will be retain cycles, but number of object is fixed(6*MaxTreeDepth)
		var m_pPos = Position()
		var m_level = 0,m_nMove = 0
		var m_eval:Float = 0
		var m_moves:ArrayN<Int> = ArrayN(6)

		@inline(__always) func isMaximizingNode() -> Bool
		{
			return m_pPos.whiteToMove
		}
		@inline(__always) func setMaximizingNode(_ bWhiteToMove:Bool)
		{
			m_pPos.whiteToMove = bWhiteToMove
		}

		@inline(__always) func chooseEval(_ eval1:Float)
		{
			if m_pPos.whiteToMove
			{
				if eval1 > m_eval {m_eval = eval1}
			}
			else
			{
				if eval1 < m_eval {m_eval = eval1}
			}
		}

		@inline(__always) func pruneAlphaBeta(_ evalParent:Float) -> Bool
		{
			if m_pPos.whiteToMove
			{
				if m_eval > evalParent {return true}
			}
			else
			{
				if m_eval < evalParent {return true}
			}
			return false
		}
	}

	var makeEmptyMoves = false,m_bEngineOn = false
	let useAlphaBeta = true
	var MaxLevel = 8
	var m_ReachedLevel = 0
	var m_arcEstimatedPos:[Int] = Array(repeating: Int(0), count: 6)
	let m_cpuCount = Utils.countCPU()
	let rootNode:Node = Node()
	let m_Node:[Node] = [Node(),Node(),Node(),Node(),Node(),Node()]
	let posLocal = [Position(),Position(),Position(),Position(),Position(),Position()]
	let posLocal0 = Position()
	let movesRepeat:[ArrayN<EvlMv>] = [ArrayN(6),ArrayN(6),ArrayN(6),ArrayN(6),ArrayN(6),ArrayN(6)]
	let movesCapture:[ArrayN<EvlMv>] = [ArrayN(6),ArrayN(6),ArrayN(6),ArrayN(6),ArrayN(6),ArrayN(6)]
	let movesOther:[ArrayN<EvlMv>] = [ArrayN(6),ArrayN(6),ArrayN(6),ArrayN(6),ArrayN(6),ArrayN(6)]
	let MaxTreeDepth = 200
	let MinValue:Float = -9999
	let MaxValue:Float = 9999
	let endGameEvalObj:Evaluation = EvalSimple()
	var evalObj:Evaluation = EvalSimple()

	init()
	{
		for i in 0..<6
		{
			m_Node[i].m_pParent = rootNode
			var pCurNode = m_Node[i]
			for _ in 0..<MaxTreeDepth
			{
				let pChildNode = Node()
				pChildNode.m_pParent = pCurNode
				pCurNode.m_pChild = pChildNode
				pCurNode = pChildNode
			}
		}
		startEngine()
	}

	@inline(__always) func startEngine()
	{
		m_bEngineOn = true
	}

	@inline(__always) func stopEngine()
	{
		m_bEngineOn = false
	}

	func cloneAndMakeMove(_ nodeIn:Node,_ hole:Int)
	{
		let nodeOut = nodeIn.m_pChild!
		nodeOut.m_pPos.setFrom(nodeIn.m_pPos)

		var inLevel = nodeIn.m_level
		var bMaximizingNode = nodeIn.isMaximizingNode()
		let mvType = nodeOut.m_pPos.makeMove(hole)
		if mvType != .MoveRepeat
		{
			inLevel += 1
			bMaximizingNode = !bMaximizingNode
		}
		nodeOut.m_level = inLevel
		nodeOut.setMaximizingNode(bMaximizingNode)
		nodeOut.m_eval = nodeOut.isMaximizingNode() ? MinValue : MaxValue//preliminary estimate
		nodeOut.m_nMove = hole
	}

	@inline(__always) func evalPosition(_ node:Node,_ idxMove:Int)
	{
		m_arcEstimatedPos[idxMove] += 1
		node.m_eval = evalObj.eval(node.m_pPos, idxMove)
	}

	func createMovesList(_ pos:Position,_ outMoves:ArrayN<Int>,_ posForMakeMove:Position,_ movesRepeat:ArrayN<EvlMv>,_ movesCapture:ArrayN<EvlMv>,_ movesOther:ArrayN<EvlMv>)
	{
		movesRepeat.clear()
		movesCapture.clear()
		movesOther.clear()
		var bHaveMoves = false
		for i in 0..<6
		{
			if pos.isValidMove(i) || makeEmptyMoves
			{
				bHaveMoves = true
				posForMakeMove.setFrom(pos)

				let evalInitial = posForMakeMove.eval()
				let mvType = posForMakeMove.makeMove(i)
				let deltaKalah = abs(posForMakeMove.eval() - evalInitial)

				let evlMv = EvlMv(eval: Float(deltaKalah),move: i)
				switch mvType
				{
					case .MoveRepeat :
						movesRepeat.append(evlMv)
					case .MoveOther :
						movesOther.append(evlMv)
					case .MoveCapture :
						movesCapture.append(evlMv)
					default :
						break
				}
			}
		}
		if !bHaveMoves {return}

		let sortCoef:Float = pos.whiteToMove ? 1 : -1
		movesRepeat.sort({$0.move < $1.move})
		movesCapture.sort({($0.eval-$1.eval)*sortCoef > 0})
		movesOther.sort({($0.eval-$1.eval)*sortCoef > 0})
		for i in 0..<movesCapture.size() {outMoves.append(movesCapture[i].move)}
		for i in 0..<movesRepeat.size() {outMoves.append(movesRepeat[i].move)}
		for i in 0..<movesOther.size() {outMoves.append(movesOther[i].move)}
	}

	func getEstimatedPosCount() -> Int
	{
		var rc = 0
		for i in 0..<6 {rc += m_arcEstimatedPos[i]}
		return rc
	}

	func search0(_ inPos:Position,_ pEvalMove:ArrayN<EvalMoves>,_ resetState:Bool = true)
	{
		m_ReachedLevel = 0

		rootNode.m_pPos.setFrom(inPos)
		rootNode.m_eval = inPos.whiteToMove ? MinValue : MaxValue
		rootNode.m_moves.clear()
		if resetState
		{
			for i in 0..<6 {m_arcEstimatedPos[i] = 0}
			createMovesList(inPos,rootNode.m_moves,posLocal0,movesRepeat[0],movesCapture[0],movesOther[0])
		}
		else
		{
			for i in 0..<pEvalMove.size() {rootNode.m_moves.append(pEvalMove[i].movesRepeat[0])}
		}

		for i in 0..<pEvalMove.size() {pEvalMove[i].movesRepeat.clear()}
		pEvalMove.clear()

		//inPos.printPos2()
		let oldEvalObj:Evaluation = evalObj
		if (rootNode.m_pPos.hole[6] > 28) || (rootNode.m_pPos.hole[13] > 28) {evalObj = endGameEvalObj}

		let queue:OperationQueue = OperationQueue()
		queue.maxConcurrentOperationCount = m_cpuCount
		queue.isSuspended = true
		for i in 0..<rootNode.m_moves.size()
		{
			rootNode.m_pChild = m_Node[i]//trick
			cloneAndMakeMove(rootNode,rootNode.m_moves[i])
			rootNode.m_pChild = nil  //restore

			pEvalMove.incrementElements()//not calling append because array of movesRepeat is already created
			pEvalMove[i].eval = rootNode.m_eval

			queue.addOperation(
			{
				self.search(self.m_Node[i],pEvalMove[i],i)
			})
		}
		queue.isSuspended = false
		queue.waitUntilAllOperationsAreFinished()

		evalObj = oldEvalObj
		/*for i in 0..<pEvalMove.size()
		{
			print("eval",pEvalMove[i].eval,"moves",pEvalMove[i].movesRepeat.prefix(upTo:pEvalMove[i].movesRepeat.size()))
		}*/			
	}

	func search(_ node:Node,_ evalMoves:EvalMoves,_ idxMove:Int)
	{
		if !m_bEngineOn {return}

		node.m_moves.clear()
		if node.m_level < MaxLevel
		{
			createMovesList(node.m_pPos,node.m_moves,posLocal[idxMove],movesRepeat[idxMove],movesCapture[idxMove],movesOther[idxMove])
		}

		let childNode = node.m_pChild!
		let parentNode = node.m_pParent!

		let cMoves = node.m_moves.size()
		if cMoves > 0
		{
			for i in 0..<cMoves
			{
				if !m_bEngineOn {return}
				cloneAndMakeMove(node,node.m_moves[i])
				if childNode.m_level > m_ReachedLevel {m_ReachedLevel = childNode.m_level}
				search(childNode,evalMoves,idxMove)

				node.chooseEval(childNode.m_eval)

				if useAlphaBeta && (node.m_level>1) && (node.m_level != parentNode.m_level)
				{
					if node.pruneAlphaBeta(parentNode.m_eval) {break}
				}
			}
		}
		else {evalPosition(node,idxMove)}

		if !m_bEngineOn {return}
		if ((node.m_level == 1) && (parentNode.m_level == 0)) || ((node.m_level == 0) && (cMoves == 0))
		{
			let evalCur = node.m_eval
			let branchEval = evalMoves.eval
			let bRootMaximizing = ((node.m_level == 0) ? node.isMaximizingNode() : !node.isMaximizingNode())
			let cmpResult = (bRootMaximizing ? (branchEval < evalCur) : (branchEval > evalCur))
			if cmpResult
			{
				evalMoves.eval = evalCur
				evalMoves.movesRepeat.clear()
				getMovesRepeat(node,evalMoves)
				//print("idxMove",idxMove,"eval",evalCur,"moves are",evalMoves.movesRepeat.elem.prefix(upTo:evalMoves.movesRepeat.size()))
			}
			//print("idxMode",idxMove,"cmpResult",cmpResult)
		}
	}

	func getMovesRepeat(_ node:Node,_ evalMoves:EvalMoves)
	{
		var nodeUpDown = node
		while true
		{
			let parentNode = nodeUpDown.m_pParent
			if parentNode === rootNode {break}
			nodeUpDown = parentNode!
		}
		while true
		{
			evalMoves.movesRepeat.append(nodeUpDown.m_nMove)
			if nodeUpDown === node {break}
			nodeUpDown = nodeUpDown.m_pChild!
		}
	}
}
