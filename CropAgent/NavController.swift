//
//  navController.swift
//  test
//
//  Created by bertrand DUPUY on 30/03/2015.
//  Copyright (c) 2015 bertrand DUPUY. All rights reserved.
//

import UIKit

class NavController: UINavigationController, UINavigationControllerDelegate{
   
    override func viewDidLoad() {
        super.viewDidLoad()
        delegate = self
    }
    
    required init(coder aDecoder: NSCoder) {
        super.init(coder : aDecoder)
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    
    
    override func popViewControllerAnimated(animated: Bool) -> UIViewController? {
        
        let isAnimated : Bool!
        let controller : UIViewController!
        
        // retour au context 0
        if let asMainVC = viewControllers.last as? MainVC where asMainVC.appContextId != 0{
            
            //l'ordre de suppression reste sans suite, seul le context change
            asMainVC.updateContext(0)
            return nil
            
        }else if let asMainVC = viewControllers.last as? MainVC where asMainVC.appContextId == 0{
            //fermeture du MainVC et retour au choix des formats
            
            hidesBarsOnTap = false
            controller = super.popViewControllerAnimated(true)
        
        }else{
            //si fermeture di controller affichant l'image finale
            if let asResultVC = viewControllers.last as? ResultVC, let asMainVc = viewControllers[viewControllers.count - 2] as? MainVC where viewControllers.count > 2{
                //fermeture du controlleur affichant le rendu final
                
                asMainVc.view.layer.opacity = 1
                hidesBarsOnTap = true
                isAnimated = true
            
            }else{
                
                isAnimated = true
            }
            
            controller = super.popViewControllerAnimated(isAnimated!)
            
        }
        
        return controller
    }

    override func pushViewController(viewController: UIViewController, animated: Bool) {
        
        var tmpAninamed = true
        
        //mise à des données de format avt ouverture de ContainerVC
        if let asFormatTable = viewControllers.last as? FormatTableVC, let asMainVC = viewController as? MainVC{
            
//            var sessionData = SessionData.sharedData.getCopy()
//            var selectedItem = asFormatTable.tableView.indexPathForSelectedRow()
//            
//            if let itemIndexPath = selectedItem{
//                sessionData.projectFormat = asFormatTable.tableData[itemIndexPath.item]
//            }
//            
//            asMainVC.sessionData = sessionData
//            SessionData.setAppData(sessionData)
        }
        
        super.pushViewController(viewController, animated: tmpAninamed)
    }
}
