module singleton;

/** 
	D makes it possible.
	Just use:
		class MyClass
		{
			mixin Singleton!(MyClass);
			
			void doSomeTthing() 
			{ 
				// do something
			};
		}		
		
		MyClass.instance.doSomething(); // create and use a unique instance
		
	to make a singleton out of a normal class;
	
	
	Singleton : simple-singleton
	
*/

template Singleton() // object is created on demand
{
	public static final typeof(this) instance ()
	{
		if (_instance is null )
		{
			_instance = new typeof(this)();
		}
		return _instance;
	}
	
	public static final void release()
	{
		delete _instance;	
	}
	
	private static typeof(this) _instance = null;
}