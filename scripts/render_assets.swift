// Copyright 2026 MiaoShou contributors. GNU GPLv3.
// Explanatory diagram only: no screen capture, UI automation or app interaction.
import AppKit
import ImageIO
import UniformTypeIdentifiers
let output=CommandLine.arguments.count > 1 ? CommandLine.arguments[1] : "assets"
let author=CommandLine.arguments.count > 2 ? CommandLine.arguments[2] : "MiaoShou contributors"
try FileManager.default.createDirectory(atPath: output, withIntermediateDirectories: true)
func color(_ rgb:Int)->NSColor {NSColor(calibratedRed:CGFloat((rgb>>16)&255)/255,green:CGFloat((rgb>>8)&255)/255,blue:CGFloat(rgb&255)/255,alpha:1)}
func rect(_ r:NSRect,_ fill:Int,_ radius:CGFloat=0){color(fill).setFill();NSBezierPath(roundedRect:r,xRadius:radius,yRadius:radius).fill()}
func label(_ text:String,_ x:CGFloat,_ y:CGFloat,_ size:CGFloat,_ fill:Int=0xf2f4f6,_ weight:NSFont.Weight = .regular){
 (text as NSString).draw(at:NSPoint(x:x,y:y),withAttributes:[.font:NSFont.systemFont(ofSize:size,weight:weight),.foregroundColor:color(fill)])
}
func icon(_ letter:String,_ x:CGFloat,_ y:CGFloat,_ tint:Int,_ size:CGFloat=42){
 rect(NSRect(x:x,y:y,width:size,height:size),tint,11)
 label(letter,x+size*0.28,y+size*0.18,size*0.52,0xffffff,.semibold)
}
func ease(_ x:Double)->Double {let x=min(1,max(0,x));return x*x*(3-2*x)}
func frame(_ t:Double,width:Int=960,height:Int=540)->CGImage {
 let rep=NSBitmapImageRep(bitmapDataPlanes:nil,pixelsWide:width,pixelsHigh:height,bitsPerSample:8,samplesPerPixel:4,hasAlpha:true,isPlanar:false,colorSpaceName:.deviceRGB,bytesPerRow:0,bitsPerPixel:0)!
 NSGraphicsContext.saveGraphicsState();let ctx=NSGraphicsContext(bitmapImageRep:rep)!;NSGraphicsContext.current=ctx
 ctx.cgContext.scaleBy(x:CGFloat(width)/960,y:CGFloat(height)/540)
 rect(NSRect(x:0,y:0,width:960,height:540),0x11161c)
 rect(NSRect(x:520,y:22,width:416,height:496),0x1b232b,24)
 if let appIcon=NSImage(contentsOfFile:output+"/app-icon.png") {
  appIcon.draw(in:NSRect(x:38,y:402,width:90,height:90))
 }
 label("秒收",142,430,44,0xf3f6f8,.semibold)
 label("MiaoShou",144,391,22,0x8fa4b6,.medium)
 label("不常用的图标，",44,290,26,0xd0dbe2,.medium)
 label("收进一个小框。",44,250,26,0xd0dbe2,.medium)
 label("整理  →  放回 / 收进",44,174,18,0x9dadbc)
 label("基于 Thaw · macOS 26",44,66,16,0x8c9ba9)
 label("操作示意 · 非屏幕录制",44,37,13,0x8493a1)
 rect(NSRect(x:540,y:468,width:376,height:32),0x303941,9)
 label("顶栏",554,475,13,0xc4ced6)
 label("⌃",872,471,23,0xe9eef2,.medium)
 rect(NSRect(x:548,y:44,width:360,height:406),0x272e36,18)
 label("秒收",568,415,18,0xf2f4f6,.semibold)
 label("完成",852,416,14,0x91c8bd)
 label("已收纳",568,377,13,0xacbac6)
 rect(NSRect(x:565,y:262,width:326,height:105),0x303943,11)
 icon("B",692,312,0x5e7391);icon("C",794,312,0x916d55)
 label("测试 B",693,284,12,0xccd5dc);label("测试 C",795,284,12,0xccd5dc)
 label("顶栏",568,231,13,0xacbac6)
 rect(NSRect(x:565,y:113,width:326,height:106),0x303943,11)
 let phase:Double
 if t<1 {phase=0} else if t<1.7 {phase=ease((t-1)/0.7)} else if t<3.7 {phase=1} else if t<4.4 {phase=1-ease((t-3.7)/0.7)} else {phase=0}
 let y:CGFloat=312-CGFloat(phase)*147
 icon("A",590,y,0x508d81)
 label("测试 A",591,y-28,12,0xccd5dc)
 if phase>0.98 {icon("A",816,472,0x508d81,24)}
 if t>1 && t<1.7 || t>3.7 && t<4.4 {
  color(0xffffff).setFill();let p=NSBezierPath();p.move(to:NSPoint(x:616,y:y+6));p.line(to:NSPoint(x:616,y:y-14));p.line(to:NSPoint(x:622,y:y-9));p.line(to:NSPoint(x:628,y:y-10));p.close();p.fill()
 }
 let status=phase>0.98 ? "A 已放回顶栏，B、C 仍在收纳盒" : phase<0.02 ? "A、B、C 已收纳" : "只移动选中的 A"
 label(status,569,73,12,0xb6c7ce)
 NSGraphicsContext.restoreGraphicsState();return rep.cgImage!
}
let gifURL=URL(fileURLWithPath:output).appendingPathComponent("demo.gif")
let destination=CGImageDestinationCreateWithURL(gifURL as CFURL,UTType.gif.identifier as CFString,72,nil)!
CGImageDestinationSetProperties(destination,[kCGImagePropertyGIFDictionary:[kCGImagePropertyGIFLoopCount:0]] as CFDictionary)
for index in 0..<72 {CGImageDestinationAddImage(destination,frame(Double(index)/12),[kCGImagePropertyGIFDictionary:[kCGImagePropertyGIFDelayTime:1.0/12.0]] as CFDictionary)}
guard CGImageDestinationFinalize(destination) else {fatalError("GIF write failed")}
for (name,w,h) in [("preview.png",960,540),("social-preview.png",1280,640)]{
 let url=URL(fileURLWithPath:output).appendingPathComponent(name)
 let target=CGImageDestinationCreateWithURL(url as CFURL,UTType.png.identifier as CFString,1,nil)!
 CGImageDestinationAddImage(target,frame(2.4,width:w,height:h),[kCGImagePropertyPNGDictionary:["Author":author,"Copyright":"© 2026 \(author)","Description":"MiaoShou interaction illustration; not a screen recording"]] as CFDictionary)
 guard CGImageDestinationFinalize(target) else {fatalError("PNG write failed")}
}
print("Generated fictional interaction diagram and preview images")
