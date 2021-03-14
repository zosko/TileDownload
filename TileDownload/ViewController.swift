//
//  ViewController.swift
//  TileDownload
//
//  Created by Bosko Petreski on 3/14/21.
//

import Cocoa
import MapKit

var switchDownloadFlag = false

class ViewController: NSViewController, MKMapViewDelegate {
    
    @IBOutlet var mapPlane : MKMapView!
    @IBOutlet var switchDownload : NSSwitch!
    
    // MARK: - MAPViewDelegate
    func mapView(_ mapView: MKMapView, rendererFor overlay: MKOverlay) -> MKOverlayRenderer {
        if overlay is MKTileOverlay {
            let renderer = MKTileOverlayRenderer(overlay: overlay)
            return renderer
        }
        return MKTileOverlayRenderer()
    }
    
    @IBAction func onSwitchDownload(_ switch : NSSwitch){
        switchDownloadFlag = switchDownload.state == .on
    }
    
    //MARK: - UIViewDelegates
    override func viewDidLoad() {
        super.viewDidLoad()
        
        let overlay = MyTileOverlay(urlTemplate: "http://tile.openstreetmap.org/{z}/{x}/{y}.png")
        overlay.canReplaceMapContent = true
        mapPlane.addOverlay(overlay, level: .aboveLabels)
    }

    override var representedObject: Any? {
        didSet {
        // Update the view, if already loaded.
        }
    }
}

class MyTileOverlay : MKTileOverlay {
    var alpha: CGFloat = 1.0

    override func loadTile(at path: MKTileOverlayPath, result: @escaping (Data?, Error?) -> Void) {
        super.loadTile(at: path, result: result)
        
        if switchDownloadFlag {
            let tileUrl = "https://tile.openstreetmap.org/\(path.z)/\(path.x)/\(path.y).png"
            FileDownloader.downloadTile(url: URL(string: tileUrl)!, path: path, completion: { (path, error) in
                
            })
        }
    }
    
}

class FileDownloader {
    
    static func downloadTile(url: URL, path:MKTileOverlayPath, completion: @escaping (String?, Error?) -> Void){
        let documentsUrl =  FileManager.default.urls(for: .desktopDirectory, in: .userDomainMask).first!
        
        let destinationUrl = documentsUrl.appendingPathComponent("tiles/\(path.z)/\(path.x)/\(path.y).png")

        if FileManager().fileExists(atPath: destinationUrl.path){
            completion(destinationUrl.path, nil)
        }
        else{
            let pathFolder = documentsUrl.appendingPathComponent("tiles/\(path.z)/\(path.x)")
            try! FileManager.default.createDirectory(atPath: pathFolder.path, withIntermediateDirectories: true, attributes: nil)
            
            let session = URLSession(configuration: URLSessionConfiguration.default, delegate: nil, delegateQueue: nil)
            var request = URLRequest(url: url)
            request.httpMethod = "GET"
            let task = session.dataTask(with: request, completionHandler: { data, response, error in
                if error == nil{
                    if let response = response as? HTTPURLResponse{
                        if response.statusCode == 200{
                            if let dataImage = data {
                                FileManager.default.createFile(atPath: destinationUrl.path, contents: dataImage, attributes: nil)
                                completion(destinationUrl.path, error)
                            }
                            else{
                                completion(destinationUrl.path, error)
                            }
                        }
                    }
                }
                else{
                    completion(destinationUrl.path, error)
                }
            })
            task.resume()
        }
    }
}

