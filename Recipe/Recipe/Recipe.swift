//
//  Recipe.swift
//  Recipe
//
//  Created by Craig Vargas on 11/9/16.
//  Copyright © 2016 Codepath Group 6. All rights reserved.
//

import UIKit
import Parse


class Recipe : PFObject, PFSubclassing {

    static let ingredientNameKey = "name"
    static let ingredientQuantityKey = "quantity"
    static let ingredientUnitsKey = "units"
    static let ingredientAuxTextKey = "auxText"
    static let ingredientAltTextKey = "auxText"
    
    static let directionOrderNumKey = "orderNumber"
    static let directionDescriptionKey = "directionDescription"
    
    static let className = "Recipe"
    
    static let createdByUserKey = "createdByUser"
    
    //properties
    @NSManaged var name: String?
    @NSManaged var imageUrlString: String?
    @NSManaged var imageFile: PFFile?
//    @NSManaged var createdByUser: PFRelation<PFUser>?
    @NSManaged var createdByUser: PFUser?
    @NSManaged var inspiredBy: String?
    @NSManaged var inspiredByUrlString: String?
    @NSManaged var inspiredByRecipeUrlString: String?
    @NSManaged var sourceId: String?
    @NSManaged var summary: String?
    @NSManaged var prepTimeStr: String?
    @NSManaged var prepTime: Double
    @NSManaged var prepTimeUnits: String?
    @NSManaged var difficulty: Int
    @NSManaged var ingredients: [Dictionary<String,AnyObject>]
//    @NSManaged var ingredientList: [String]?
//    @NSManaged var directionsDict: [String]?
    @NSManaged var directions: [String]?
    @NSManaged var directionsString: String?
    
    //Properties that do not get saved to the database
    var imageUrl: URL?
    var inspiredByUrl: URL?
    var inspiredByRecipeUrl: URL?
    var ingredientObjList: [Ingredient] = [Ingredient]()
    
    override init() {
        super.init()
    }
    
    convenience init(dictionary: NSDictionary) {
        self.init()
        
        createdByUser = PFUser.current()
        
        name = dictionary["name"] as? String
        prepTime = (dictionary["prepTime"] as! NSString).doubleValue
        
        difficulty = (dictionary["difficulty"] as! NSString).integerValue
        
        // Temporary fix. store directions as one element in the array until we can decide on a standard form for the directions
        if let dictionaryDirections = dictionary["directions"] as? String {
            directionsString = dictionaryDirections
        }
        
        
        // TODO see if we can change this to automatically convert to Ingredient class
        var dictionaryIngredients = [Dictionary<String, AnyObject>]()
        
        for ingredient in (dictionary["ingredients"] as? [Dictionary<String, AnyObject>])! {
            var normalizedIngredient = ingredient
            
            normalizedIngredient["quantity"] = (ingredient["quantity"] as! NSString).doubleValue as AnyObject?
            
            dictionaryIngredients.append(normalizedIngredient)
            
            let ingredientObject = Ingredient(dictionary: normalizedIngredient as NSDictionary)
            ingredientObjList.append(ingredientObject)
        }
        
        ingredients = dictionaryIngredients        
    }
    
//    func create(ingredientObjectWith name: String, quantity: Double, units: String)->Dictionary<String,AnyObject>{
//        var ingredient = [String:AnyObject]()
//        ingredient[Recipe.ingredientNameKey] = name as AnyObject
//        ingredient[Recipe.ingredientQuantityKey] = quantity as AnyObject
//        ingredient[Recipe.ingredientUnitsKey] = units as AnyObject
//        return ingredient
//    }
    
//    func create(directionObjectWith orderNumber: Int, description: String)->Dictionary<String,AnyObject>{
//        var direction = [String:AnyObject]()
//        direction[Recipe.directionOrderNumKey] = orderNumber as AnyObject
//        direction[Recipe.directionDescriptionKey] = description as AnyObject
//        return direction
//    }
    
    static func parseClassName() -> String {
        return "Recipe"
//        return Recipe.className
    }
    
    func saveToDb() {
        if createdByUser == nil {
            createdByUser = PFUser.current()
        }
        
        self.saveInBackground(block: {(wasSuccessful: Bool, error: Error?)->Void in
            if let error = error{
                print("**********")
                print("save failed")
                print(error.localizedDescription)
            }else{
                print("**********")
                print("recipe saved successfully.")
                print("wasSuccessful: \(wasSuccessful) // error: \(error?.localizedDescription)")
            }
        })
    }
    
    func deleteFromDb() {
        self.deleteInBackground(block: {(wasSuccessful: Bool, error: Error?)->Void in
            if let error = error{
                print("**********")
                print("delete failed")
                print(error.localizedDescription)
            }else{
                print("**********")
                print("recipe deleted successfully.")
                print("wasSuccessful: \(wasSuccessful) // error: \(error?.localizedDescription)")
            }
        })
    }
    
