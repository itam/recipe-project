//
//  IngredientFlexTVCell.swift
//  Recipe
//
//  Created by Craig Vargas on 11/23/16.
//  Copyright © 2016 Codepath Group 6. All rights reserved.
//

import UIKit

class IngredientFlexTVCell: UITableViewCell, UIPickerViewDataSource, UIPickerViewDelegate {
    
    static let name = "IngredientFlexTVCell"
    
    @IBOutlet weak var ingredientLabel: UILabel!
    @IBOutlet weak var ingredientPicker: UIPickerView!
    @IBOutlet weak var customUnitsTextField: UITextField!
    @IBOutlet weak var nameTextField: UITextField!
    @IBOutlet weak var alternativeTextField: UITextField!
    @IBOutlet weak var editView: UIView!
    
    @IBOutlet weak var mainSizeConstraint: NSLayoutConstraint!

    
    
    var digits = [0, 1, 2, 3, 4, 5, 6, 7, 8, 9]
    var digitStrings = ["0", "1", "2", "3", "4", "5", "6", "7", "8", "9"]
    var fractionStrings = ["","1/16", "1/8", "1/4", "1/2", "2/3", "3/4"]
    var decimals = [0.0, 1.0/16.0, 1.0/8.0, 1.0/4.0, 1.0/2.0, 2.0/3.0, 3.0/4.0]
    var unitStrings = ["","oz", "lbs", "g", "cup", "cups", "ml", "L", "tsp", "tsps", "tbsp", "tbsps"]
    
    var pickerData: Array<Array<String>>!
    
    var visibleViewConstraint: CGFloat!
    var hiddenViewConstraint: CGFloat!
    var cellHeight: CGFloat{
        get{
            switch editViewState {
            case .hidden:
                return hiddenHeight
            case .visible:
                return visibleHeight
            }
        }
    }
    var visibleHeight: CGFloat!
    var hiddenHeight: CGFloat!
    
    var isFirstViewLoad = true
    
    enum ViewState {
        case visible
        case hidden
    }
    
    var editViewState: ViewState{
        get{
            if mainSizeConstraint.constant == hiddenViewConstraint{
                return .hidden
            }else{
                return .visible
            }
        }
    }
    
    var ingredient = Dictionary<String,AnyObject>(){
        willSet{
            
        }
        didSet{
            setView(setView(withDictionary: ingredient))
        }
    }
    
    var ingredientObject = Ingredient(){
        willSet{
            
        }
        didSet{
            setView(setView(withIngredientObject: ingredientObject))
        }
    }
    
    var quantity: Double{

        get{
            let tens = ingredientPicker.selectedRow(inComponent: 0)
            let ones = ingredientPicker.selectedRow(inComponent: 1)
            let fractionPickerIndex = ingredientPicker.selectedRow(inComponent: 2)
            let decimal = decimals[fractionPickerIndex]
            
            return Double(tens * 10 + ones * 1) + decimal
        }
        
        set{
            var fractionPickerIndex = -1
            var tens = 0
            var ones = 0
            
            tens = Int(newValue/10.0)
            ones = Int(newValue.truncatingRemainder(dividingBy: 10.0))
            let decimal = newValue.truncatingRemainder(dividingBy: 1.0)
            
            for (index, value) in decimals.enumerated(){
                if decimal == value{
                    fractionPickerIndex = index
                    break
                }else if decimal < value{
                    //Real value is in between our fraction choices so pick the closest one
                    if index == decimals.count - 1{
                        fractionPickerIndex = decimals.count - 1
                    }else{
                        let lowerDifference = value - decimals[index - 1]
                        let upperDifference = decimals[index] - value
                        if lowerDifference < upperDifference{
                            fractionPickerIndex = index - 1
                        }else{
                            fractionPickerIndex = index
                        }
                    }
                    break
                }
            }
            if fractionPickerIndex == -1 {
                fractionPickerIndex = decimals.count - 1
            }
            
            //update picker view
            ingredientPicker.selectRow(tens, inComponent: 0, animated: true)
            ingredientPicker.selectRow(ones, inComponent: 1, animated: true)
            ingredientPicker.selectRow(fractionPickerIndex, inComponent: 2, animated: true)

        }
    }
    
