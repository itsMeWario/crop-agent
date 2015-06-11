//
//  FormatTableCell.swift
//  CropAgent
//
//  Created by bertrand DUPUY on 15/05/2015.
//  Copyright (c) 2015 bertrand DUPUY. All rights reserved.
//

import UIKit

class FormatTableCell: UITableViewCell {
    
    var customImageView : UIImageView?
    var customLabel : UILabel?
    

    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
    }

    override func setSelected(selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)
        
        if selected{
            contentView.backgroundColor = UIColor(white: 0.9, alpha: 1)
            customLabel?.textColor = UIColor.blackColor()
        }else{
            contentView.backgroundColor = UIColor(white: 0, alpha: 1)
            customLabel?.textColor = UIColor(white: 0.9, alpha: 1)
        }
    }
    
    func initContentView(image : UIImage, label : String){
        
        if customImageView != nil && customLabel != nil{
            //mise à jour des composants si la contentView est déjà initialisée
            
            customImageView?.image = image
            customLabel?.text = label
        
        }else{
            
            //initialisation de la contentView avec ajout
            //imageView et d'un label
            
            customImageView = UIImageView(image: image)
            customImageView?.setTranslatesAutoresizingMaskIntoConstraints(false)
            let isPad = UIDevice.currentDevice().userInterfaceIdiom == .Pad
            let tmpLabel = UILabel(frame: CGRectZero)
            tmpLabel.text = label
            tmpLabel.font = isPad ? tmpLabel.font.fontWithSize(20) : tmpLabel.font.fontWithSize(16)
            tmpLabel.frame.size = tmpLabel.intrinsicContentSize()
            tmpLabel.setTranslatesAutoresizingMaskIntoConstraints(false)
            tmpLabel.textColor = UIColor(white: 0.9, alpha: 1)
            tmpLabel.textAlignment = NSTextAlignment.Center
            customLabel = tmpLabel
            
            let containerView = UIView(frame: CGRectZero)
            containerView.setTranslatesAutoresizingMaskIntoConstraints(false)
            
            containerView.frame.size = CGSize(width: customImageView!.frame.width + customLabel!.frame.width + CGFloat(40), height: frame.size.height*0.8)
            containerView.frame.origin = CGPoint(x: (frame.size.width - containerView.frame.size.width)*0.5, y: (frame.size.height - containerView.frame.size.height)*0.5)
            
            contentView.addSubview(containerView)
            
            containerView.addSubview(customImageView!)
            containerView.addSubview(tmpLabel)
            
            let parentScale = isPad ? CGPoint(x: 0.9, y: 1) : CGPoint(x: 0.8, y: 1)
            
            contentView.addConstraint(NSLayoutConstraint(item: containerView, attribute: NSLayoutAttribute.CenterX, relatedBy: NSLayoutRelation.Equal, toItem: contentView, attribute: NSLayoutAttribute.CenterX, multiplier: 1, constant: 0))
            contentView.addConstraint(NSLayoutConstraint(item: containerView, attribute: NSLayoutAttribute.CenterY, relatedBy: NSLayoutRelation.Equal, toItem: contentView, attribute: NSLayoutAttribute.CenterY, multiplier: 1, constant: 0))
            contentView.addConstraint(NSLayoutConstraint(item: containerView, attribute: NSLayoutAttribute.Width, relatedBy: NSLayoutRelation.Equal, toItem: contentView, attribute: NSLayoutAttribute.Width, multiplier: parentScale.x, constant: 0))
            contentView.addConstraint(NSLayoutConstraint(item: containerView, attribute: NSLayoutAttribute.Height, relatedBy: NSLayoutRelation.Equal, toItem: contentView, attribute: NSLayoutAttribute.Height, multiplier: parentScale.y, constant: 0))
            
            containerView.addConstraint(NSLayoutConstraint(item: customImageView!, attribute: NSLayoutAttribute.CenterY, relatedBy: NSLayoutRelation.Equal, toItem: containerView, attribute: NSLayoutAttribute.CenterY, multiplier: 1, constant: 0))
            
            containerView.addConstraint(NSLayoutConstraint(item: customImageView!, attribute: NSLayoutAttribute.Height, relatedBy: NSLayoutRelation.Equal, toItem: containerView, attribute: NSLayoutAttribute.Height, multiplier: 0.6, constant: 0))
            containerView.addConstraint(NSLayoutConstraint(item: customImageView!, attribute: NSLayoutAttribute.Width, relatedBy: NSLayoutRelation.Equal, toItem: containerView, attribute: NSLayoutAttribute.Height, multiplier: customImageView!.image!.size.width/customImageView!.image!.size.height*0.6, constant: 0))
            containerView.addConstraint(NSLayoutConstraint(item: customImageView!, attribute: NSLayoutAttribute.Leading, relatedBy: NSLayoutRelation.Equal, toItem: containerView, attribute: NSLayoutAttribute.Leading, multiplier: 1, constant: 0))
            
            containerView.addConstraint(NSLayoutConstraint(item: customLabel!, attribute: NSLayoutAttribute.CenterY, relatedBy: NSLayoutRelation.Equal, toItem: containerView, attribute: NSLayoutAttribute.CenterY, multiplier: 1, constant: 0))
            containerView.addConstraint(NSLayoutConstraint(item: customLabel!, attribute: NSLayoutAttribute.Leading, relatedBy: NSLayoutRelation.Equal, toItem: containerView, attribute: NSLayoutAttribute.Leading, multiplier: 1, constant: 0))
            containerView.addConstraint(NSLayoutConstraint(item: customLabel!, attribute: NSLayoutAttribute.Height, relatedBy: NSLayoutRelation.Equal, toItem: nil, attribute: NSLayoutAttribute.NotAnAttribute, multiplier: 1, constant: tmpLabel.frame.size.height))
            containerView.addConstraint(NSLayoutConstraint(item: customLabel!, attribute: NSLayoutAttribute.Trailing, relatedBy: NSLayoutRelation.Equal, toItem: containerView, attribute: NSLayoutAttribute.Trailing, multiplier: 1, constant: 0))

            containerView.layoutIfNeeded()
            
            
        }
    
    
    
    
    
    }
    
    

}
