//
//  Game.swift
//  Kalah
//
//  Created by Nick Utenkov on 07/02/17.
//  Copyright © 2017 nick. All rights reserved.
//

import Foundation
import AVFoundation

final class Game
{
	var m_pWndCtrl:KalahViewController!
	var m_pEngine = Engine()
	var m_holes = Array(repeating: Int(0), count: 14)
	var m_gamePos = Position()
	var m_bIsPlaying = false,m_bIsMoveAnimating = false
	var m_bStopAnimating = false,m_bEngineThinkAndMove = false,m_bUserMoving = false
	var m_bEngineThinkOnBestUserMove = false
	var m_BestUserMoves:ArrayN<Int> = ArrayN(6)
	var m_BestUserMoves4Display:ArrayN<Int>!
	var m_tStart:UInt64 = 0,m_tEnd:UInt64 = 0
	var strTech = ["","","","",]
	var m_nMove = 0,m_idxPlies = 0
	let NumSounds = 4
	var m_snd:[SystemSoundID] = []
	let levelsPlies = [5,6,7,8]
	let UserBeginLevel = 4
	var curAnimate = 0
	var bUseSounds = false
	var bAnimateBest = false
	var bShowTech = false
	let numberFormatter = NumberFormatter()
	let strEngineFinish = "engineFinished"
	let bTestMode = false//true

