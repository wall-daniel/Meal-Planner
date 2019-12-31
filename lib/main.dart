import 'dart:convert';

import 'package:flutter/material.dart';
import 'dart:io';
import 'dart:async';
import 'package:path_provider/path_provider.dart';

void main() => runApp(MaterialApp(title: 'Meal Prep App', home: HomeScreen()));

class HomeScreen extends StatefulWidget {
  @override
  HomeScreenState createState() => HomeScreenState();
}

class HomeScreenState extends State<HomeScreen> with SingleTickerProviderStateMixin, WidgetsBindingObserver {
  final _groceryList = new List<Ingredient>();
  final _mealList = new List<Meal>();
  final _recipeList = new List<Recipe>();
  TabController _tabController;

  HomeScreenState() {
    _groceryList.add(Ingredient('this', 2, true));
    _groceryList.add(Ingredient('that', 5, true));
    _groceryList.add(Ingredient('this', 2, false));
    _groceryList.add(Ingredient('that', 5, true));
    _groceryList.add(Ingredient.fromJson({'name': 't', 'number': 3, 'bought': true}));

    _mealList.add(Meal('Monday', 'Breakfast', 'cereal', <Ingredient>[_groceryList[0], _groceryList[2]]));
    _mealList.add(Meal('Monday', 'Lunch', 'food', <Ingredient>[_groceryList[3], _groceryList[2]]));
    _mealList.add(Meal('Monday', 'Dinner', 'cereal', <Ingredient>[_groceryList[0], _groceryList[2]]));
  }

  @override
  void initState() {
    super.initState();

    _tabController = TabController(initialIndex: 0, vsync: this, length: 3);
    _tabController.addListener(() {
      setState(() {});
    });

    WidgetsBinding.instance.addObserver(this);
  }

  Future<File> get _localFile async {
    final directory = await getApplicationDocumentsDirectory();
    final path = directory.path;
    return File('$path/recipes.txt');
  }

  read() async {
    final file = await _localFile;
    final fileOutput = await file.readAsString();
    print(fileOutput);

    try {
      final map = json.decode(fileOutput);
      _recipeList.addAll(map['recipes']);
    } catch (e) {
      print(e);
    }

    // setState(() {

    // });
  }

  save() async {
    final file = await _localFile;

    final map = Map<String, dynamic>();
    map['recipes'] = _recipeList;
    map['meals'] = _mealList;

    print(json.encode(map));
    file.writeAsString(json.encode(map));
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.paused) {
      save();
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _tabController.dispose();
    super.dispose();
  }

  Future<void> createMeal() async {
    final result = await Navigator.push(context, MaterialPageRoute(builder: (context) => MealPage(null))) as Meal;

    setState(() {
      _mealList.add(result);
    });
  }

  Future<void> editMeal(Meal meal) async {
    final result = await Navigator.push(context, MaterialPageRoute(builder: (context) => MealPage(meal))) as Meal;

    setState(() {
      meal = result;
    });
  }

  Future<void> createRecipe() async {
    final recipe =
        await Navigator.push(context, MaterialPageRoute(builder: (context) => EditRecipePage.create())) as Recipe;

    setState(() {
      print('created');
      _recipeList.add(recipe);
    });
  }

