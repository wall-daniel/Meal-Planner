import 'package:flutter/material.dart';

void main() => runApp(MaterialApp(title: 'Meal Prep App', home: HomeScreen()));

class HomeScreen extends StatelessWidget {
  final _groceryList = new List<Ingredient>();
  final _meals = new List<Meal>();

  @override
  Widget build(BuildContext context) {
    _groceryList.add(Ingredient('this', 2, true));
    _groceryList.add(Ingredient('that', 5, true));
    _groceryList.add(Ingredient('this', 2, false));
    _groceryList.add(Ingredient('that', 5, true));
    _groceryList.add(Ingredient('this', 2, false));
    _groceryList.add(Ingredient('that', 5, true));
    _groceryList.add(Ingredient('this', 2, true));
    _groceryList.add(Ingredient('that', 5, true));
    _groceryList.add(
        Ingredient.fromJson({'name': 'those', 'number': 3, 'bought': true}));

    _meals.add(Meal('Monday', 'Breakfast', 'cereal',
        <Ingredient>[_groceryList[0], _groceryList[2]]));
    _meals.add(Meal('Monday', 'Lunch', 'food',
        <Ingredient>[_groceryList[3], _groceryList[2]]));
    _meals.add(Meal('Monday', 'Dinner', 'cereal',
        <Ingredient>[_groceryList[0], _groceryList[2]]));

    return DefaultTabController(
        length: 2,
        child: Scaffold(
          appBar: AppBar(
            title: Text('Meal Planner'),
            bottom: TabBar(
              tabs: <Widget>[
                Tab(icon: Icon(Icons.local_grocery_store)),
                Tab(icon: Icon(Icons.calendar_today)),
              ],
            ),
          ),
          body: TabBarView(
            children: <Widget>[
              groceryListTab(_groceryList),
              calenderTab(context, _meals)
            ],
          ),
          floatingActionButton: FloatingActionButton(
            child: Icon(Icons.add),
            onPressed: () => {},
          ),
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

  Map<String, dynamic> toJson() =>
      {'name': name, 'number': number, 'bought': bought};
}

Widget groceryListTab(List<Ingredient> items) {
  return ListView.separated(
    separatorBuilder: (context, index) {
      return Divider();
    },
    itemCount: items.length,
    itemBuilder: (context, index) {
      final item = items[index];

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
  );
}

class Meal {
  String day;
  String mealtime; // e.g. breakfast, lunch, dinner, snack
  String name;
  List<Ingredient> ingredients;
  // final List<String> instructions;

  Meal(this.day, this.mealtime, this.name, this.ingredients);

  Meal.fromJson(Map<String, dynamic> json)
      : day = json['day'],
        mealtime = json['meal'],
        name = json['name'],
        ingredients = json['ingredients'];

  Map<String, dynamic> toJson() =>
      {'day': day, 'meal': mealtime, 'name': name, 'ingredients': ingredients};
}

Widget calenderTab(BuildContext context, List<Meal> meals) {
  return ListView(
    children: <Widget>[
      calenderDay(context, 'Monday', null, meals[1], meals[2]),
      calenderDay(context, 'Tuesday', meals[0], meals[1], meals[2]),
      calenderDay(context, 'Wednesday', meals[0], meals[1], meals[2]),
      calenderDay(context, 'Thursday', meals[0], meals[1], meals[2]),
      calenderDay(context, 'Friday', meals[0], meals[1], meals[2])
    ],
  );
}

Widget calenderDay(
    BuildContext context, String day, Meal breakfast, Meal lunch, Meal dinner) {
  return Column(
    children: <Widget>[
      Container(
        padding: EdgeInsets.all(8.0),
        alignment: Alignment.centerLeft,
        color: Colors.grey,
        child: RichText(
            text: TextSpan(
                style: TextStyle(fontSize: 14.0, fontWeight: FontWeight.bold),
                text: day)),
      ),
      ListTile(
        title: Text('Breakfast: ${breakfast == null ? 'n/a' : breakfast.name}'),
        onTap: () => _editCalenderDay(context, breakfast),
      ),
      ListTile(
        title: Text('Lunch: ${lunch.name}'),
        onTap: () => _editCalenderDay(context, lunch),
      ),
      ListTile(
        title: Text('Dinner ${dinner.name}'),
        onTap: () => _editCalenderDay(context, dinner),
      ),
    ],
  );
}

Future<void> _editCalenderDay(BuildContext context, Meal meal) async {
  final result = await Navigator.push(
      context, MaterialPageRoute(builder: (context) => MealPage(meal))) as Meal;

  print(result);
}

class MealPage extends StatelessWidget {
  final _formKey = GlobalKey<FormState>();
  Meal _meal;

  MealPage(this._meal);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        appBar: AppBar(
          title: Text(_meal == null ? 'Meal' : _meal.name),
          actions: <Widget>[
            IconButton(
              icon: Icon(Icons.save),
              onPressed: () => {
                if (_formKey.currentState.validate()) {
                  _formKey.currentState.save(),
                  Navigator.pop(context, _meal)
                }
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
                  decoration: InputDecoration(
                    labelText: 'Recipe Name', icon: Icon(Icons.add_a_photo)
                  ),
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
            )
          ),
        )
      );
  }
}
