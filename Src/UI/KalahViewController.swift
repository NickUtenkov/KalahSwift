
import UIKit
import Foundation

enum Anims:Int
{
	case None = 0,Fast_rep,Fast,Slow
}

final class KalahViewController: UIViewController
{
	@IBOutlet var gameView: UIView!
	@IBOutlet var stxtComp: UILabel!
	@IBOutlet var stxtYou: UILabel!
	@IBOutlet var statusLine: UILabel!
	@IBOutlet var boxTech: UIView!//super view for 4 below labels
	@IBOutlet var stxtPos: UILabel!
	@IBOutlet var stxtSecs: UILabel!
	@IBOutlet var stxtPosHead: UILabel!
	@IBOutlet var stxtSecsHead: UILabel!
	@IBOutlet var stxtFirstTurnVal: UILabel!
	@IBOutlet var stxtFirstTurnHead: UILabel!
	@IBOutlet var btnNewGame: UIButton!
	@IBOutlet var boxTech2: UIView!//super view for engine estimates
	var estimates:[UILabel] = Array(repeating: UILabel(),count: 6)//single UILabel() object will be replaced
	var holes:[UILabel] = Array(repeating: UILabel(),count: 14 )//single UILabel() object will be replaced
	var rects:[CGRect] = Array(repeating: CGRect.zero,count: 6)
	var rects4FirstTurn:[CGRect] = Array(repeating: CGRect.zero,count: 2)
	var rectsOpponent:[CGRect] = Array(repeating: CGRect.zero,count: 6)
	var tech:[UILabel] = Array( repeating: UILabel(),count: 2)//single UILabel() object will be replaced
	var techHead:[UILabel] = Array(repeating: UILabel(),count: 2)//single UILabel() object will be replaced
	var clr:[UIColor] = Array(repeating: UIColor(),count: 8)//single UIColor() object will be replaced
	var m_Timer: Timer!
	var m_bUserFirst = false
	var m_bShowTimedTechLine = false
	var m_pKalahGame: Game!
	var strNS:[String] = Array(repeating: "",count: 6)
	var savedVal = 0
	var winer:Bool = false
	var idxUserMoved = 0

	required init?(coder aDecoder: NSCoder)
	{
		super.init(coder: aDecoder)
		Utils.prefsInit()
	}

	override func viewDidLoad()
	{
		super.viewDidLoad()
		doViewDidLoad()
	}

