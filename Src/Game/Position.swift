//
//  Position.swift
//  Kalah
//
//  Created by Nick Utenkov on 03/02/17.
//  Copyright © 2017 nick. All rights reserved.
//

import Foundation

final class Position
{
	/*private */var hole:[Int] = Array(repeating: Int(),count: 14 )
	var whiteToMove:Bool = false
	static let arrayWhite:[Int] = [0,1,2, 3, 4, 5, 6,7,8,9,10,11,12,0,1,2, 3, 4, 5, 6,7,8,9,10,11,12,0,1,2, 3, 4, 5, 6,7,8,9,10,11,12,0,1,2, 3, 4, 5, 6,7,8,9,10,11,12]
	static let arrayBlack:[Int] = [7,8,9,10,11,12,13,0,1,2, 3, 4, 5,7,8,9,10,11,12,13,0,1,2, 3, 4, 5,7,8,9,10,11,12,13,0,1,2, 3, 4, 5,7,8,9,10,11,12,13,0,1,2, 3, 4, 5]
	static let testPos1:[Int] = [1,1,1,1,1,1,25,6,5,4,3,2,1,20]//(18 moves)
	static let testPos2:[Int] = [1,1,1,1,1,1,25,0,1,2,0,1,1,36]
	static let testPos3:[Int] = [0,2,1,1,1,1,25,0,0,3,0,1,1,36]
	static let testPos4:[Int] = [0,0,2,2,1,0,26,0,0,0,1,2,1,37]
	static let testPos5:[Int] = [4, 3, 0, 12, 11, 0, 7, 0, 0, 2, 10, 10, 10, 3]
	static let testPos13:[Int] = [0,2,2,2,1,4,20,6,5,4,3,2,1,20]
	static let testPos14:[Int] = [2,2,2,2,1,2,20,6,5,4,3,2,1,20]//original test pos(18 moves)
	static let testPos15:[Int] = [4,1,2,0,0,13,17,3,2,0,13,1,10]//oppo to move,long think(842,590,390 pos 543.08 secs on level 8 ?!)
	enum MoveType:Int
	{
		case MoveSkip = -1,MoveCapture,MoveRepeat,MoveOther
	}

	func setInitial()
	{
		for i in 0..<6
		{
			hole[i+0] = 6
			hole[i+7] = 6
		}
		hole[ 6] = 0
		hole[13] = 0

		whiteToMove = true
	}

	func setFrom(_ posIn:Position)
	{
		for i in 0..<14 {hole[i] = posIn.hole[i]}
		whiteToMove = posIn.whiteToMove
	}
	func setFrom(_ arHoles:[Int])
	{
		for i in 0..<14 {hole[i] = arHoles[i]}
	}

	@inline(__always) static func IdxTurnDelta(_ isWhiteMoving:Bool) -> Int
	{
		return isWhiteMoving ? 0 : 7
	}

	func makeMove(_ idxHole:Int) -> MoveType
	{
		var isRepeatMove = false
		var mvType:MoveType = MoveType.MoveOther
		let arHoles = whiteToMove ? Position.arrayWhite : Position.arrayBlack
		let idx = arHoles[idxHole]
		let cStones = hole[idx]
		hole[idx] = 0

		for i in 1..<cStones+1 {hole[arHoles[idxHole+i]] += 1}

		let lastStoneHole = arHoles[idxHole + cStones]
		isRepeatMove = ((lastStoneHole-Position.IdxTurnDelta(whiteToMove))==6)
		if isRepeatMove {mvType = MoveType.MoveRepeat}
		
		if !isRepeatMove
		{
			if lastStoneHole-Position.IdxTurnDelta(whiteToMove) != 6//capture for last stone in kalah is not applicapable
			{
				if ((hole[lastStoneHole] == 1) && (hole[12 - lastStoneHole] != 0) && ((whiteToMove && (lastStoneHole<6)) || (!whiteToMove && (lastStoneHole>6)) ))
				{
					hole[6+Position.IdxTurnDelta(whiteToMove)] += hole[12 - lastStoneHole] + 1
					hole[lastStoneHole] = 0
					hole[12 - lastStoneHole] = 0
					mvType = MoveType.MoveCapture
				}
			}
		}
		if mvType == MoveType.MoveCapture {_ = bothPlayersHaveMoves()}
		else {_ = playerHolesEmptied(whiteToMove)}
		
		return mvType
	}

	func playerHolesEmptied(_ forWhite:Bool) -> Bool
	{
		let arHolesCheck = forWhite ? Position.arrayWhite : Position.arrayBlack
		let arHolesFrom = forWhite ? Position.arrayBlack : Position.arrayWhite
		let idxKalah = forWhite ? 13 : 6
		
		for i in 0..<6
		{
			if hole[arHolesCheck[i]] != 0 {return false}
		}
		for i in 0..<6
		{
			hole[idxKalah] += hole[arHolesFrom[i]]
			hole[arHolesFrom[i]] = 0
		}
		return true
	}

	func bothPlayersHaveMoves() -> Bool
	{
		return !playerHolesEmptied(true) && !playerHolesEmptied(false)
	}

	@inline(__always) func isValidMove(_ idxHole:Int) -> Bool
	{
		return hole[idxHole + Position.IdxTurnDelta(whiteToMove)] != 0
	}

