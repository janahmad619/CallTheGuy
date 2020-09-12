//
//  RejectedJobsViewController.swift
//  Call The Guy
//
//  Created by JanAhmad on 31/12/2019.
//  Copyright © 2019 jinnbyte. All rights reserved.
//

import UIKit

class RejectedJobsViewController: UIViewController,UITableViewDataSource, UITableViewDelegate {
    lazy var  refresher:UIRefreshControl = {
        let refresh = UIRefreshControl()
        refresh.addTarget(self, action: #selector(reloadApi), for: .valueChanged)
        return refresh
    }()
    var userId = Constants.userId
    var jobDetails = [jobs]()
    var jobStatusId = 5
    var emptyView: EmptyView?
    var navController: UINavigationController?
    @IBOutlet weak var rejectedJobsTableView: UITableView!
    @IBOutlet weak var activityIndicator: UIActivityIndicatorView!
    override func viewDidLoad() {
        super.viewDidLoad()
        rejectedJobsTableView.delegate = self
         rejectedJobsTableView.refreshControl = refresher
        emptyView = UINib(nibName: "NoDataView", bundle: .main).instantiate(withOwner: nil, options: nil).first as! EmptyView
        rejectedJobsTableView.frame = self.view.bounds
        let param:[String:Any] = ["userId":userId,"JobStatusId": jobStatusId]
        
        if Reachability.isConnectedToNetwork(){
            activityIndicator.startAnimating()
            if (Constants.userTypeId == 3){
                APIRequest.GetJobs(parameters: param, completion: APIRequestCompleted)
            }
            else{
                APIRequest.GetContractorJobs(parameters: param, completion: APIRequestCompleted)
            }
        }
        else {
            print("Internet connection not available")
            
            Constants.Alert(title: "NO Internet Connection", message: "Please make sure You are connected to internet", controller: self)
        }
    }
    override func viewWillAppear(_ animated: Bool) {
        rejectedJobsTableView.reloadData()
    }
    @objc func reloadApi(){
        print("helloWorld")
        let deadline = DispatchTime.now() + .milliseconds(1000)
        DispatchQueue.main.asyncAfter(deadline: deadline){
             let param:[String:Any] = ["userId":self.userId,"JobStatusId": self.jobStatusId]
            if Reachability.isConnectedToNetwork(){
                self.activityIndicator.startAnimating()
                if (Constants.userTypeId == 3){
                    APIRequest.GetJobs(parameters: param, completion: self.APIRequestCompleted)
                }
                else{
                    APIRequest.GetContractorJobs(parameters: param, completion: self.APIRequestCompleted)
                }
            }
            else {
                print("Internet connection not available")
                
                Constants.Alert(title: "NO Internet Connection", message: "Please make sure You are connected to internet", controller: self)
            }
            self.refresher.endRefreshing()
        }
    }
    public func APIRequestCompleted(response:Any?,error:Error?){
        
        if APIResponse.isValidResponse(viewController: self, response: response, error: error){
            
            let decoder = JSONDecoder()
            do {
                
                let data = try JSONSerialization.data(withJSONObject: response, options: .prettyPrinted)
                
                print(data,"PRinting the data here.")
                
                let jobs = try decoder.decode(JobsModel.self, from: data)
                jobDetails = jobs.Jobs
                if (jobDetails.count == 0){
                    rejectedJobsTableView.backgroundView = emptyView
                    rejectedJobsTableView.separatorColor = .clear
                    activityIndicator.stopAnimating()
                }
                else{
                    activityIndicator.stopAnimating()
                    rejectedJobsTableView.reloadData()
                }
            }
            catch {
                
                print("error trying to convert data to JSON")
                Constants.Alert(title: "Error", message: "Hello", controller: self)
            }
        }
        else{
            Constants.Alert(title: "Error", message: "Error", controller: self)
        }
    }
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return 210
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return jobDetails.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "RejectedJobsCell") as! RejectedJobsTableViewCell
        cell.jobDetails = jobDetails[indexPath.row]
        cell.configureCell()
        cell.delegate = self
        return cell
    }

}
extension RejectedJobsViewController: jobDetailsDelegate{
    func onAvailableContractors(jobDetail: jobs) {
        print ("no protocol function")
    }
    
    func onJobDetailButtonPressed(jobDetail: jobs) {
        let vc = UIStoryboard.init(name: "Main", bundle: Bundle.main).instantiateViewController(withIdentifier: "JobDetails") as? CompletedJobDetailsViewController
        if let navigationController = self.navController,
            let viewController = vc {
            viewController.jobDetail = jobDetail
            navigationController.pushViewController(viewController, animated: true)
        }
    }
}