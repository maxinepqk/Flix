//
//  SuperheroViewController.swift
//  Flix
//
//  Created by Maxine Kwan on 6/22/17.
//  Copyright © 2017 Maxine Kwan. All rights reserved.
//

import UIKit
import AFNetworking

class SuperheroViewController: UIViewController, UICollectionViewDataSource, UICollectionViewDelegate, UISearchBarDelegate {

    @IBOutlet weak var searchBar: UISearchBar!
    @IBOutlet weak var activityIndicator: UIActivityIndicatorView!
    @IBOutlet weak var collectionView: UICollectionView!
    var refreshControl: UIRefreshControl!
    var movies: [[String: Any]] = []
    var networkAlertController: UIAlertController!
    var filteredMovies: [[String: Any]] = []
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        networkAlertController = UIAlertController(title: "Cannot Get Movies", message: "The Internet connection appears to be offline", preferredStyle: .alert)
        // create an try again action
        let tryAgainAction = UIAlertAction(title: "Try Again", style: .default) { (action) in
            self.newNetworkRequest()
        }
        // add the try again action to the alert controller
        networkAlertController.addAction(tryAgainAction)
        
        collectionView.dataSource = self
        collectionView.delegate = self
        searchBar.delegate = self
        
        // Start the activity indicator
        activityIndicator.startAnimating()
        
        // Initialize a UIRefreshControl
        refreshControl = UIRefreshControl()
        refreshControl.addTarget(self, action: #selector(refreshControlAction(_:)), for: UIControlEvents.valueChanged)
        collectionView.insertSubview(refreshControl, at: 0)
        
        newNetworkRequest()

        // Do any additional setup after loading the view.
    }
    
    func newNetworkRequest() {
        // Configure session so that completion handler is executed on main UI thread
        let url = URL(string: "https://api.themoviedb.org/3/movie/now_playing?api_key=a07e22bc18f5cb106bfe4cc1f83ad8ed")!
        let request = URLRequest(url: url, cachePolicy: .reloadIgnoringLocalCacheData, timeoutInterval: 10)
        let session = URLSession(configuration: .default, delegate: nil, delegateQueue: OperationQueue.main)
        let task = session.dataTask(with: request) { (data, response, error) in
            // This will run when the network request returns
            if let error = error {
                // Network Alert Controller
                self.present(self.networkAlertController, animated: true)
                print(error.localizedDescription)
            } else if let data = data {
                let dataDictionary = try! JSONSerialization.jsonObject(with: data, options: []) as! [String: Any]
                let movies = dataDictionary["results"] as! [[String:Any]]
                let filteredMovies = dataDictionary["results"] as! [[String:Any]]
                self.movies = movies
                self.filteredMovies = filteredMovies
                self.collectionView.reloadData()
                self.refreshControl.endRefreshing()
            }
            self.activityIndicator.stopAnimating()
        }
        task.resume()
        
    }
    
    // Makes a network request to get updated data
    // Updates the tableView with the new data
    // Hides the RefreshControl
    func refreshControlAction(_ refreshControl: UIRefreshControl) {
        newNetworkRequest()
    }
    
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
         return filteredMovies.count
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "SuperheroCell", for: indexPath) as! SuperheroCell
        let movie = filteredMovies[indexPath.item]

        if let posterPathString = movie["poster_path"] as? String {
            let baseURLString = "https://image.tmdb.org/t/p/w500"
            let posterURL = URL(string: baseURLString + posterPathString)!
            //cell.superheroImageView.af_setImage(withURL: posterURL)

            let imageRequest = URLRequest(url: posterURL)
            cell.superheroImageView.setImageWith(
                imageRequest,
                placeholderImage: nil,
                success: { (imageRequest, imageResponse, image) -> Void in
                    
                    // imageResponse will be nil if the image is cached
                    if imageResponse != nil {
                        print("Image was NOT cached, fade in image")
                        cell.superheroImageView.alpha = 0.0
                        cell.superheroImageView.image = image
                        UIView.animate(withDuration: 0.3, animations: { () -> Void in
                            cell.superheroImageView.alpha = 1.0
                        })
                    } else {
                        print("Image was cached so just update the image")
                        cell.superheroImageView.image = image
                    }
            },
                failure: { (imageRequest, imageResponse, error) -> Void in
                    // do something for the failure condition
            })
        }
        return cell
    }
    
    func searchBar(_ searchBar: UISearchBar, textDidChange searchText: String) {
        filteredMovies = searchText.isEmpty ? movies : movies.filter {
            (item: [String: Any]) -> Bool in
            // If dataItem matches the searchText, return true to include it
            return (item["title"] as! String).range(of: searchText, options: .caseInsensitive, range: nil, locale: nil) != nil
        }
        collectionView.reloadData()
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        let cell = sender as! UICollectionViewCell
        if let indexPath = collectionView.indexPath(for: cell) {
            let movie = filteredMovies[indexPath.row]
            let detailViewController = segue.destination as! DetailViewController
            detailViewController.movie = movie
        }
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    

}
