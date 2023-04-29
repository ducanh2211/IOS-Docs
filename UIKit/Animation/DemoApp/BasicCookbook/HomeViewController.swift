/// Copyright (c) 2019 Razeware LLC
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

// MARK: - UIViewController

class HomeViewController: UITableViewController {
  let animator = PopAnimator()
  
  override var prefersStatusBarHidden: Bool {
    return true
  }
}

// MARK: - UITableViewDataSource & UITableViewDelegate

extension HomeViewController {
  override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
    return Recipe.all().count
  }
  
  override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
    let cell = tableView.dequeueReusableCell(
      withIdentifier: "RecipeTableViewCell",
      for: indexPath
    ) as! RecipeTableViewCell
    
    cell.recipe = Recipe.all()[indexPath.row]
    
    return cell
  }
  
  override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
    performSegue(withIdentifier: "showDetails", sender: Recipe.all()[indexPath.row])
  }
}

// MARK: - Prepare for Segue

extension HomeViewController {
  override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
    if let detailsViewController = segue.destination as? DetailsViewController,
       let recipe = sender as? Recipe {
      detailsViewController.transitioningDelegate = self
      detailsViewController.recipe = recipe
      
    }
  }
}

extension HomeViewController: UIViewControllerTransitioningDelegate {
  
  func animationController(forPresented presented: UIViewController,
                           presenting: UIViewController,
                           source: UIViewController) -> UIViewControllerAnimatedTransitioning? {
    
    guard let selectedIndexPathCell = tableView.indexPathForSelectedRow,
          let selectedCell = tableView.cellForRow(at: selectedIndexPathCell) as? RecipeTableViewCell
    else { return nil }
    
    let convertedFrame = selectedCell.convert(selectedCell.bounds, to: nil)
    let originFrame = CGRect(
      x: convertedFrame.origin.x + 20,
      y: convertedFrame.origin.y + 20,
      width: convertedFrame.size.width - 40,
      height: convertedFrame.size.height - 40
    )
    
    animator.originFrame = originFrame
    animator.isPresenting = true
    return animator
  }
  
  func animationController(forDismissed dismissed: UIViewController) -> UIViewControllerAnimatedTransitioning? {
    animator.isPresenting = false
    return animator
  }
  
}