  Future<void> editRecipe(int index) async {
    final recipe =
        await Navigator.push(context, MaterialPageRoute(builder: (context) => EditRecipePage(_recipeList[index])))
            as Recipe;

    if (recipe != null) {
      setState(() {
        _recipeList[index] = recipe;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    read();

    return DefaultTabController(
        length: 3,
        child: Scaffold(
          appBar: AppBar(
            title: Text('Meal Planner'),
            bottom: TabBar(
              tabs: <Widget>[
                Tab(icon: Icon(Icons.local_grocery_store)),
                Tab(icon: Icon(Icons.calendar_today)),
                Tab(icon: Icon(Icons.receipt)),
              ],
              controller: _tabController,
            ),
          ),
          body: TabBarView(
            children: <Widget>[
              ListView.separated(
                separatorBuilder: (context, index) {
                  return Divider();
                },
                itemCount: _groceryList.length,
                itemBuilder: (context, index) {
                  final item = _groceryList[index];

                  return ListTile(
                    title: Text(item.name),
                    subtitle: Text('Number ${item.number}'),
                    leading: Checkbox(
                      value: item.bought,
                      onChanged: (val) {
                        print(val);
                      },
                    ),
                  );
                },
              ),
              ListView(
                children: <Widget>[
                  calenderDay(context, 'Monday', null, _mealList[1], _mealList[2], editMeal),
                  calenderDay(context, 'Tuesday', _mealList[0], _mealList[1], _mealList[2], editMeal),
                  calenderDay(context, 'Wednesday', _mealList[0], _mealList[1], _mealList[2], editMeal),
                  calenderDay(context, 'Thursday', _mealList[0], _mealList[1], _mealList[2], editMeal),
                  calenderDay(context, 'Friday', _mealList[0], _mealList[1], _mealList[2], editMeal)
                ],
              ),
              ListView.separated(
                itemCount: _recipeList.length,
                separatorBuilder: (context, index) {
                  return Divider();
                },
                itemBuilder: (context, index) {
                  return ListTile(
                    title: Text(_recipeList[index].name),
                    onTap: () {
                      editRecipe(index);
                    },
                  );
                },
              )
            ],
            controller: _tabController,
          ),
          floatingActionButton: _tabController.index != 1
              ? FloatingActionButton(
                  child: Icon(Icons.add),
                  onPressed: () => {
                    if (_tabController.index == 0)
                      {
                        // Do something with ingredients
                      }
                    else if (_tabController.index == 2)
                      {createRecipe()}
                  },
                )
              : null,
        ));
  }
}

class Ingredient {
  final String name;
  final int number;
  final bool bought;

  Ingredient(this.name, this.number, this.bought);

  Ingredient.fromJson(Map<String, dynamic> json)
      : name = json['name'],
        number = json['number'],
        bought = json['bought'];

  Map<String, dynamic> toJson() => {'name': name, 'number': number, 'bought': bought};
}

class Meal {
  String day;
  String mealtime; // e.g. breakfast, lunch, dinner, snack
  String name;
  final List<Ingredient> ingredients;
  // final List<String> instructions;

  Meal.empty()
      : ingredients = List<Ingredient>(),
        day = '',
        name = '',
        mealtime = '';

  Meal(this.day, this.mealtime, this.name, this.ingredients);

  Meal.fromJson(Map<String, dynamic> json)
      : day = json['day'],
        mealtime = json['meal'],
        name = json['name'],
        ingredients = json['ingredients'];

  Map<String, dynamic> toJson() => {'day': day, 'meal': mealtime, 'name': name, 'ingredients': ingredients};
}

Widget calenderDay(BuildContext context, String day, Meal breakfast, Meal lunch, Meal dinner, Function editMeal) {
  return Column(
    children: <Widget>[
      Container(
        padding: EdgeInsets.all(8.0),
        alignment: Alignment.centerLeft,
        color: Colors.grey,
        child: RichText(text: TextSpan(style: TextStyle(fontSize: 14.0, fontWeight: FontWeight.bold), text: day)),
      ),
      ListTile(
        title: Text('Breakfast: ${breakfast == null ? 'n/a' : breakfast.name}'),
        onTap: () => editMeal(breakfast),
      ),
      ListTile(
        title: Text('Lunch: ${lunch.name}'),
        onTap: () => editMeal(lunch),
      ),
      ListTile(
        title: Text('Dinner ${dinner.name}'),
        onTap: () => editMeal(dinner),
      ),
    ],
  );
}

class MealPage extends StatelessWidget {
  final _formKey = GlobalKey<FormState>();
  Meal _meal;

  MealPage(this._meal) {
    if (_meal == null) {
      _meal = Meal.empty();
    }
  }
  @override
  Widget build(BuildContext context) {
    return Scaffold(
        appBar: AppBar(
          title: Text(_meal == null ? 'Meal' : _meal.name),
          actions: <Widget>[
            IconButton(
              icon: Icon(Icons.save),
              onPressed: () => {
                if (_formKey.currentState.validate()) {_formKey.currentState.save(), Navigator.pop(context, _meal)}
              },
            )
          ],
        ),
        body: Container(
          margin: EdgeInsets.all(8.0),
          child: Form(
              key: _formKey,
              child: Column(
                children: <Widget>[
                  TextFormField(
                    initialValue: _meal == null ? '' : _meal.name,
                    decoration: InputDecoration(labelText: 'Recipe Name', icon: Icon(Icons.add_a_photo)),
                    validator: (value) {
                      if (value.isEmpty) {
                        return 'Name cannot be null';
                      } else if (value.length > 25) {
                        return 'Name cannot be longer than 25 characters';
                      }

                      return null;
                    },
                    onSaved: (value) {
                      _meal.name = value;
                    },
                  )
                ],
              )),
        ));
  }
}

class Recipe {
  String name;
  final List<Ingredient> ingredients;
  final List<String> instructions;

  Recipe(this.name, this.ingredients, this.instructions);

  Recipe.fromJson(Map<String, dynamic> json)
      : name = json['name'],
        ingredients = json['ingredients'],
        instructions = json['instructions'];

  Map<String, dynamic> toJson() => {'name': name};

  @override
  String toString() {
    return jsonEncode(this.toJson());
  }
}

class EditRecipePage extends StatefulWidget {
  Recipe _recipe;

  EditRecipePage(this._recipe);

  EditRecipePage.create() {
    _recipe = Recipe('', List<Ingredient>(), List<String>());
  }

  @override
  EditRecipeState createState() => EditRecipeState();
}

class EditRecipeState extends State<EditRecipePage> {
  final _formKey = GlobalKey<FormState>();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        appBar: AppBar(
          title: Text('Recipe'),
          actions: <Widget>[
            IconButton(
              icon: Icon(Icons.save),
              onPressed: () {
                if (_formKey.currentState.validate()) {
                  _formKey.currentState.save();

                  Navigator.pop(context, widget._recipe);
                }
              },
            )
          ],
        ),
        body: Form(
          key: _formKey,
          child: SingleChildScrollView(
            child: Column(
              children: <Widget>[
                TextFormField(
                  decoration: InputDecoration(labelText: 'Recipe Name', hintText: 'Name'),
                  initialValue: widget._recipe.name,
                  validator: (value) {
                    if (value.length < 3) {
                      return 'Name has to be more than 3 characters';
                    }

                    return null;
                  },
                  onSaved: (value) {
                    widget._recipe.name = value;
                  },
                ),
                Container(
                    padding: EdgeInsets.fromLTRB(8.0, 24.0, 8.0, 8.0),
                    child: Align(
                      alignment: Alignment.centerLeft,
                      child: Text(
                        'Ingredients:',
                        style: TextStyle(color: Colors.black87, fontSize: 24.0),
                      ),
                    )),
                ListView.separated(
                  shrinkWrap: true,
                  physics: NeverScrollableScrollPhysics(),
                  itemCount: widget._recipe.ingredients.length,
                  itemBuilder: (context, index) {
                    return Text(widget._recipe.ingredients[index].name);
                  },
                  separatorBuilder: (context, index) {
                    return Divider();
                  },
                ),
                Container(
                    padding: EdgeInsets.fromLTRB(8.0, 24.0, 8.0, 8.0),
                    child: Align(
                      alignment: Alignment.centerLeft,
                      child: Text(
                        'Instructions:',
                        style: TextStyle(color: Colors.black87, fontSize: 24.0),
                      ),
                    )),
                ListView.separated(
                  shrinkWrap: true,
                  physics: NeverScrollableScrollPhysics(),
                  itemCount: widget._recipe.instructions.length,
                  itemBuilder: (context, index) {
                    return TextFormField(
                      initialValue: widget._recipe.instructions[index],
                      decoration: InputDecoration(hintText: 'Step #${index + 1}'),
                      onChanged: (value) {
                        if (index + 1 == widget._recipe.instructions.length) {
                          setState(() {
                            widget._recipe.instructions.add('');
                          });
                        }
                      },
                    );
                  },
                  separatorBuilder: (context, index) {
                    return Divider();
                  },
                )
              ],
            ),
          ),
        ));
  }
}
