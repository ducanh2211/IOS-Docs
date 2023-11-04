/// Copyright (c) 2020 Razeware LLC
///
/// Permission is hereby granted, free of charge, to any person obtaining a copy
/// of this software and associated documentation files (the "Software"), to deal
/// in the Software without restriction, including without limitation the rights
/// to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
/// copies of the Software, and to permit persons to whom the Software is
/// furnished to do so, subject to the following conditions:
///
/// The above copyright notice and this permission notice shall be included in
/// all copies or substantial portions of the Software.
///
/// Notwithstanding the foregoing, you may not use, copy, modify, merge, publish,
/// distribute, sublicense, create a derivative work, and/or sell copies of the
/// Software in any work that is designed, intended, or marketed for pedagogical or
/// instructional purposes related to programming, coding, application development,
/// or information technology.  Permission for such use, copying, modification,
/// merger, publication, distribution, sublicensing, creation of derivative works,
/// or sale is expressly withheld.
///
/// This project and source code may use libraries or frameworks that are
/// released under various Open-Source licenses. Use of those libraries and
/// frameworks are governed by their own individual licenses.
///
/// THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
/// IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
/// FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
/// AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
/// LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
/// OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
/// THE SOFTWARE.

import UIKit

@IBDesignable class CounterView: UIView {
  private struct Constants {
    static let numberOfGlasses = 8
    static let lineWidth: CGFloat = 5.0
    static let arcWidth: CGFloat = 76
    
    static var halfOfLineWidth: CGFloat {
      return lineWidth / 2
    }
  }
  
  @IBInspectable var counter: Int = 5 {
    didSet {
      if counter <=  Constants.numberOfGlasses {
        //the view needs to be refreshed
        setNeedsDisplay()
      }
    }
  }
  @IBInspectable var outlineColor: UIColor = UIColor.blue
  @IBInspectable var counterColor: UIColor = UIColor.orange
  
  override func draw(_ rect: CGRect) {
    // 1
    let center = CGPoint(x: bounds.width / 2, y: bounds.height / 2)
    
    // 2
    let radius = max(bounds.width, bounds.height)
    
    // 3
    let startAngle: CGFloat = 3 * .pi / 4
    let endAngle: CGFloat = .pi / 4
    
    // 4
    let path = UIBezierPath(
      arcCenter: center,
      radius: radius/2 - Constants.arcWidth/2,
      startAngle: startAngle,
      endAngle: endAngle,
      clockwise: true)
    
    // 5
    path.lineWidth = Constants.arcWidth
    counterColor.setStroke()
    path.stroke()
    
    //Draw the outline

    //1 - first calculate the difference between the two angles
    //ensuring it is positive
    let angleDifference: CGFloat = 2 * .pi - startAngle + endAngle
    //then calculate the arc for each single glass
    let arcLengthPerGlass = angleDifference / CGFloat(Constants.numberOfGlasses)
    //then multiply out by the actual glasses drunk
    let outlineEndAngle = arcLengthPerGlass * CGFloat(counter) + startAngle

    //2 - draw the outer arc
    let outerArcRadius = bounds.width/2 - Constants.halfOfLineWidth
    let outlinePath = UIBezierPath(
      arcCenter: center,
      radius: outerArcRadius,
      startAngle: startAngle,
      endAngle: outlineEndAngle,
      clockwise: true)

    //3 - draw the inner arc
    let innerArcRadius = bounds.width/2 - Constants.arcWidth + Constants.halfOfLineWidth
    outlinePath.addArc(
      withCenter: center,
      radius: innerArcRadius,
      startAngle: outlineEndAngle,
      endAngle: startAngle,
      clockwise: false)
        
    //4 - close the path
    outlinePath.close()
        
    outlineColor.setStroke()
    outlinePath.lineWidth = Constants.lineWidth
    outlinePath.stroke()
  }
}