    var units: String?{
        get{
            let unitsPickerIndex = ingredientPicker.selectedRow(inComponent: 3)
            if unitsPickerIndex == 0{
                return customUnitsTextField.text
            }else{
                return unitStrings[unitsPickerIndex]
            }
        }
        set{
            var unitsPickerIndex = 0
            for (index, value) in unitStrings.enumerated(){
                if newValue == value{
                    unitsPickerIndex = index
                    break
                }
            }
            ingredientPicker.selectRow(unitsPickerIndex, inComponent: 3, animated: true)
            if unitsPickerIndex == 0{
                customUnitsTextField.text = newValue
            }
        }
    }
    
    var name: String?{
        get{
            return nameTextField.text
        }
        set{
            nameTextField.text = newValue
        }
    }
    
//    var alternativeText: String?{
//        get{
//            return alternativeTextField.text
//        }
//        set{
//            alternativeTextField.text = newValue
//            ingredientLabel.text = newValue
//        }
//    }
    
    var displayText: String?{
        get{
            //Set Alternative text value
            if let altTextFieldValue = alternativeTextField.text{
                if altTextFieldValue != "" {
                    return altTextFieldValue
                }
            }
            return Ingredient.makeAlternativeText(quantity: quantity, units: units, name: name)
        }
    }

    override func awakeFromNib() {
        super.awakeFromNib()
        
        print("inside awake from nib*************")
        print("constraint constant: \(mainSizeConstraint.constant)")
        print("constraint relation: \(mainSizeConstraint.relation.rawValue)")
        
        setConstraints()
        setView()
        setPickerValues()
        // Initialization code
    }

    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)

        // Configure the view for the selected state
    }
    
    init(){
        super.init(style: UITableViewCellStyle.default, reuseIdentifier: IngredientFlexTVCell.name)
    }
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }
    
    
    //*
    //*
    //Picker View Functions
    //*
    //*
    func numberOfComponents(in pickerView: UIPickerView) -> Int {
        return pickerData.count
    }
    
    func pickerView(_ pickerView: UIPickerView, numberOfRowsInComponent component: Int) -> Int {
        return pickerData[component].count
    }
    
//    func pickerView(_ pickerView: UIPickerView, titleForRow row: Int, forComponent component: Int) -> String? {
//        return pickerData[component][row]
//    }
//    
//    func pickerView(_ pickerView: UIPickerView, attributedTitleForRow row: Int, forComponent component: Int) -> NSAttributedString? {
//        let str = NSAttributedString(string: pickerData[component][row], attributes: [NSFontAttributeName:UIFont.systemFont(ofSize: 5.0)])
//        print("Attributed String: \(str)")
//        return NSAttributedString(string: pickerData[component][row], attributes: [NSFontAttributeName:UIFont.systemFont(ofSize: 10.0)])
//    }
    
    func pickerView(_ pickerView: UIPickerView, viewForRow row: Int, forComponent component: Int, reusing view: UIView?) -> UIView {
        if let label = view as? UILabel{
            label.text = pickerData[component][row]
            label.font = UIFont.systemFont(ofSize: 10.0)
            label.sizeToFit()
            return label
        }else{
            let label = UILabel()
            label.text = pickerData[component][row]
            label.font = UIFont.systemFont(ofSize: 12.0)
            label.sizeToFit()
            return label
        }
    }
    
    func pickerView(_ pickerView: UIPickerView, didSelectRow row: Int, inComponent component: Int) {
        ingredientLabel.text = displayText
        if component == 3{
            customUnitsTextField.text = ""
        }
    }
    
    func pickerView(_ pickerView: UIPickerView, rowHeightForComponent component: Int) -> CGFloat {
        return 16.0
    }
    
    //Uncomment to control the width of the picker view columns
