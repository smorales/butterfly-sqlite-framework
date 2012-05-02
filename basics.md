---
layout: default
title: Butterfly SQLite Framework
subtitle: The easy way to deal with SQLite databases
---

### Basics
* [Creating and initializing a model class](#creating_and_initializing_a_model_class)
* [Saving the model class](#saving_the_model_class)
* [Using callback methods](#using_callback_methods)
* [Fetching data using the SQLite instance](#fetching_data_using_the_sqlite_instance)
* [Fetching data using the SQLiteModel instance](#fetching_data_using_a_sqlitemodel_instance)



#### Creating and initializing a model class

Create a model class which will represent a table in your database: 

{% highlight actionscript %} 
[Bindable]
public class Contact extends SQLiteModel
{
	[PrimaryKey]
	public var id:int;
	public var firstName:String;
	public var lastName:String;
	
	public function toString() : String
	{
		return "id:" + id + ", name:" + firstName + " " + lastName;
	}
}
{% endhighlight %}

Note that the class uses the metatag `[Bindable]`. Without it, the framework wont be able to make the relations between table and model. 
The `[PrimaryKey]` metatag indicates that the variable `id` should be unique. Since `id` is an integer, it will increment
everytime a contact is stored in the table.
 
Now let's initialize the database and bind the model class with the belonging table:  
{% highlight actionscript %}
var file:File= File.applicationDirectory.resolvePath("addressbook.db");
sqlite = SQLite.getInstance(file.nativePath);
sqlite.initTable(Contact);
{% endhighlight %}

In the first two lines we instantiate a sqlite instance. Then we bind the model class with the table.
The framework will create the table if not already available.


#### Saving the model class 
To save the model class call simply the method `save()`:

{% highlight actionscript %}
var contact:Contact = new Contact();
contact.firstName = "Chuck";
contact.lastName = "Norris";
contact.save();
{% endhighlight %}
   

#### Using callback methods 
Bypass a callback if you want to be informed when the storing finishes. 
The callback method must expect one parameter, wich will be always the saved model instance. 
Which is in this case our model class `Contact`. 

{% highlight actionscript %}
contact.save( onSavedContact );

function onSavedContact($contact:Contact) : void
{
	trace("contact saved: "+$contact.id, $contact.firstName);
}
{% endhighlight %}


#### Fetching data using the SQLite instance
Call the `load()` method from the sqlite instance and give as argument the model class. 
This will the framework know, that you want load the content of the Contact table. 
The callback function must implement one parameter type of `ArrayCollection`. The array collection
will never be null, but can of course be emtpy.
{% highlight actionscript %}
sqlite.successHandler = onLoadedContacts;
sqlite.load(Contact);

function onLoadedContacts($contacts:ArrayCollection) : void 
{
	for each (var contact : Contact in $contacts) 
		trace('contact loaded => '+contact.id, contact.firstName);
}
{% endhighlight %}


#### Fetching data using a SQLiteModel instance
Using a class model for loading data means that you are looking for only one specific model. 
Maybe you want load a model with the `id = 1` or you are looking for a contact, which name matches with 
some string or you want simply the first or last entry in the database.
  
  
> Example 1 - Using the where clause

{% highlight actionscript %}
var contact:Contact = new Contact();
contact.find("id=1", onLoadedContact);

function onLoadedContact($contact:Contact) : void
{
	trace('contact loaded => '+$contact.id, $contact.firstName);
}
{% endhighlight %}

{% highlight actionscript %}
var contact:Contact = new Contact();
contact.find("name='Chuck'", onLoadedContact);

function onLoadedContact($contact:Contact) : void
{
	trace('contact loaded => '+$contact.id, $contact.firstName);
}
{% endhighlight %}

{% highlight actionscript %}
var contact:Contact = new Contact();
contact.find("name like '%Chu%'", onLoadedContact);

// in this case the framework will return the first match
function onLoadedContact($contact:Contact) : void
{
	trace('contact loaded => '+$contact.id, $contact.firstName);
}
{% endhighlight %}


> Example 2 - Loading the first entry
{% highlight actionscript %}
var contact:Contact = new Contact();
contact.findFirst(onLoadedContact);

function onLoadedContact($contact:Contact) : void
{
	trace('contact loaded => '+$contact.id, $contact.firstName);
}
{% endhighlight %}


> Example 3 - Loading the last entry
{% highlight actionscript %}
var contact:Contact = new Contact();
contact.findLast(onLoadedContact);

function onLoadedContact($contact:Contact) : void
{
	trace('contact loaded => '+$contact.id, $contact.firstName);
}
{% endhighlight %}