	func userHaveMoreThanOneMove() -> Bool
	{
		var cMoves = 0
		for i in 0..<6 {if hole[i] != 0 {cMoves += 1}}
		return cMoves > 1
	}

	func calcHoleActivity(_ idxHole:Int,_ cStones:Int,_ bWhiteToMove:Bool) -> Int
	{//using only hole array from position
		var rc = 0
		let arHolesOur = bWhiteToMove ? Position.arrayWhite : Position.arrayBlack
		let arHolesOpp = bWhiteToMove ? Position.arrayBlack : Position.arrayWhite//opponent
		for i in 0..<14 {hole[i] = 0}
		for i in 1..<cStones+1 {hole[arHolesOur[idxHole+i]] += 1}

		for i in 0..<6
		{
			rc += hole[arHolesOur[i]]
			rc -= hole[arHolesOpp[i]]
		}
		rc += 7//for not be negative after subtraction
		return rc
	}
	
	/*@inline(__always)*/ func eval() -> Int
	{
		var deltaKalahWhite = 0,deltaKalahBlack = 0
		var sumWhite = 0
		for i in 0..<6 {sumWhite += hole[i]}
		var sumBlack = 0
		for i in 7..<13 {sumBlack += hole[i]}
		if (sumWhite == 0) || (sumBlack == 0)
		{
			deltaKalahWhite += sumWhite
			deltaKalahBlack += sumBlack
		}
		return (hole[6]+deltaKalahWhite) - (hole[13]+deltaKalahBlack)
	}

	func evalRehenberg(_ posBuffer:Position) -> Int
	{
		var sumWhiteHolesActivity = 0
		var sumBlackHolesActivity = 0

		for i in 0..<6
		{
			if hole[i + 0] != 0
			{
				sumWhiteHolesActivity += posBuffer.calcHoleActivity(i,hole[i + 0],true)
			}
			if hole[i + 7] != 0
			{
				sumBlackHolesActivity += posBuffer.calcHoleActivity(i,hole[i + 7],false)
			}
		}
		return hole[6]*sumWhiteHolesActivity - hole[13]*sumBlackHolesActivity
	}

	func evalTseitin(_ posBuffer:Position) -> Float
	{
		var sumWhiteHolesActivity = 0
		var sumBlackHolesActivity = 0
		
		for i in 0..<6
		{
			if hole[i + 0] != 0
			{
				sumWhiteHolesActivity += posBuffer.calcHoleActivity(i,hole[i + 0],true)
			}
			if hole[i + 7] != 0
			{
				sumBlackHolesActivity += posBuffer.calcHoleActivity(i,hole[i + 7],false)
			}
		}
		var a1:Float = 0
		if hole[6] < 37
		{
			let h6:Float = Float(hole[6])
			a1 = h6 + 17.3/(37.0 - Float(h6))
			if sumWhiteHolesActivity > 0 {a1 -= 40.0/Float(sumWhiteHolesActivity)}
		}
		else {a1 = 999}

		var a2:Float = 0
		if hole[13] < 37
		{
			let h13:Float = Float(hole[13])
			a2 = h13 + 17.3/(37.0 - h13) 
			if sumBlackHolesActivity > 0 {a2 -= 40.0/Float(sumBlackHolesActivity)}
		}
		else {a2 = 999}
		return a1 - a2 + (whiteToMove ? 1.72 : -1.72)
	}

	func saveState(_ path:String)
	{
		NSKeyedArchiver.setClassName("ArchiveHelper", for: ArchiveHelper.self)
		NSKeyedArchiver.archiveRootObject(ArchiveHelper(self),toFile:path)
	}

	func readState(_ path:String)
	{
		NSKeyedUnarchiver.setClass(ArchiveHelper.self, forClassName: "ArchiveHelper")
		if let arch = NSKeyedUnarchiver.unarchiveObject(withFile:path) as? ArchiveHelper
		{
			setFrom(arch.pos)
		}
	}

	@inline(__always) func deltaKalahs() -> Int
	{
		return hole[6]-hole[13]
	}

	func printPos()
	{
		print("")
		print(String(format:"    (%2d) (%2d) (%2d) (%2d) (%2d) (%2d)",hole[12-0],hole[12-1],hole[12-2],hole[12-3],hole[12-4],hole[12-5]))
		print(String(format:"[%2d]                             [%2d]",hole[13],hole[6]))
		print(String(format:"    (%2d) (%2d) (%2d) (%2d) (%2d) (%2d)",hole[0],hole[1],hole[2],hole[3],hole[4],hole[5]))
	}
	func printPos2()
	{
		print(hole)
	}
}

extension Position
{
	//used for Position not be NSObject
	final class ArchiveHelper : NSObject,NSCoding
	{
		var pos:Position

		init(_ inPos:Position)
		{
			pos = inPos
		}

		convenience init(coder aDecoder: NSCoder)
		{
			self.init(Position())
			pos.hole = aDecoder.decodeObject(forKey: "holes") as! [Int]
			pos.whiteToMove = aDecoder.decodeBool(forKey: "whiteToMove")
		}

		func encode(with aCoder: NSCoder)
		{
			aCoder.encode(pos.hole, forKey: "holes")
			aCoder.encode(pos.whiteToMove, forKey: "whiteToMove")
		}
	}
}
