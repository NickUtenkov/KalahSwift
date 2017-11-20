//
//  Extensions.swift
//  Kalah
//
//  Created by nick on 20/12/16.
//  Copyright © 2016 nick. All rights reserved.
//

import Foundation
import UIKit

extension String
{
	var localized:String
	{
		return NSLocalizedString(self, tableName: "Localizable", bundle: Bundle.main, value: "", comment: "")
	}
	var bool:Bool
	{
		return self.lowercased() == "true" || Int(self) == 1
	}

	func render(_ bounds:CGSize,_ pFont:UIFont,_ clr:UIColor)
	{
		let myString = self as NSString
		let attrs = 
			[NSAttributedStringKey.font: pFont,
			 NSAttributedStringKey.foregroundColor:clr
			]
		let sz: CGSize = myString.size(withAttributes:attrs)
		let pt = CGPoint(x:(bounds.width - sz.width)/2,y:(bounds.height - sz.height)/2)
		myString.draw(at: pt,withAttributes:attrs)
	}

	func cgSize(_ inSize:CGSize,_ fnt:UIFont) -> CGSize
	{
		let str = self as NSString
		let attrs = [NSAttributedStringKey.font:fnt]
		let sz1 = str.boundingRect(
			with:inSize,
			options:[.usesFontLeading, .usesLineFragmentOrigin],
			attributes:attrs,
			context:nil).size
		return sz1
	}

	var length:Int
	{
		//return self.characters.count
		return self.count
	}

	func lengthForWidth(_ inWidth:CGFloat,_ pFont:UIFont) -> Int
	{//http://nsscreencast.com/episodes/209-cool-text-effects
		let font = CTFontCreateWithName(pFont.fontName as CFString,pFont.pointSize, nil)
		let attrs:[String:AnyObject] = [NSAttributedStringKey.font.rawValue:font]
		let attString = CFAttributedStringCreate(kCFAllocatorDefault,self as CFString,attrs as CFDictionary!)
		
		let path = CGMutablePath()
		let rct = CGRect(x:0,y:0,w:inWidth,h:32002)
		path.addRect(rct )
		let frameSetter = CTFramesetterCreateWithAttributedString(attString!)
		let frame = CTFramesetterCreateFrame(frameSetter,CFRangeMake(0, CFAttributedStringGetLength(attString)), path, nil)
		let arLines = CTFrameGetLines(frame)
		let unmanagedLine:UnsafeRawPointer = CFArrayGetValueAtIndex(arLines, 0)
		let line:CTLine = unsafeBitCast(unmanagedLine, to: CTLine.self)
		let rng = CTLineGetStringRange(line)
		return rng.length
	}
}

extension UIView
{
	func roundCorners(_ rad:CGFloat,_ corners:UIRectCorner)
	{
		let maskPath:UIBezierPath = .init(roundedRect: self.bounds, byRoundingCorners:corners, cornerRadii: CGSize(width:rad,height:rad))
		let maskLayer:CAShapeLayer = .init()
		maskLayer.frame = self.bounds
		maskLayer.path = maskPath.cgPath
		self.layer.mask = maskLayer
		self.layer.masksToBounds = false
	}
	
	func decorate(_ rad:CGFloat,_ wd:CGFloat,_ clr:UIColor?,_ bMaskToBounds:Bool = true)
	{//should NOT call this function again if view bounds changed !
		self.layer.cornerRadius = rad
		self.layer.masksToBounds = bMaskToBounds
		if wd>0
		{
			self.layer.borderWidth = wd
			if clr != nil
			{
				self.layer.borderColor = clr!.cgColor
			}
		}
	}

	func makeGradient(_ bRemoveBackground:Bool,_ clr1:CGColor,_ clr2:CGColor)
	{
		let gradient = CAGradientLayer()
		gradient.name = "MyGradient"

		gradient.frame = bounds
		gradient.colors = [clr1,clr2]

		if let idx = layer.sublayers?.index(where:{$0.name == "MyGradient"})
		{
			layer.replaceSublayer(layer.sublayers![idx],with:gradient)
		}
		else {layer.insertSublayer(gradient,at:0)}

		if bRemoveBackground {backgroundColor = nil}//free memory !
	}

	func makeGradient(_ bRemoveBackground:Bool,_ clr1:CGColor,_ clr2:CGColor,_ clr3:CGColor,_ lineLayerHeight:CGFloat = 1)
	{
		let lineLayer = CALayer()
		lineLayer.name = "MyTopLine"
		lineLayer.frame = CGRect(x:0,y:0,w:bounds.size.width,h:lineLayerHeight)
		lineLayer.backgroundColor = clr3

		if let idx = layer.sublayers?.index(where:{$0.name == "MyTopLine"})
		{
			layer.replaceSublayer(layer.sublayers![idx],with:lineLayer)
		}
		else {layer.insertSublayer(lineLayer,at:0)}

		makeGradient(bRemoveBackground,clr1,clr2)
	}

