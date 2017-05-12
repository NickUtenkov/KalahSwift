//
//  Utils.swift
//  Kalah
//
//  Created by nick on 07/10/16.
//  Copyright © 2016 nick. All rights reserved.
//

import Foundation
import UIKit

public enum logLevel: String
{
	case info = "❓"
	case debug = "✳️"
	case warn = "⚠️"
	case error = "🚫"
	case fatal = "🆘"
}

final class Utils
{
	static let nanoDiv:Double = 1000000000.0
	static var nanoCoef:Double =
	{
		var data = mach_timebase_info()
		mach_timebase_info(&data)
		return (Double(data.numer)) / (Double(data.denom))
	}()

	@inline(__always) static func getSecondsSince(_ timeSince:UInt64) -> Double
	{
		return (nanoCoef * Double(mach_absolute_time()) - Double(timeSince))/nanoDiv
	}

	@inline(__always) static func getSeconds(_ deltaTime:UInt64) -> Double
	{
		return (nanoCoef * Double(deltaTime))/nanoDiv
	}

	static func prefsSet(_ val:Any,_ key:String)
	{
		let defaults = UserDefaults.standard
		defaults.set(val,forKey: key)
		defaults.synchronize()
	}
	
	static func prefsGetString(_ key:String) -> String?
	{
		return UserDefaults.standard.string(forKey:key)
	}
	
	static func prefsGetInteger(_ key:String) -> Int
	{
		return UserDefaults.standard.integer(forKey:key)
	}
	
	static func prefsGetBool(_ key:String) -> Bool
	{
		return UserDefaults.standard.bool(forKey:key)
	}
	
	static func prefsGetFloat(_ key:String) -> Float
	{
		return UserDefaults.standard.float(forKey:key)
	}

	static func prefsGetColor(_ idxColor:Int) -> UIColor
	{
		let compRed = CGFloat(prefsGetInteger("Color\(idxColor)_0"))
		let compGreen = CGFloat(prefsGetInteger("Color\(idxColor)_1"))
		let compBlue = CGFloat(prefsGetInteger("Color\(idxColor)_2"))
		let compAlpha = CGFloat(prefsGetInteger("Color\(idxColor)_3"))
		return UIColor(red:compRed/255, green:compGreen/255, blue:compBlue/255, alpha:compAlpha/255)
	}
	
	static func GetDocDir() -> String
	{
		return NSSearchPathForDirectoriesInDomains(.documentDirectory, .userDomainMask, true)[0]
	}

	static func prefsInit()
	{
		var str:String? = nil

		str = prefsGetString("Level")
		if str == nil {prefsSet(2,"Level")}

		str = prefsGetString("ShowTech")
		if str == nil {prefsSet(true,"ShowTech")}

		str = prefsGetString("Animate")
		if str == nil {prefsSet(2,"Animate")}

		str = prefsGetString("AnimateBest")
		if str == nil {prefsSet(true,"AnimateBest")}

		str = prefsGetString("UseSounds")
		if str == nil {prefsSet(true,"UseSounds")}
		let arColors:Array<(r:Int,g:Int,b:Int,a:Int)> =
		[
			(64,64,64,255),
			(255,255,255,255),
			(0,0,0,255),
			(0,160,0,255),
			(237,0,0,255),
			(0,178,0,255),
			(0,0,178,255),
			(255,255,0,255),
		]
		var idx = 0
		for (r,g,b,a) in arColors
		{
			str = prefsGetString("Color\(idx)_0")
			if str == nil {prefsSet(r,"Color\(idx)_0")}

			str = prefsGetString("Color\(idx)_1")
			if str == nil {prefsSet(g,"Color\(idx)_1")}

			str = prefsGetString("Color\(idx)_2")
			if str == nil {prefsSet(b,"Color\(idx)_2")}

			str = prefsGetString("Color\(idx)_3")
			if str == nil {prefsSet(a,"Color\(idx)_3")}

			idx += 1
		}
	}

	static func isUIThread(filename: String = #file, line: Int = #line, funcname: String = #function)
	{
		if !Thread.isMainThread
		{
			print("not UIthread \(funcname) \(line)")
		}//\(filename) 
	}
	
	static func runOnUI(_ block:@escaping () -> Swift.Void)
	{
		if Thread.current.isMainThread {block()}
		else {DispatchQueue.main.async(execute: block)}
	}

	static func countCPU() -> Int
	{
		return ProcessInfo().processorCount
	}

	static func getStonesStringRu(_ cStones:Int) -> String
	{
		let arStr = ["Stone0".localized,"Stone1".localized]
		var idx = 0
		if !(cStones > 10 && cStones < 20)
		{
			let ostatok = cStones % 10
			if ((ostatok == 2) || (ostatok == 4)) {idx = 1}
		}
		return arStr[idx]
	}
}
