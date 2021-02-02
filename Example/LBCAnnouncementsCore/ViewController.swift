//
//  ViewController.swift
//  LBCAnnouncementsCore
//
//  Created by MouldiGABSI on 02/01/2021.
//  Copyright (c) 2021 MouldiGABSI. All rights reserved.
//

import UIKit
import LBCAnnouncementsCore

class ViewController: UIViewController {

    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.
        let router = Router<APIAnnouncementService>()
        router.request(.getAnnouncementList) { ( result: Result<[Announcement], APIError>) in
            
            switch result {
            case .success(let announcements) :
                print("success -----> \(announcements)")
            case .failure(let error):
                print("failure -----> \(error)")
            }
        }
        
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }

}

struct Announcement: Decodable {
    var title, description: String?
}

/*
 {
       "id":1461267313,
       "category_id":4,
       "title":"Statue homme noir assis en plâtre polychrome",
       "description":"Magnifique Statuette homme noir assis fumant le cigare en terre cuite et plâtre polychrome réalisée à la main.  Poids  1,900 kg en très bon état, aucun éclat  !  Hauteur 18 cm  Largeur : 16 cm Profondeur : 18cm  Création Jacky SAMSON  OPTIMUM  PARIS  Possibilité de remise sur place en gare de Fontainebleau ou Paris gare de Lyon, en espèces (heure et jour du rendez-vous au choix). Envoi possible ! Si cet article est toujours visible sur le site c'est qu'il est encore disponible",
       "price":140.00,
       "images_url":{
          "small":"https://raw.githubusercontent.com/leboncoin/paperclip/master/ad-small/2c9563bbe85f12a5dcaeb2c40989182463270404.jpg",
          "thumb":"https://raw.githubusercontent.com/leboncoin/paperclip/master/ad-thumb/2c9563bbe85f12a5dcaeb2c40989182463270404.jpg"
       },
       "creation_date":"2019-11-05T15:56:59+0000",
       "is_urgent":false
    }
 */