    //Build recipe with Edamam dictionary
    class func recipe(fromEdamamDict dictionary: Dictionary<String,Any>) -> Recipe{
        let recipe = Recipe()
        if let recipeDict = dictionary["recipe"] as? Dictionary<String,Any>{
            recipe.name = recipeDict["label"] as? String
            recipe.inspiredBy = recipeDict["source"] as? String
            recipe.inspiredByUrlString = recipeDict["url"] as? String
            recipe.inspiredByRecipeUrlString = recipeDict["shareAs"] as? String
            recipe.sourceId = recipeDict["uri"] as? String
            recipe.imageUrlString = recipeDict["image"] as? String
            
            //TODO work on ingredient list next
            if let ingredientDictList = recipeDict["ingredients"] as? [Dictionary<String,Any>]{
                recipe.ingredients = [Dictionary<String,AnyObject>]()
                var ingredient = Dictionary<String,AnyObject>()
                for ingredientDict in ingredientDictList{
                    ingredient[self.ingredientNameKey] = ingredientDict["food"] as AnyObject
                    ingredient[self.ingredientQuantityKey] = ingredientDict["quantity"] as AnyObject
                    ingredient[self.ingredientUnitsKey] = ingredientDict["measure"] as AnyObject
                    ingredient[self.ingredientAuxTextKey] = ingredientDict["text"] as AnyObject
                    recipe.ingredients.append(ingredient)
                    
                    let ingredientObject = Ingredient(dictionary: ingredient as NSDictionary)
                    recipe.ingredientObjList.append(ingredientObject)
                }
            }
            
            //populateUrls
            recipe.inspiredByUrl = recipe.getUrl(fromOptionalString: recipe.inspiredByUrlString)
            recipe.inspiredByRecipeUrl = recipe.getUrl(fromOptionalString: recipe.inspiredByRecipeUrlString)
            recipe.imageUrl = recipe.getUrl(fromOptionalString: recipe.imageUrlString)
        }
        return recipe
    }
    
    //Search Edamam with query
    class func searchEdamam(forRecipesWithQuery query: String?, startIndex: Int?, numResults: Int?, success: @escaping ([Dictionary<String,Any>])->(), failure: @escaping (Error?)->()){
        EdamamClient.search(
            query: query,
            startIndex: startIndex,
            numResults: numResults,
            recipeUri: nil,
            success: {(recipeList: [Dictionary<String,Any>])->Void in
                success(recipeList)},
            failure: {(error: Error?)->Void in
                failure(error)})
    }
    
    //Search Edamam with recipeUri
    class func searchEdamam(forRecipeWith recipeUri: String, success: @escaping ([Dictionary<String,Any>])->(), failure: @escaping (Error?)->()){
        EdamamClient.search(
            query: nil,
            startIndex: nil,
            numResults: nil,
            recipeUri: recipeUri,
            success: {(recipeList: [Dictionary<String,Any>])->Void in
                success(recipeList)},
            failure: {(error: Error?)->Void in
                failure(error)})
    }
    
    class func recipes(withEdamamRecipeDictList recipeDictList: [Dictionary<String,Any>])->[Recipe]{
        var recipes = [Recipe]()
        for recipeDict in recipeDictList{
            recipes.append(Recipe.recipe(fromEdamamDict: recipeDict))
        }
        return recipes
    }
    
    func getUrl(fromOptionalString optUrlString: String?)->URL?{
        if let urlString = optUrlString{
            return URL(string: urlString)
        }else{
            return nil
        }
    }
    
    class func getDefaultRecipeList() -> [Recipe] {
        var recipeList = [Recipe]();
        
        if let path = Bundle.main.path(forResource: "default_recipes", ofType: "json")
        {
            let jsonData = try! NSData(contentsOfFile: path, options: .dataReadingMapped)
            
            let recipeArray: NSArray = try! JSONSerialization.jsonObject(with: jsonData as Data, options: JSONSerialization.ReadingOptions.mutableContainers) as! NSArray
            
            for item in recipeArray {
                let dictionary = item as! NSDictionary
                let recipe = Recipe(dictionary: dictionary)
                
                recipeList.append(recipe)
            }
            
        }
        
        return recipeList;
    }
    
    class func getMyRecipes(success: @escaping ([Recipe])->(), failure: @escaping (Error?)->()){
        if let currentUser = PFUser.current(){
            print("currentUser: \(currentUser)")
            let query = PFQuery(className: Recipe.className)
            query.whereKey(Recipe.createdByUserKey, equalTo: currentUser)
            query.findObjectsInBackground(block: {(results: [PFObject]?, error: Error?)->Void in
                if error == nil{
                    //successful query
                    print("found 'MyRecipes' successfully in parse DB")
                    var recipes = [Recipe]()
                    if let results = results{
                        for result in results{
                            if let recipe = result as? Recipe{
                                recipe.buildIngredientObjectsList()
                                recipes.append(recipe)
                            }
                        }
                        success(recipes)
                    }
                }else{
                    failure(error)
                }
            })
        }else{
//            print("user is not logged in")
            User.login()
        }
    }
    
    class func getRecipesFromDb(success: @escaping ([Recipe])->(), failure: @escaping (Error?)->()){
        let query = PFQuery(className: Recipe.className)
        query.findObjectsInBackground(block: {(results: [PFObject]?, error: Error?)->Void in
            if error == nil{
                //successful query
                print("found 'MyRecipes' successfully in parse DB")
                var recipes = [Recipe]()
                if let results = results{
                    for result in results{
                        if let recipe = result as? Recipe{
                            recipe.buildIngredientObjectsList()
                            recipes.append(recipe)
                        }
                    }
                    success(recipes)
                }
            }else{
                failure(error)
            }
        })
    }
    
    func buildIngredientObjectsList(){
        ingredientObjList = Ingredient.IngredientsWithArray(dictionaries: ingredients as [NSDictionary])
    }
    
    func prepareIngredientsForDbStorage(){
        ingredients = Ingredient.IngredientDictionariesWithArray(ingredients: ingredientObjList)
    }
}
