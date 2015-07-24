import UIKit
import WebKit
import Turbolinks

class ViewController: UIViewController, TLVisitable {
    weak var visitableDelegate: TLVisitableDelegate?

    var location: NSURL?
    var viewController: UIViewController { return self }

    // MARK: View Lifecycle

    override func viewDidLoad() {
        super.viewDidLoad()
        
        view.backgroundColor = UIColor.whiteColor()
        installActivityIndicator()
    }

    override func viewWillDisappear(animated: Bool) {
        super.viewWillDisappear(animated)
        visitableDelegate?.visitableViewWillDisappear(self)
    }

    override func viewDidDisappear(animated: Bool) {
        super.viewDidDisappear(animated)
        visitableDelegate?.visitableViewDidDisappear(self)
    }

    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(animated)
        visitableDelegate?.visitableViewWillAppear(self)
    }

    override func viewDidAppear(animated: Bool) {
        super.viewDidAppear(animated)
        visitableDelegate?.visitableViewDidAppear(self)
    }

    // MARK: Visitable Lifecycle

    func didBecomeInteractive() {
        title = webView?.title
    }

    // MARK: Web View

    var webView: WKWebView?

    func activateWebView(webView: WKWebView) {
        self.webView = webView

        view.addSubview(webView)
        view.addConstraints(NSLayoutConstraint.constraintsWithVisualFormat("H:|[view]|", options: nil, metrics: nil, views: [ "view": webView ]))
        view.addConstraints(NSLayoutConstraint.constraintsWithVisualFormat("V:|[view]|", options: nil, metrics: nil, views: [ "view": webView ]))
        view.sendSubviewToBack(webView)

        updateWebViewScrollViewInsets()
        installRefreshControl()
    }

    func deactivateWebView() {
        removeRefreshControl()
        webView?.removeFromSuperview()
        webView = nil
    }
    
    override func traitCollectionDidChange(previousTraitCollection: UITraitCollection?) {
        super.traitCollectionDidChange(previousTraitCollection)
        updateWebViewScrollViewInsets()
    }

    private func updateWebViewScrollViewInsets() {
        let insets = UIEdgeInsets(top: topLayoutGuide.length, left: 0, bottom: bottomLayoutGuide.length, right: 0)
        webView?.scrollView.scrollIndicatorInsets = insets
        webView?.scrollView.contentInset = insets
    }
    
    // MARK: Activity Indicator

    lazy var activityIndicator: UIActivityIndicatorView = {
        let activityIndicator = UIActivityIndicatorView(activityIndicatorStyle: .WhiteLarge)
        activityIndicator.setTranslatesAutoresizingMaskIntoConstraints(false)
        activityIndicator.color = UIColor.grayColor()
        return activityIndicator
    }()

    private func installActivityIndicator() {
        view.addSubview(activityIndicator)
        view.addConstraint(NSLayoutConstraint(item: activityIndicator, attribute: .CenterX, relatedBy: .Equal, toItem: view, attribute: .CenterX, multiplier: 1, constant: 0))
        view.addConstraint(NSLayoutConstraint(item: activityIndicator, attribute: .CenterY, relatedBy: .Equal, toItem: view, attribute: .CenterY, multiplier: 1, constant: 0))
    }

    func showActivityIndicator() {
        if !refreshing {
            activityIndicator.startAnimating()
            view.bringSubviewToFront(activityIndicator)
        }
    }

    func hideActivityIndicator() {
        activityIndicator.stopAnimating()
    }

    // MARK: Screenshots

    private lazy var screenshotView: UIView = {
        let screenshotView = UIView(frame: CGRectZero)
        screenshotView.setTranslatesAutoresizingMaskIntoConstraints(false)
        screenshotView.backgroundColor = UIColor.whiteColor()
        return screenshotView
    }()
    
    private var screenshotVisible: Bool {
        return screenshotView.superview == view
    }

    func updateScreenshot() {
        if !screenshotVisible {
            self.screenshotView = view.snapshotViewAfterScreenUpdates(false)
        }
    }

    func showScreenshot() {
        if !screenshotVisible && !refreshing {
            view.addSubview(screenshotView)
            view.addConstraints(NSLayoutConstraint.constraintsWithVisualFormat("H:|[view]|", options: nil, metrics: nil, views: [ "view": screenshotView ]))
            view.addConstraints(NSLayoutConstraint.constraintsWithVisualFormat("V:|[view]|", options: nil, metrics: nil, views: [ "view": screenshotView ]))
        }
    }

    func hideScreenshot() {
        after(50) {
            self.screenshotView.removeFromSuperview()
        }
    }

    // MARK: Pull to Refresh

    lazy var refreshControl: UIRefreshControl = {
        let refreshControl = UIRefreshControl()
        refreshControl.addTarget(self, action: "requestRefresh", forControlEvents: .ValueChanged)
        refreshControl.setTranslatesAutoresizingMaskIntoConstraints(false)
        return refreshControl
    }()

    var refreshing: Bool {
        return refreshControl.refreshing
    }

    private func installRefreshControl() {
        webView?.scrollView.addSubview(refreshControl)
    }

    func removeRefreshControl() {
        refreshControl.endRefreshing()
        refreshControl.removeFromSuperview()
    }

    func requestRefresh() {
        visitableDelegate?.visitableDidRequestRefresh(self)
    }

    func willRefresh() {
        refreshControl.beginRefreshing()
    }

    func didRefresh() {
        after(50) {
            self.refreshControl.endRefreshing()
        }
    }
}

func after(msec: Int, callback: () -> ()) {
    let time = dispatch_time(DISPATCH_TIME_NOW, (Int64)(100 * NSEC_PER_MSEC))
    dispatch_after(time, dispatch_get_main_queue(), callback)
}