	func makeGradientGray()
	{
		let clr1 = UIColor(red:0.93,green:0.94,blue:0.95,alpha:1.0)
		let clr2 = UIColor(red:0.64,green:0.65,blue:0.66,alpha:1.0)
		let clr3 = UIColor(red:0.50,green:0.50,blue:0.50,alpha:1.0)
		self.makeGradient(true,clr1.cgColor,clr2.cgColor,clr3.cgColor)
	}

	func removeGradientLayer()
	{
		if let idx = layer.sublayers?.index(where:{$0.name == "MyGradient"})
		{
			layer.sublayers![idx].removeFromSuperlayer()
		}
	}

	func setShadow(_ shadowColor:CGColor?,_ shadowRadius:CGFloat,_ shadowOpacity:Float,_ offsetX:CGFloat,_ offsetY:CGFloat)
	{
		self.layer.shadowColor = shadowColor
		self.layer.shadowRadius = shadowRadius
		self.layer.shadowOpacity = shadowOpacity
		self.layer.shadowOffset = CGSize(w:offsetX,h:offsetY)
		self.layer.masksToBounds = false
		//self.clipsToBounds = false
	}

	func setWidth(_ newWidth:CGFloat)
	{
		var newFrame = frame
		newFrame.size.width = newWidth
		frame = newFrame
	}
	
	func setHeight(_ newHeight:CGFloat)
	{
		var newFrame = frame
		newFrame.size.height = newHeight
		frame = newFrame
	}
	
	func setWidthHeight(_ newWidth:CGFloat,_ newHeight:CGFloat)
	{
		var newFrame = frame
		newFrame.size.width = newWidth
		newFrame.size.height = newHeight
		frame = newFrame
	}

	func setXOrigin(_ newOrigin:CGFloat)
	{
		var newFrame = frame
		newFrame.origin.x = newOrigin
		frame = newFrame
	}

	func setYOrigin(_ newOrigin:CGFloat)
	{
		var newFrame = frame
		newFrame.origin.y = newOrigin
		frame = newFrame
	}
	
	func setOrigin(_ newXOrigin:CGFloat,_ newYOrigin:CGFloat)
	{
		var newFrame = frame
		newFrame.origin.x = newXOrigin
		newFrame.origin.y = newYOrigin
		frame = newFrame
	}

	func bottom() -> CGFloat
	{
		return frame.origin.y+frame.size.height
	}
	
	func right() -> CGFloat
	{
		return frame.origin.x+frame.size.width
	}

	func repositionRelativeToViewWithGapHeight(_ relativeView:UIView,_ deltaHeight:CGFloat)
	{
		var newFrame = self.frame
		newFrame.origin.y = relativeView.bottom() + deltaHeight
		self.frame = newFrame
	}

	func repositionRelativeToViewWithGapWidth(_ relativeView:UIView,_ deltaWidth:CGFloat)
	{
		var newFrame = self.frame
		newFrame.origin.x = relativeView.right() + deltaWidth
		self.frame = newFrame
	}

	func applyGradient(colours: [UIColor]) -> Void
	{
		self.applyGradient(colours:colours, locations: nil)
	}
	
	func applyGradient(colours: [UIColor], locations: [NSNumber]?) -> Void
	{
		let gradient: CAGradientLayer = CAGradientLayer()
		gradient.frame = self.bounds
		gradient.colors = colours.map { $0.cgColor }
		gradient.locations = locations
		self.layer.insertSublayer(gradient, at: 0)
	}

	@IBInspectable var cornerRadius: CGFloat
	{
		set { layer.cornerRadius = newValue  }
		get { return layer.cornerRadius }
	}

	@IBInspectable var borderWidth: CGFloat
	{
		set { layer.borderWidth = newValue }
		get { return layer.borderWidth }
	}

	@IBInspectable var borderColor: UIColor?
	{
		set { layer.borderColor = newValue?.cgColor  }
		get { return layer.borderColor?.UIColor }
	}

	@IBInspectable var shadowOffset: CGSize
	{
		set { layer.shadowOffset = newValue  }
		get { return layer.shadowOffset }
	}

	@IBInspectable var shadowOpacity: Float
	{
		set { layer.shadowOpacity = newValue }
		get { return layer.shadowOpacity }
	}

	@IBInspectable var shadowRadius: CGFloat
	{
		set {  layer.shadowRadius = newValue }
		get { return layer.shadowRadius }
	}

	@IBInspectable var shadowColor: UIColor?
	{
		set { layer.shadowColor = newValue?.cgColor }
		get { return layer.shadowColor?.UIColor }
	}

	@IBInspectable var masksToBounds: Bool
		{
		set { layer.masksToBounds = newValue }
		get { return layer.masksToBounds }
	}

