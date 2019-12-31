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
  final _meals = new List<Day>();
  final _recipeList = new List<Recipe>();
  TabController _tabController;

  HomeScreenState() {
    _groceryList.add(Ingredient('this', 2, true));
    _groceryList.add(Ingredient('that', 5, true));
    _groceryList.add(Ingredient('this', 2, false));
    _groceryList.add(Ingredient('that', 5, true));
    _groceryList.add(Ingredient.fromJson({'name': 't', 'number': 3, 'bought': true}));

    read();
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

  createEmptyWeek() {
    print('Creating empty week.');

    _meals.add(Day.empty('Monday'));
    _meals.add(Day.empty('Tuesday'));
    _meals.add(Day.empty('Wednesday'));
    _meals.add(Day.empty('Thursday'));
    _meals.add(Day.empty('Friday'));

    print(jsonEncode(_meals));
  }

  read() async {
    try {
      final file = await _localFile;
      final fileOutput = await file.readAsString();
      print(fileOutput);

      final map = json.decode(fileOutput);

      for (var i in map['recipes'] as List<dynamic>) {
        _recipeList.add(Recipe.fromJson(i));
      }
      for (var i in map['meals'] as List<dynamic>) {
        _meals.add(Day.fromJson(i));
      }
    } catch (e) {
      print(e);
    }

    if (_meals.length == 0) {
      createEmptyWeek();
    }
  }

  save() async {
    final file = await _localFile;

    final map = Map<String, dynamic>();
    map['recipes'] = _recipeList;
    map['meals'] = _meals;

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
    final result =
        await Navigator.push(context, MaterialPageRoute(builder: (context) => MealPage(null, _recipeList))) as Meal;

    setState(() {
      // _meals.add(result);
    });
  }

  Future<void> editMeal(Meal meal) async {
    final result =
        await Navigator.push(context, MaterialPageRoute(builder: (context) => MealPage(meal, _recipeList))) as Meal;

    setState(() {
      meal = result;
    });
  }

  Future<void> createRecipe() async {
    final recipe =
        await Navigator.push(context, MaterialPageRoute(builder: (context) => EditRecipePage.create())) as Recipe;

    if (recipe != null) {
      setState(() {
        print('created');
        _recipeList.add(recipe);
      });
    }
  }

  Future<void> editRecipe(int index) async {
    final recipe =
        await Navigator.push(context, MaterialPageRoute(builder: (context) => EditRecipePage(_recipeList[index])))
            as Recipe;

    // if (recipe != null) {
    //   setState(() {
    //     _recipeList[index] = recipe;
    //   });
    // }
  }

  @override
  Widget build(BuildContext context) {
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
              ListView.separated(
                separatorBuilder: (context, index) {
                  return Divider();
                },
                itemCount: _meals.length,
                itemBuilder: (context, index) {
                  return calenderDay(context, _meals[index], editMeal);
                },
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
  String name;
  int number;
  bool bought;

  Ingredient(this.name, this.number, this.bought);

  Ingredient.empty() {
    name = '';
    number = 0;
    bought = false;
  }

  Ingredient.fromJson(Map<String, dynamic> json)
      : name = json['name'],
        number = json['number'],
        bought = json['bought'];

  Map<String, dynamic> toJson() => {'name': name, 'number': number, 'bought': bought};
}

class Meal {
  String name;
  final List<Ingredient> ingredients;
  // final List<String> instructions;

  Meal.empty()
      : ingredients = List<Ingredient>(),
        name = '';

  Meal(this.name, this.ingredients);

  Meal.fromJson(Map<String, dynamic> json)
      : name = json['name'],
        ingredients = List.from(json['ingredients']);

  Map<String, dynamic> toJson() => {'name': name, 'ingredients': ingredients};
}

class Day {
  String day;
  Meal breakfast;
  Meal lunch;
  Meal dinner;

  Day(this.day, this.breakfast, this.lunch, this.dinner);

  Day.empty(this.day) {
    breakfast = Meal.empty();
    lunch = Meal.empty();
    dinner = Meal.empty();
  }

  Day.fromJson(Map<String, dynamic> json)
      : day = json['day'],
        breakfast = Meal.fromJson(json['breakfast']),
        lunch = Meal.fromJson(json['lunch']),
        dinner = Meal.fromJson(json['dinner']);

  Map<String, dynamic> toJson() => {'day': day, 'breakfast': breakfast, 'lunch': lunch, 'dinner': dinner};
}

Widget calenderDay(BuildContext context, Day day, Function editMeal) {
  return Column(
    children: <Widget>[
      Container(
        padding: EdgeInsets.all(8.0),
        alignment: Alignment.centerLeft,
        color: Colors.grey,
        child: RichText(text: TextSpan(style: TextStyle(fontSize: 14.0, fontWeight: FontWeight.bold), text: day.day)),
      ),
      ListTile(
        title: Text('Breakfast: ${day.breakfast == null ? 'n/a' : day.breakfast.name}'),
        onTap: () => editMeal(day.breakfast),
      ),
      ListTile(
        title: Text('Lunch: ${day.lunch == null ? 'n/a' : day.lunch.name}'),
        onTap: () => editMeal(day.lunch),
      ),
      ListTile(
        title: Text('Dinner ${day.dinner == null ? 'n/a' : day.dinner.name}'),
        onTap: () => editMeal(day.dinner),
      ),
    ],
  );
}

class MealPage extends StatelessWidget {
  final _formKey = GlobalKey<FormState>();
  Meal _meal;
  final List<Recipe> _recipeList;

  MealPage(this._meal, this._recipeList) {
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
                  DropdownButton<Recipe>(
                    items: _recipeList.map<DropdownMenuItem<Recipe>>((value) {
                      return DropdownMenuItem(child: Text(value.name));
                    }).toList(),
                    onChanged: (value) {
                      print(value.toJson());
                    },
                  ),
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
  bool editing = false;

  EditRecipePage(this._recipe);

  EditRecipePage.create() {
    _recipe = Recipe('', <Ingredient>[Ingredient.empty()], <String>['']);
    editing = true;
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

                  // Remove empty ingredients and instructions
                  widget._recipe.ingredients.removeWhere((value) => value.name.isEmpty);
                  widget._recipe.instructions.removeWhere((value) => value.isEmpty);

                  Navigator.pop(context, widget._recipe);
                }
              },
            ),
            IconButton(
              icon: Icon(Icons.edit),
              onPressed: () {
                setState(() {
                  widget._recipe.ingredients.add(Ingredient.empty());
                  widget._recipe.instructions.add('');
                  widget.editing = true;
                });
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
                  enabled: widget.editing,
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
                    return TextFormField(
                      initialValue: widget._recipe.ingredients[index].name,
                      decoration: InputDecoration(hintText: 'Ingredient #${index + 1}'),
                      onChanged: (value) {
                        if (index + 1 == widget._recipe.ingredients.length) {
                          setState(() {
                            widget._recipe.ingredients.add(Ingredient.empty());
                          });
                        }
                      },
                      onSaved: (value) {
                        widget._recipe.ingredients[index].name = value;
                      },
                    );
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
                      onSaved: (value) {
                        widget._recipe.instructions[index] = value;
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
