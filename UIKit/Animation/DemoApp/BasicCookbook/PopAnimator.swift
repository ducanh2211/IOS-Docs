/// Copyright (c) 2023 Razeware LLC
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
/// THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
/// IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
/// FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
/// AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
/// LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
/// OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
/// THE SOFTWARE.

import UIKit

class PopAnimator: NSObject, UIViewControllerAnimatedTransitioning {
  
  let duration: TimeInterval = 1.5
  var isPresenting = true
  var originFrame = CGRect.zero

  
  func transitionDuration(using transitionContext: UIViewControllerContextTransitioning?) -> TimeInterval {
    return duration
  }
  
  func animateTransition(using transitionContext: UIViewControllerContextTransitioning) {
    
    // set up
    let containerView = transitionContext.containerView
    let toView = transitionContext.view(forKey: .to)!
    let fromView = transitionContext.view(forKey: .from)!
    let transitionedView = isPresenting ? toView : fromView
    
    let snapshotView = isPresenting ?
      transitionedView.snapshotView(afterScreenUpdates: true)! :
      transitionedView.snapshotView(afterScreenUpdates: false)!
    
    // calculation
    let initialFrame = isPresenting ? originFrame : transitionedView.frame
    let finalFrame = isPresenting ? transitionedView.frame : originFrame

    let xScaleFactor = isPresenting ?
      initialFrame.width / finalFrame.width :
      finalFrame.width / initialFrame.width

    let yScaleFactor = isPresenting ?
      initialFrame.height / finalFrame.height :
      finalFrame.height / initialFrame.height
    
    let scaleTransform = CGAffineTransform(scaleX: xScaleFactor, y: yScaleFactor)
    print(scaleTransform)

    if isPresenting {
      snapshotView.transform = scaleTransform
      print(scaleTransform)
      snapshotView.center = CGPoint(x: initialFrame.midX, y: initialFrame.midY)
      snapshotView.clipsToBounds = true
    }
    print(snapshotView.frame)
    snapshotView.layer.cornerRadius = 20
    snapshotView.layer.masksToBounds = true
    
    transitionedView.alpha = 0
    
    containerView.addSubview(toView)
    containerView.addSubview(snapshotView)
    
    
    UIView.animate(withDuration: duration, delay: 0, animations: {
      snapshotView.transform = self.isPresenting ? .identity : scaleTransform
      snapshotView.center = CGPoint(x: finalFrame.midX, y: finalFrame.midY)
      snapshotView.layer.cornerRadius = !self.isPresenting ? 20.0 : 0.0
    }, completion: { _ in
      transitionedView.alpha = 1
      snapshotView.removeFromSuperview()
      transitionContext.completeTransition(true)
    })
  }
  

}