	init(_ kvc:KalahViewController)
	{
		m_pWndCtrl = kvc
		updatePrefsValues()
		setPlayingLevelFromPrefs()
		if !bTestMode
		{
			m_gamePos.setInitial()
			m_gamePos.whiteToMove = true
		}
		else
		{
			m_gamePos.setFrom(Position.testPos1)
			m_gamePos.whiteToMove = false
			bAnimateBest = false
		}
		updateHoles(m_gamePos)
		loadSounds()
		numberFormatter.numberStyle = NumberFormatter.Style.decimal

		let nc = NotificationCenter.`default`
		nc.addObserver(self, selector:#selector(self.processEngineFinished), name:NSNotification.Name(rawValue:strEngineFinish), object:nil)
	}

	deinit
	{
		m_pEngine.m_bEngineOn = false
		while m_bEngineThinkAndMove {usleep(10000)}
		
		if m_bIsMoveAnimating
		{
			m_bStopAnimating = true
			waitAnimatingMoveFinished()
		}
		
		while m_bEngineThinkOnBestUserMove {usleep(10000)}
		
		unloadSounds()
	}

	func updatePrefsValues()
	{
		curAnimate = Utils.prefsGetInteger("Animate")
		m_idxPlies = Utils.prefsGetInteger("Level")
		bUseSounds = Utils.prefsGetBool("UseSounds")
		bAnimateBest = Utils.prefsGetBool("AnimateBest")
		bShowTech = Utils.prefsGetBool("ShowTech")
		m_nMove = Utils.prefsGetBool("FirstRandom") ? 0 : 1

		var evalObj:Evaluation = EvalSimple()
		let evalIdx = Utils.prefsGetInteger("EvalFunc")
		if evalIdx == 1 {evalObj = EvalRehenberg()}
		else if evalIdx == 2 {evalObj = EvalTseitin()} 
		m_pEngine.evalObj = evalObj
	}

	func setPlayingLevelFromPrefs()
	{
		m_pEngine.MaxLevel = levelsPlies[m_idxPlies]
	}

	func updateHoles(_ pos:Position)
	{
		for i in 0..<14 {m_holes[i] = pos.hole[i]}
	}

	func loadSounds()
	{
		if !(curAnimate > Anims.None.rawValue && bUseSounds) {return}
		if m_snd.count > 0 {return}
		let sndNames = ["Pop","Hero","Submarine","Tink"]
		for i in 0..<sndNames.count
		{
			let path = Bundle.main.path(forResource: sndNames[i], ofType: "caf")!
			let url = URL(fileURLWithPath: path)
			m_snd.append(0)
			AudioServicesCreateSystemSoundID(url as CFURL,&m_snd[i])
		}
	}

	func unloadSounds()
	{
		if m_snd.count == 0 {return}
		for i in 0..<m_snd.count
		{
			AudioServicesDisposeSystemSoundID(m_snd[i])
		}
		m_snd = []
	}

	@inline(__always) func waitAnimatingMoveFinished()
	{
		while m_bIsMoveAnimating {usleep(100000)}
	}

	@inline(__always) func createStateFileName() -> String
	{
		return "\(Utils.GetDocDir())/KalahState.bin"
	}

	func restoreState(_ bWhiteToMove:inout Bool)
	{
		let path = createStateFileName()
		//print(path)
		if FileManager.default.fileExists(atPath:path)
		{
			m_gamePos.readState(path)
			updateHoles(m_gamePos)
			
			bWhiteToMove = m_gamePos.whiteToMove
			m_nMove = 1//in order NO random move
		}
	}

	func saveState()
	{
		if m_bIsPlaying {m_gamePos.saveState(createStateFileName())}
		else {removeGameState()}
	}

	func removeGameState()
	{
		try? FileManager.default.removeItem(atPath: createStateFileName())
	}

	func startGame()
	{
		//if bTestMode {return}//for test purposes(making opponents moves manually)
		if m_gamePos.bothPlayersHaveMoves()
		{
			m_bIsPlaying = true
			m_pEngine.startEngine()
			
			if !m_gamePos.whiteToMove {engineThinkAndMove()}
			else
			{
				m_pWndCtrl.showStatus(0)
				if bAnimateBest {findBestUserMove()}
			}
		}
	}

	func engineThinkOnBestUser()
	{
		m_bEngineThinkOnBestUserMove = true

		let gamePos4BestUserMove = Position()
		gamePos4BestUserMove.setFrom(m_gamePos)
		gamePos4BestUserMove.whiteToMove = true

		let EM:ArrayN<EvalMoves> = ArrayN(6)

		for lvl in UserBeginLevel..<7
		{
			m_pEngine.MaxLevel = lvl

			let tStart = mach_absolute_time()
			m_pEngine.search0(gamePos4BestUserMove,EM,lvl==UserBeginLevel)
			let tEnd = mach_absolute_time()
			if m_pEngine.m_bEngineOn
			{
				EM.sort({$0.eval > $1.eval})
				m_BestUserMoves.clear()//because we are in loop
				let initialEval = EM[0].eval
				for i in 0..<EM.size()
				{
					if (EM[i].eval != initialEval) {break}
					m_BestUserMoves.append(EM[i].movesRepeat[0])
				}
			}
			else {break}
			//print("elapsed",Utils.getSeconds(tEnd-tStart))
			if (Utils.getSeconds(tEnd-tStart) > 1.0) {break}
		}
		
		m_bEngineThinkOnBestUserMove = false
	}

	func findBestUserMove()
	{
		m_BestUserMoves.clear()
		if (!m_gamePos.bothPlayersHaveMoves()) {return}
		if (m_gamePos.userHaveMoreThanOneMove())
		{
			DispatchQueue.global(qos: .background).async(execute:
			{
				self.engineThinkOnBestUser()
			})
		}
	}

	func stopGame()
	{
		m_pEngine.stopEngine()
		
		if m_bIsMoveAnimating
		{
			m_bStopAnimating = true
			waitAnimatingMoveFinished()
			m_bStopAnimating = false
		}
		
		while m_bEngineThinkAndMove {usleep(100000)}
		while m_bEngineThinkOnBestUserMove {usleep(10000)}
		m_bIsPlaying = false
	}

	func newGame(_ userTurnFirst:Bool)//user always play white(but these doesn't mean he always turns first !)
	{
		stopGame()
		removeGameState()
		m_pWndCtrl.showEngineEstimates(nil)

		if !bTestMode
		{
			m_gamePos.setInitial()
			m_gamePos.whiteToMove = userTurnFirst
			m_nMove = 0
		}
		else
		{
			m_gamePos.setFrom(Position.testPos1)
			m_gamePos.whiteToMove = false
			m_nMove = 1//in order NO random move
			bAnimateBest = false
		}
		updateHoles(m_gamePos)
		

		startGame()
	}

	func updateFieldAtEnd(_ pPos:Position)
	{
		updateHoles(m_gamePos)
		
		m_pWndCtrl.drawField()
		
		let deltaKalah = m_gamePos.deltaKalahs()
		if deltaKalah != 0
		{
			m_pWndCtrl.saveWiner(deltaKalah<0)
			m_pWndCtrl.saveFormatValue(abs(deltaKalah))
			m_pWndCtrl.showStatus(5)
		}
		else {m_pWndCtrl.showStatus(2)}
		
		m_bIsPlaying = false
		
		removeGameState()
	}

	func isBestUserMove(_ idxUserMoved:Int) -> Bool
	{
		let bumCount = m_BestUserMoves4Display.size()
		if bumCount == 0 {return true}
		
		for i in 0..<bumCount
		{
			if idxUserMoved==m_BestUserMoves4Display[i] {return true}
		}
		
		return false
	}

	func userMoved(_ idx:Int)
	{
		if !m_bIsPlaying {return}
		if m_bEngineThinkAndMove {return}
		if m_bIsMoveAnimating {return}
		m_gamePos.whiteToMove = true
		if !m_gamePos.isValidMove(idx) {return}
		
		if m_bUserMoving {return}
		m_bUserMoving = true
		
		updateHoles(m_gamePos)
		
		if m_bEngineThinkOnBestUserMove
		{
			m_pEngine.stopEngine()
			while m_bEngineThinkOnBestUserMove {usleep(100000)}
			m_pEngine.startEngine()
		}

		m_BestUserMoves4Display = m_BestUserMoves
		var bIsBestUserMove = false
		if bAnimateBest {bIsBestUserMove = isBestUserMove(idx)}
		animateMove(idx,m_gamePos.whiteToMove,true,bIsBestUserMove)//move is shown quickly(very little delay,that's why not using thread)

		let mvType = m_gamePos.makeMove(idx)
		if !m_gamePos.bothPlayersHaveMoves()
		{
			m_bUserMoving = false
			waitAnimatingMoveFinished()
			updateFieldAtEnd(m_gamePos)
			m_pWndCtrl.showEngineEstimates(nil)
			return
		}

		if mvType == .MoveRepeat
		{
			if bAnimateBest {findBestUserMove()}//can NOT to check m_gamePos.Both Players Have Moves()
			m_bUserMoving = false;
			return
		}

		engineThinkAndMove()
		
		m_bUserMoving = false
	}

	func opponentMoved(_ idx:Int)//for test purposes
	{
		animateMove(idx,m_gamePos.whiteToMove,true,false)//move is shown quickly(very little delay,that's why not using thread)
		_ = m_gamePos.makeMove(idx)
		updateHoles(m_gamePos)
	}

	func animateMove(_ hole:Int,_ whiteToMove:Bool,_ isUserMove:Bool,_ isBestUserMove:Bool)
	{
		m_bIsMoveAnimating = true
		
		let arHoles = whiteToMove ? Position.arrayWhite : Position.arrayBlack
		let idx = arHoles[hole],cStones = m_holes[idx]
		if isUserMove && !isBestUserMove && bAnimateBest
		{
			if (!whiteToMove)
			{
				for i in 0..<m_BestUserMoves4Display.size()
				{
					m_BestUserMoves4Display[i] += 7
				}
			}
			animateHoles(m_BestUserMoves4Display,3,7)
			drawHolesAndDelay(m_BestUserMoves4Display,0,0)
		}
		
		blinkHole(idx,3,4)//animate first hole
		m_holes[idx] = 0
		drawHoleAndDelay(idx,0,0)
		
		let lastStoneHole = arHoles[hole + cStones]
		let isRepeatMove = ((lastStoneHole-Position.IdxTurnDelta(whiteToMove))==6)
		
		for i in 1..<cStones+1
		{
			let idx = arHoles[hole+i]
			m_holes[idx] += 1
			if (!isRepeatMove || (isRepeatMove && (i != cStones )))//kalah hole will be animated later
			{
				drawHoleAndDelay(idx,4,(curAnimate==Anims.Slow.rawValue) ? 0.35 : 0.1,bUseSounds ? ( (idx > 6) ? m_snd[3] : m_snd[0] ) : 0)
				drawHoleAndDelay(idx,0,0)
			}
		}
		
		if !isRepeatMove
		{
			if (lastStoneHole-Position.IdxTurnDelta(whiteToMove)) != 6//capture for last stone in kalah is not applicapable
			{
				if (m_holes[lastStoneHole] == 1) && (m_holes[12 - lastStoneHole] != 0) && ((whiteToMove && (lastStoneHole<6)) || (!whiteToMove && (lastStoneHole>6)) )
				{
					let idx = 6+Position.IdxTurnDelta(whiteToMove)
					let deltaKalah = m_holes[12 - lastStoneHole] + 1
					
					m_holes[lastStoneHole] = 0
					drawHoleAndDelay(lastStoneHole,0,0)
					
					blinkHole(12 - lastStoneHole,3,6,bUseSounds ? m_snd[2] : 0)//animate captured hole
					m_holes[12 - lastStoneHole] = 0
					drawHoleAndDelay(12 - lastStoneHole,0,0)
					
					m_holes[idx] += deltaKalah
					drawHoleAndDelay(idx,4,(curAnimate==Anims.Slow.rawValue) ? 0.3 : 0.1)//animate kalah
					drawHoleAndDelay(idx,0,0)
				}
			}
		}
		else 
		{
			blinkHole(lastStoneHole,3,5,bUseSounds ? m_snd[1] : 0)//animate kalah hole
			drawHoleAndDelay(lastStoneHole,0,0)
		}
		
		m_bIsMoveAnimating = false
	}

	func drawHoleAndDelay(_ idx:Int,_ idxColor:Int,_ secs:Float,_ sndId:SystemSoundID = 0)
	{
		if (secs != 0) && m_bStopAnimating {return}
		if (secs != 0) && !(curAnimate > Anims.Fast_rep.rawValue) {return}
		
		m_pWndCtrl.drawHole(idx,holeStones:m_holes[idx],holeColor:idxColor)
		if sndId != 0 {AudioServicesPlaySystemSound(sndId)}
		if secs > 0 {usleep(UInt32(secs*1000000))}
	}

	func drawHolesAndDelay(_ idxs:ArrayN<Int>,_ idxColor:Int,_ secs:Float)
	{
		if (secs != 0) && m_bStopAnimating {return}
		if (secs != 0) && !bAnimateBest {return}
		
		for i in 0..<idxs.size() {m_pWndCtrl.drawHole(idxs[i],holeStones:m_holes[idxs[i]],holeColor:idxColor)}
		
		if secs > 0 {usleep(UInt32(secs*1000000))}
	}

	func drawEmptyHoleAndDelay(_ idx:Int,_ secs:Float)
	{
		if (m_bStopAnimating) {return}
		if (secs != 0) && !(curAnimate > Anims.Fast_rep.rawValue) {return}
		
		m_pWndCtrl.drawHole(idx,holeStones:-1,holeColor:0)
		
		if secs > 0 {usleep(UInt32(secs*1000000))}
	}

	func drawEmptyHolesAndDelay(_ idxs:ArrayN<Int>,_ secs:Float)
	{
		if m_bStopAnimating {return}
		if (secs != 0) && !bAnimateBest {return}
		
		for i in 0..<idxs.size() {m_pWndCtrl.drawHole(idxs[i],holeStones:-1,holeColor:0)}
		
		if secs > 0 {usleep(UInt32(secs*1000000))}
	}

	func animateHoles(_ idxs:ArrayN<Int>,_ count:Int,_ idxColor:Int)
	{
		if m_bStopAnimating {return}
		for _ in 0..<count
		{
			drawHolesAndDelay(idxs,idxColor,0.15)
			drawEmptyHolesAndDelay(idxs,0.15)
		}
	}

	func blinkHole(_ idx:Int,_ count:Int,_ idxColor:Int,_ sndId:SystemSoundID = 0)
	{
		if (m_bStopAnimating) {return}
		var cnt = count
		let nAnimate = curAnimate
		if (nAnimate==Anims.Fast_rep.rawValue || nAnimate==Anims.Fast.rawValue) {cnt = 2}
		for i in 0..<cnt
		{
			drawHoleAndDelay(idx,idxColor,0.15,(i==0) ? sndId : 0)
			drawEmptyHoleAndDelay(idx,0.15)
		}
	}

	func chooseEngineMove(_ pEM:ArrayN<EvalMoves>) -> ArrayN<Int>
	{
		var k = 0
		let initialEval = pEM[0].eval
		for i in 0..<pEM.size()
		{
			if pEM[i].eval != initialEval {break}
			k += 1
		}
		var idx:UInt32 = 0
		if k > 1
		{
			srandom(UInt32(time(nil)))
			// From Cocoa Design Patterns
			// the least significant bits of the value returned by random() are
			// not very random. Shifting those bits out of the way produces
			// better small random numbers
			idx = (arc4random() >> 5) % UInt32(k)
		}
		return pEM[Int(idx)].movesRepeat
	}

	@objc func processEngineFinished(notification: NSNotification)
	{
		let evalMove:ArrayN<EvalMoves> = notification.object as! ArrayN<EvalMoves>
		Utils.runOnUI
		{[unowned self] in
			self.epilogEngineMove(evalMove)
			self.animateEngineMove(evalMove)
			self.finishEngineThinkOnMove()
		}
	}

	func engineThinkAndMove()
	{
		m_bEngineThinkAndMove = true

		setPlayingLevelFromPrefs()

		let evalMove:ArrayN<EvalMoves> = ArrayN(6)

		m_nMove += 1
		m_gamePos.whiteToMove = false
		if m_nMove != 1//1-st engine move is random
		{
			prologEngineMove()
			DispatchQueue.global(qos: .background).async(execute:
			{
				self.findEngineMove(evalMove)
			})
		}
		else//let make any move
		{
			chooseSomeEngineMove(evalMove)
			animateEngineMove(evalMove)
			finishEngineThinkOnMove()
		}
	}

	func prologEngineMove()
	{
		m_pWndCtrl.showStatus(1)
		if bShowTech {m_pWndCtrl.setTimerShowTechLine(true)}
		
		setPlayingLevelFromPrefs()
		
		if bShowTech
		{
			m_pWndCtrl.startTimerOnMainThread()//will no updating if run on current thread
		}
	}

	func epilogEngineMove(_ evalMove:ArrayN<EvalMoves>)
	{
		if bShowTech
		{
			m_pWndCtrl.stopTimer()
			m_pWndCtrl.showTech()
			m_pWndCtrl.showEngineEstimates(evalMove)
			m_pWndCtrl.setTimerShowTechLine(false)
		}
	}

	func findEngineMove(_ evalMove:ArrayN<EvalMoves>)
	{
		m_pEngine.MaxLevel = levelsPlies[m_idxPlies]
		m_tEnd = 0
		m_tStart = mach_absolute_time()
		m_pEngine.search0(m_gamePos,evalMove,true)
		m_tEnd = mach_absolute_time()
		evalMove.sort({$0.eval < $1.eval})
		NotificationCenter.`default`.post(name:NSNotification.Name(rawValue:strEngineFinish),object:evalMove)
	}

	func chooseSomeEngineMove(_ evalMove:ArrayN<EvalMoves>)
	{
		evalMove.clear()
		let tmpPos = Position()
		for i in 0..<6
		{
			if m_gamePos.isValidMove(i)
			{
				let move1 = EvalMoves()
				move1.eval = 0
				move1.movesRepeat.append(i)
				tmpPos.setFrom(m_gamePos)
				let mvType = tmpPos.makeMove(i)
				if (mvType == .MoveRepeat)
				{
					let movesForRandom:ArrayN<Int> = ArrayN(6)
					createSimpleMovesList(tmpPos,movesForRandom)
					//move1.eval4SavedMoves = 1;//for test purpose
					let cMovesForRandom = movesForRandom.size()
					srandom(UInt32(time(nil)))
					let idx = Int(arc4random() >> 5) % cMovesForRandom
					move1.movesRepeat.append(movesForRandom[idx])
				}
				evalMove.append(move1)
			}
		}
	}

	func finishEngineThinkOnMove()
	{
		m_gamePos.whiteToMove = true
		
		if m_pEngine.m_bEngineOn
		{
			if (bAnimateBest && m_gamePos.bothPlayersHaveMoves()) {findBestUserMove()}
			
			waitAnimatingMoveFinished()//wait engine move (or user move (if engine stopped)) animating
			
			if !m_gamePos.bothPlayersHaveMoves()
			{
				updateFieldAtEnd(m_gamePos)
				m_pWndCtrl.showEngineEstimates(nil)
			}
			else {m_pWndCtrl.showStatus(0)}
		}
		//print("Pos/sec",getStatusLine(2))
		
		m_bEngineThinkAndMove = false
	}

	func animateEngineMove(_ evalMove:ArrayN<EvalMoves>)
	{
		if m_pEngine.m_bEngineOn
		{
			let moves = chooseEngineMove(evalMove)
			waitAnimatingMoveFinished()//in case search end while animating user move
			
			let cMoves = moves.size()
			let nSavedAnimate = curAnimate
			if cMoves>1 && curAnimate == Anims.Fast_rep.rawValue
			{
				curAnimate = Anims.Fast.rawValue
			}
			for i in 0..<cMoves
			{
				if curAnimate > Anims.None.rawValue
				{
					if m_bIsMoveAnimating
					{
						m_pWndCtrl.saveFormatValue(6-moves[i])
						m_pWndCtrl.showStatus(3)
					}
				}
				
				if m_pEngine.m_bEngineOn
				{
					if curAnimate > Anims.None.rawValue
					{
						m_pWndCtrl.saveFormatValue(6-moves[i])
						m_pWndCtrl.showStatus(4)
						
						usleep(1000000);
					}
					
					updateHoles(m_gamePos)
					animateMove(moves[i],m_gamePos.whiteToMove,false,false)
					
					_ = m_gamePos.makeMove(moves[i])
				}
			}
			curAnimate = nSavedAnimate
		}
	}

	func createSimpleMovesList(_ pos:Position,_ moves:ArrayN<Int>)
	{
		for i in 0..<6
		{
			if pos.isValidMove(i) {moves.append(i)}
		}
	}

	@inline(__always) func getHoleVal(_ idx:Int) -> Int
	{
		return m_holes[idx]
	}

	@inline(__always) func getElapsedTime() -> UInt64
	{
		return (m_tEnd == 0) ? mach_absolute_time() : m_tEnd
	}

	func getStatusLine(_ idx:Int) -> String
	{
		let t1 = Utils.getSeconds(getElapsedTime()-m_tStart)
		switch idx
		{
			case 0 :
				strTech[0] = numberFormatter.string(from: NSNumber(value: m_pEngine.getEstimatedPosCount()))!
			case 1 :
				let t2 = floor(t1+0.5)
				if fabs(t2-t1) < 0.01 {strTech[1] = String(format:"%1.0f",t2)}
				else {strTech[1] = String(format:"%4.2f",t1)}
			case 2 :
				strTech[2] = String(format:"%4.2f",Double(m_pEngine.getEstimatedPosCount())/1000000.0/t1)
			default :
				break
		}
		return strTech[idx]
	}
}