	func doViewDidLoad()
	{
		for i in 0..<14
		{
			holes[i] = gameView.viewWithTag((i + 1))! as! UILabel
			holes[i].isUserInteractionEnabled = false
		}
		m_Timer = nil
		m_bShowTimedTechLine = false
		tech[0] = stxtPos
		tech[0].text = " "
		tech[1] = stxtSecs
		tech[1].text = " "
		techHead[0] = stxtPosHead
		techHead[1] = stxtSecsHead
		m_pKalahGame = Game(self)
		m_pKalahGame.restoreState(&m_bUserFirst)
		self.drawField()
		stxtFirstTurnVal.text = (m_bUserFirst ? stxtYou.text : stxtComp.text)
		boxTech.isHidden = !Utils.prefsGetBool("ShowTech")
		boxTech2.isHidden = !Utils.prefsGetBool("ShowTech")
		for i in 0..<6
		{
			estimates[i] = boxTech2.viewWithTag((i + 100))! as! UILabel
		}
		showEngineEstimates(nil)
		for i in 0..<6
		{
			rects[i] = holes[i].frame
		}
		//extends rectangles
		rects[0].size.width += rects[0].origin.x
		rects[0].origin.x = 0
		rects[5].size.width += gameView.frame.size.width - (rects[5].origin.x + rects[5].size.width)
		let pView = gameView.viewWithTag(200)!
		//field
		let deltaH = pView.frame.origin.y + pView.frame.size.height - (rects[0].origin.y + rects[0].size.height)
		for i in 0..<6
		{
			rects[i].size.height += deltaH
		}
		rects4FirstTurn[0] = stxtFirstTurnVal.frame
		rects4FirstTurn[1] = stxtFirstTurnHead.frame
		
		for i in 0..<6
		{
			rectsOpponent[i] = holes[i+7].frame
		}
		
		for i in 0..<8
		{
			clr[i] = Utils.prefsGetColor(i)
		}
		
		self.setHolesColor()
		self.setStatusLineColor()
		self.setForeColor()
		self.view.backgroundColor = nil
		let defNtfCenter = NotificationCenter.default
		defNtfCenter.addObserver(self, selector: #selector(self.notifyPrefsChanged), name: UserDefaults.didChangeNotification, object: nil)
		defNtfCenter.addObserver(self, selector: #selector(self.gameSaveState), name: NSNotification.Name.UIApplicationWillResignActive, object: nil)
		try? FileManager.default.createDirectory(at:URL(fileURLWithPath:Utils.GetDocDir()), withIntermediateDirectories: false, attributes: nil)
		
		btnNewGame.decorate(5,1,UIColor(red:0.5,green:0.5,blue:0.5,alpha:1.0))
		btnNewGame.applyGradient(colours:[UIColor(red:0.84,green:0.84,blue:0.84,alpha:1.0),UIColor(red:0.34,green:0.34,blue:0.34,alpha:1.0)])
	}

	override func viewDidAppear(_ animated: Bool)
	{
		super.viewDidAppear(animated)
		self.view.window!.backgroundColor = clr[3]

		self.loadLocStrings()
		self.showStatus(0)
		m_pKalahGame.startGame()
	}

	@objc func notifyPrefsChanged(_ sender: AnyObject)
	{
		boxTech.isHidden = !Utils.prefsGetBool("ShowTech")
		boxTech2.isHidden = !Utils.prefsGetBool("ShowTech")
		for i in 0..<8
		{
			clr[i] = Utils.prefsGetColor(i)
		}
		self.setHolesColor()
		self.setStatusLineColor()
		self.setForeColor()
		self.view.window!.backgroundColor = clr[3]
		m_pKalahGame.updatePrefsValues()
		let animVal = Utils.prefsGetInteger("Animate")
		if animVal > 0 && Utils.prefsGetBool("UseSounds")
		{
			m_pKalahGame.loadSounds()
		}
		else
		{
			m_pKalahGame.unloadSounds()
		}
	}

	func setNewGame(_ isHumanFirst: Bool)
	{
		m_pKalahGame.newGame(isHumanFirst)
		self.drawField()
		for i in 0..<2
		{
			tech[i].text = " "
		}
	}

	@IBAction func newGame()
	{
		setNewGame(m_bUserFirst)
	}

	func drawField()
	{
		for i in 0..<14 {holes[i].text = "\(m_pKalahGame.getHoleVal(i))"}
	}

	func forceUpdate()
	{
		CATransaction.flush()
	}

	func drawHole(_ idx: Int, holeStones value: Int, holeColor idxColor: Int)
	{
		Utils.isUIThread()
		if value != -1
		{
			self.holes[idx].text = "\(value)"
		}
		else
		{
			self.holes[idx].text = " "
		}
		if value != -1
		{
			self.holes[idx].textColor = self.clr[idxColor]
		}
		self.forceUpdate()
	}

	func saveFormatValue(_ idx: Int)
	{
		savedVal = idx
	}

	func saveWiner(_ isComp: Bool)
	{
		winer = isComp
	}

	func showStatus(_ idx: Int)
	{
		if idx < 3
		{
			statusLine.text = strNS[idx]
		}
		else
		{
			var pStrNS: String = ""
			switch idx
			{
				case 3, 4:
				pStrNS = String(format: strNS[idx], savedVal) 
				case 5:
				if Locale.current.languageCode == "ru"
				{
					pStrNS = String(format:winer ? "WinComp".localized : "WinYou".localized,savedVal,Utils.getStonesStringRu(savedVal))
				}
				else
				{
					pStrNS = String(format: strNS[idx], (winer ? stxtComp.text : stxtYou.text)!, savedVal)
				}
				default:
				pStrNS = ""
			}

			statusLine.text = pStrNS
		}
		self.forceUpdate()
	}

	@objc func showTech()
	{
		if m_bShowTimedTechLine
		{
			for i in 0..<2
			{
				tech[i].text = m_pKalahGame.getStatusLine(i)
			}
		}
	}

	func showEngineEstimates(_ evalMove:ArrayN<EvalMoves>?)
	{
		for i in 0..<6
		{
			estimates[i].text = ""
		}
		if evalMove != nil
		{
			for i in 0..<evalMove!.size()
			{
				let intVal:Int = Int(evalMove![i].eval)
				estimates[evalMove![i].movesRepeat[0]].text = "\(-intVal)"
				//estimates[evalMove![i].movesRepeat[0]].text = String(format:"%4.1f",-evalMove![i].eval)
			}
		}
	}

	func startTimerOnMainThread()
	{
		self.performSelector(onMainThread:#selector(startTimer),with:nil,waitUntilDone:false)//will no updating if run on current thread
	}

	@objc func startTimer()
	{
		m_Timer = Timer.scheduledTimer(timeInterval: 1.0, target: self, selector: #selector(self.showTech), userInfo: nil, repeats: true)
	}

	func stopTimer()
	{
		m_Timer.invalidate()
		m_Timer = nil
	}

	func setTimerShowTechLine(_ bShow: Bool)
	{
		m_bShowTimedTechLine = bShow
	}

	func callUserMoved()
	{
		m_pKalahGame.userMoved(idxUserMoved)
	}

	override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?)
	{
		let numTaps = touches.first!.tapCount
		if numTaps != 1
		{
			return
		}
		for touch: UITouch in touches
		{
			var pt = touch.location(in:gameView)
			#if _DEBUG
			m_layer.m_rect = CGRectMake(pt.x, pt.y, 2, 2)
			m_layer.setNeedsDisplay()
			#endif
			for i in 0..<6
			{
				if rects[i].contains(pt)
				{
					idxUserMoved = i
					callUserMoved()
					return
				}
			}
			for i in 0..<2
			{
				if rects4FirstTurn[i].contains(pt)
				{
					m_bUserFirst = !m_bUserFirst
					stxtFirstTurnVal.text = (m_bUserFirst ? stxtYou.text : stxtComp.text)
					return
				}
			}
			if m_pKalahGame.bTestMode
			{
				for i in 0..<6
				{
					if rectsOpponent[i].contains(pt)
					{
						m_pKalahGame.opponentMoved(i)
						return
					}
				}
			}
		}
	}

	func setHolesColor()
	{
		for i in 0..<14
		{
			holes[i].textColor = clr[0]
		}
	}

	func setStatusLineColor()
	{
		statusLine.textColor = clr[1]
	}

	func setForeColor()
	{
		stxtComp.textColor = clr[2]
		stxtYou.textColor = clr[2]
		stxtFirstTurnHead.textColor = clr[2]
		stxtFirstTurnVal.textColor = clr[2]
		for i in 0..<2
		{
			tech[i].textColor = clr[2]
			techHead[i].textColor = clr[2]
		}
	}

	func loadLocStrings()
	{
		stxtComp.text = "Computer".localized
		stxtYou.text = "You".localized
		stxtFirstTurnHead.text = "FirstTurn".localized
		stxtFirstTurnVal.text = (m_bUserFirst ? stxtYou.text : stxtComp.text)
		stxtPosHead.text = "Pos".localized
		stxtSecsHead.text = "Secs".localized
		btnNewGame.setTitle("NewGame".localized, for: .normal)

		strNS[0] = "YourTurn".localized
		strNS[1] = "Thinking".localized
		strNS[2] = "Draw".localized
		strNS[3] = "WillTurn".localized
		strNS[4] = "TurningFrom".localized
		strNS[5] = "Win".localized
	}

	@objc func gameSaveState(_ sender: AnyObject)
	{
		m_pKalahGame.saveState()
	}
}