	@IBInspectable var _clipsToBounds: Bool
	{
		set { clipsToBounds = newValue }
		get { return clipsToBounds }
	}
}

extension UIButton
{
	func makeGradient(_ clr1:CGColor,_ clr2:CGColor)
	{
		let scl = UIScreen.main.scale
		let gradient = CAGradientLayer()
		gradient.name = "MyGradient"
		gradient.frame = self.bounds
		if scl > 1
		{
			var newFrame = gradient.frame
			newFrame.size.width *= scl
			newFrame.size.height *= scl
			gradient.frame = newFrame
		}
		gradient.colors = [clr1,clr2]

		if let lblFont = titleLabel?.font
		{
			var pFont = lblFont
			var size = bounds.size
			size.width *= scl
			size.height *= scl
			if scl>1
			{
				if let pFontScaled = UIFont(name:pFont.fontName,size:pFont.pointSize*scl)
				{
					pFont = pFontScaled
				}
			}

			UIGraphicsBeginImageContext(size)
			var ctx = UIGraphicsGetCurrentContext()
			ctx!.interpolationQuality = .high
			gradient.render(in: ctx!)
			currentTitle?.render(size,pFont,titleColor(for: .normal)!)

			var viewImage = UIGraphicsGetImageFromCurrentImageContext()
			setImage(viewImage, for: .normal)
			UIGraphicsEndImageContext()

			gradient.colors = [clr2,clr1]//reverse gradient

			UIGraphicsBeginImageContext(size)
			ctx = UIGraphicsGetCurrentContext()
			ctx!.interpolationQuality = .high
			gradient.render(in: ctx!)
			currentTitle?.render(size,pFont,titleShadowColor(for: .normal)!)
			
			viewImage = UIGraphicsGetImageFromCurrentImageContext()
			setImage(viewImage, for: .highlighted)
			UIGraphicsEndImageContext()
		}

		backgroundColor = nil
	}

	func resize(_ newSize:CGSize)
	{
		if (self.titleLabel?.text?.length)! > 0
		{
			var newFrame = self.frame
			//CGSize sz = getStringSize(label.text,maxSize,label.font,label.lineBreakMode)
			let sz = self.titleLabel!.text!.cgSize(newSize,self.titleLabel!.font)
			newFrame.size.width = sz.width+2*self.layer.cornerRadius
			self.frame = newFrame
		}
	}

	/*@IBInspectable override var cornerRadius: CGFloat
	{
		set { layer.cornerRadius = newValue  }
		get { return layer.cornerRadius }
	}

	@IBInspectable override var borderWidth: CGFloat
	{
		set { layer.borderWidth = newValue }
		get { return layer.borderWidth }
	}

	@IBInspectable override var borderColor: UIColor?
	{
		set { layer.borderColor = newValue?.cgColor  }
		get { return layer.borderColor?.UIColor }
	}*/
}

extension CGColor
{
	var UIColor: UIKit.UIColor
	{
		return UIKit.UIColor(cgColor: self)
	}
}

extension UIImage
{
	func scaleToSize(_ targetSize:CGSize) -> UIImage?
	{
		UIGraphicsBeginImageContext(targetSize)
		draw(in:CGRect(origin:CGPoint.zero,size:targetSize))
		let newImage = UIGraphicsGetImageFromCurrentImageContext()
		UIGraphicsEndImageContext()
		//if(newImage == nil) print("could not scale image")

		return newImage
	}
}

extension UILabel
{
	func setTextResized(_ newText:String?,_ newSize:CGSize) -> CGSize
	{
		var newFrame = self.frame
		var oldSize = self.frame.size
		oldSize.height = newSize.height
		if !(newSize.width<0) {oldSize.width = newSize.width}
		//let sz = getStringSize((newText != nil ? newText : self.text),oldSize,self.font,self.lineBreakMode)
		var str = ""
		if let tmp = newText {str = tmp}
		else {str = self.text!}
		let sz = str.cgSize(oldSize,self.font)
		newFrame.size.height = sz.height
		if !(newSize.width < 0) {newFrame.size.width = sz.width}
		self.frame = newFrame
		if newText != nil {self.text = newText}
		else {self.text = ""}
		
		return newFrame.size
	}

	func resize(_ newSize:CGSize)
	{
		if (self.text?.length)! > 0
		{
			var newFrame = self.frame
			//CGSize sz = getStringSize(label.text,maxSize,label.font,label.lineBreakMode)
			let sz = self.text!.cgSize(newSize,self.font)
			newFrame.size = sz
			self.frame = newFrame
		}
	}
}

extension CGRect
{
	public init(x: CGFloat, y: CGFloat, w: CGFloat, h: CGFloat)
	{
		self.init(x:x, y:y, width:w, height:h)
	}
}

extension CGSize
{
	public init(w:CGFloat,h:CGFloat)
	{
		self.init(width:w,height:h)
	}
}