//
//    func pickerView(_ pickerView: UIPickerView, widthForComponent component: Int) -> CGFloat {
//            switch component {
//            case 0:
//                return CGFloat(30.0)
//            case 1:
//                return CGFloat(30.0)
//            case 2:
//                return CGFloat(70.0)
//            case 3:
//                return CGFloat(100.0)
//            default:
//                return CGFloat(0.0)
//            }
//    }
    
    
    
    @IBAction func textFieldDidChange(_ sender: UITextField) {
        ingredientLabel.text = displayText
        if sender === customUnitsTextField {
            units = customUnitsTextField.text
        }
    }
    
    private func setConstraints(){
        self.hiddenViewConstraint = CGFloat(8.0)
        self.contentView.layoutIfNeeded()
        self.visibleViewConstraint = hiddenViewConstraint + editView.frame.height + 8.0
        print("setConstraints: hide constraint: \(hiddenViewConstraint)")
        print("setConstraints: show constraint: \(visibleViewConstraint)")
        print("setConstraints: label: \(ingredientLabel.frame.maxY)")
        self.visibleHeight = ingredientLabel.frame.maxY + visibleViewConstraint + 8.0
        self.hiddenHeight = ingredientLabel.frame.maxY + hiddenViewConstraint + 8.0
        print("setConstraints: show constraint: \(visibleHeight)")
        print("setConstraints: hide constraint: \(hiddenHeight)")
    }
    
    private func setPickerValues(){
        pickerData = [digitStrings, digitStrings, fractionStrings, unitStrings]
        ingredientPicker.dataSource = self
        ingredientPicker.delegate = self
    }
    
    func showEditView(){
        print("Start show: state = \(editViewState)")
        self.editView.isHidden = false
        self.editView.alpha = 1.0
        self.mainSizeConstraint.constant = visibleViewConstraint
        self.contentView.layoutIfNeeded()
        print("End show: state = \(editViewState), height = \(cellHeight), state = \(editViewState)")
    }
    
    func hideEditView(){
        print("Start hide: state = \(editViewState)")
        self.editView.alpha = 0.0
        self.editView.isHidden = true
        self.mainSizeConstraint.constant = hiddenViewConstraint
        self.contentView.layoutIfNeeded()
        print("End hide: state = \(editViewState), height = \(cellHeight), state = \(editViewState)")
    }
    
    func toggleView(){
        print("Start toggle: state = \(editViewState)")
        if self.editViewState == .hidden{
            showEditView()
        }else{
            hideEditView()
        }
        print("End toggle: state = \(editViewState)")
    }
    
    private func setView(){
        if isFirstViewLoad {
            editView.alpha = 0.0
            editView.isHidden = true
            isFirstViewLoad = false
        }
    }
    
    func setView(withDictionary ingredient: Dictionary<String,AnyObject>){
        //Set Quantity view
        if let quantityValue = ingredient[Recipe.ingredientQuantityKey] as? Double{
            quantity = quantityValue
        }else{
            quantity = 0.0
        }
        //Set units view
        if let unitsValue = ingredient[Recipe.ingredientUnitsKey] as? String{
            self.units = unitsValue
        }else{
            self.units = ""
        }
        //Set name view
        if let nameValue = ingredient[Recipe.ingredientNameKey] as? String{
            self.name = nameValue
        }
        //Set Alternative text value
        alternativeTextField.text = ""
        if let altTextValue = ingredient[Recipe.ingredientAltTextKey] as? String{
            if altTextValue != Ingredient.makeAlternativeText(quantity: quantity, units: units, name: name){
                alternativeTextField.text = altTextValue
            }
        }
        
        ingredientLabel.text = displayText
    }
    
    func setView(withIngredientObject ingredient: Ingredient){
        //Set Quantity view
        quantity = ingredient.quantity
        //Set units view
        units = ingredient.unit
        //Set name view
        name = ingredient.name
        //Set Alternative text value
        if ingredient.alternativeTextIsUnique(){
            alternativeTextField.text = ingredient.alternativeText
        }else{
            alternativeTextField.text = ""
        }
        
        ingredientLabel.text = displayText
    }

    
//    private func makeDisplayText() -> String{
//        return String(self.quantity) + " " + (self.units ?? "") + " of " + (self.name ?? "")
//    }
    
}