//
//  ShowSongsTableViewController.swift
//  TheBestClock
//
//  Created by Chris Marshall on 11/11/18.
//  Copyright © 2018 The Great Rift Valley Software Company. All rights reserved.
//

// Cribbed from here: https://stackoverflow.com/a/43385752/879365

import UIKit
import MediaPlayer
import AVFoundation

class MusicPlayerCell: UITableViewCell {
    @IBOutlet var labelMusicTitle: UILabel!
    @IBOutlet var labelMusicDescription: UILabel!
    @IBOutlet var imageMusic: UIImageView!
}

struct SongInfo {
    
    var albumTitle: String
    var artistName: String
    var songTitle: String
    var songId: NSNumber
}

struct AlbumInfo {
    
    var albumTitle: String
    var songs: [SongInfo]
}

class SongQuery {
    func get(songCategory: String) -> [AlbumInfo] {
        var albums: [AlbumInfo] = []
        let albumsQuery: MPMediaQuery
        if songCategory == "Artist" {
            albumsQuery = MPMediaQuery.artists()
            
        } else if songCategory == "Album" {
            albumsQuery = MPMediaQuery.albums()
            
        } else {
            albumsQuery = MPMediaQuery.albums()
        }
        
        // let albumsQuery: MPMediaQuery = MPMediaQuery.albums()
        let albumItems: [MPMediaItemCollection] = albumsQuery.collections! as [MPMediaItemCollection]
        //  var album: MPMediaItemCollection
        
        for album in albumItems {
            
            let albumItems: [MPMediaItem] = album.items as [MPMediaItem]
            // var song: MPMediaItem
            
            var songs: [SongInfo] = []
            
            var albumTitle: String = ""
            
            for song in albumItems {
                if songCategory == "Artist" {
                    albumTitle = song.value(forProperty: MPMediaItemPropertyArtist) as? String ?? ""
                } else if songCategory == "Album" {
                    albumTitle = song.value(forProperty: MPMediaItemPropertyAlbumTitle) as? String ?? ""
                } else {
                    albumTitle = song.value(forProperty: MPMediaItemPropertyAlbumTitle) as? String ?? ""
                }
                
                let songInfo: SongInfo = SongInfo(
                    albumTitle: song.value(forProperty: MPMediaItemPropertyAlbumTitle) as? String ?? "",
                    artistName: song.value(forProperty: MPMediaItemPropertyArtist) as? String ?? "",
                    songTitle: song.value(forProperty: MPMediaItemPropertyTitle) as? String ?? "",
                    songId: song.value(forProperty: MPMediaItemPropertyPersistentID) as? NSNumber ?? 0
                )
                songs.append( songInfo )
            }
            
            let albumInfo: AlbumInfo = AlbumInfo(
                albumTitle: albumTitle,
                songs: songs
            )
            
            albums.append( albumInfo )
        }
        
        return albums
    }
    
    func getItem( songId: NSNumber ) -> MPMediaItem {
        let property: MPMediaPropertyPredicate = MPMediaPropertyPredicate( value: songId, forProperty: MPMediaItemPropertyPersistentID )
        
        let query: MPMediaQuery = MPMediaQuery()
        query.addFilterPredicate(property)
        
        var items: [MPMediaItem] = query.items! as [MPMediaItem]
        
        return items[items.count - 1]
    }
}

class ViewController: UIViewController, UITableViewDelegate, UITableViewDataSource {
    @IBOutlet var tableView: UITableView?
    let myTableView: UITableView = UITableView(frame: CGRect.zero, style: .grouped)
    
    var albums: [AlbumInfo] = []
    var songQuery: SongQuery = SongQuery()
    var audio: AVAudioPlayer?
    
    override func viewDidLoad() {
        
        super.viewDidLoad()
        self.title = "Songs"
        MPMediaLibrary.requestAuthorization { (status) in
            if status == .authorized {
                self.albums = self.songQuery.get(songCategory: "")
                DispatchQueue.main.async {
                    self.tableView?.rowHeight = UITableView.automaticDimension
                    self.tableView?.estimatedRowHeight = 60.0
                    self.tableView?.reloadData()
                }
            } else {
                self.displayMediaLibraryError()
            }
        }
        
    }
    
    func displayMediaLibraryError() {
        var error: String
        switch MPMediaLibrary.authorizationStatus() {
        case .restricted:
            error = "Media library access restricted by corporate or parental settings"
        case .denied:
            error = "Media library access denied by user"
        default:
            error = "Unknown error"
        }
        
        let controller = UIAlertController(title: "Error", message: error, preferredStyle: .alert)
        controller.addAction(UIAlertAction(title: "OK", style: .cancel, handler: nil))
        controller.addAction(UIAlertAction(title: "Open Settings", style: .default, handler: { (_) in
            if #available(iOS 10.0, *) {
                UIApplication.shared.open(URL(string: UIApplication.openSettingsURLString)!, options: [:], completionHandler: nil)
            } else {
                // Fallback on earlier versions
            }
        }))
        present(controller, animated: true, completion: nil)
    }
    
    override func didReceiveMemoryWarning() {
        
        super.didReceiveMemoryWarning()
        
    }
    
    func numberOfSections(in tableView: UITableView) -> Int {
        return albums.count
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        
        return albums[section].songs.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath ) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(
            withIdentifier: "MusicPlayerCell",
            for: indexPath) as? MusicPlayerCell ?? MusicPlayerCell()
        cell.labelMusicTitle?.text = albums[indexPath.section].songs[indexPath.row].songTitle
        cell.labelMusicDescription?.text = albums[indexPath.section].songs[indexPath.row].artistName
        let songId: NSNumber = albums[indexPath.section].songs[indexPath.row].songId
        let item: MPMediaItem = songQuery.getItem( songId: songId )
        
        if  let imageSound: MPMediaItemArtwork = item.value( forProperty: MPMediaItemPropertyArtwork ) as? MPMediaItemArtwork {
            cell.imageMusic?.image = imageSound.image(at: CGSize(width: cell.imageMusic.frame.size.width, height: cell.imageMusic.frame.size.height))
        }
        return cell
    }
    
    func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        
        return albums[section].albumTitle
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        
        let songId: NSNumber = albums[indexPath.section].songs[indexPath.row].songId
        let item: MPMediaItem = songQuery.getItem( songId: songId )
        let url: NSURL = item.value( forProperty: MPMediaItemPropertyAssetURL ) as? NSURL ?? NSURL()
        do {
            audio = try AVAudioPlayer(contentsOf: url as URL)
            guard let player = audio else { return }
            
            player.prepareToPlay()
            player.play()
        } catch let error {
            print(error.localizedDescription)
        }
        
        self.title = albums[indexPath.section].songs[indexPath.row].songTitle
    }
}
